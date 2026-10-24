package Database::BI::Model::DataSource;

use strict;
use warnings;
use autodie qw(:all);

use Carp		qw(croak carp);
use File::Spec		();
use Readonly;
use Scalar::Util	qw(blessed);
use Sub::Protected;
use Params::Validate::Strict qw(validate_strict);
use Params::Get		();

our $VERSION = '0.016.0';

=head1 NAME

Database::BI::Model::DataSource - Table-agnostic adapter around Database::Abstraction

=head1 VERSION

0.012.0

=head1 SYNOPSIS

B<Read all rows from a CSV file:>

    use Database::BI::Model::DataSource;

    my $source = Database::BI::Model::DataSource->new(
        directory => '/path/to/data',
        table     => 'sales',           # looks for data/sales.csv, tsv, .psv, .sql, .xml, etc.
    );

    my $records = $source->fetch_all;   # arrayref of hashrefs -- one hashref per row

    for my $row (@{$records}) {
        printf "Product: %s, Amount: %s\n", $row->{product}, $row->{amount};
    }

B<Get column names in the original file order (CSV/PSV/TSV only):>

    my $cols = $source->columns;        # returns undef for SQLite and XML
    if ($cols) {
        print join(', ', @{$cols}), "\n";
    }

B<Find out which column is the primary key:>

    print "Primary key column: ", $source->id_column, "\n";

B<Open a SQLite file (.sql extension):>

    my $source = Database::BI::Model::DataSource->new(
        directory => '/var/data',
        table     => 'inventory',       # looks for /var/data/inventory.sql
    );

B<Open a pipe-separated file (.psv extension):>

    my $source = Database::BI::Model::DataSource->new(
        directory => '/var/data',
        table     => 'products',        # looks for /var/data/products.psv
    );

B<Open a tab-separated file (.tsv extension):>

    my $source = Database::BI::Model::DataSource->new(
        directory => '/var/data',
        table     => 'products',        # looks for /var/data/products.tsv
    );

B<Use a custom i18n object to translate error messages:>

    # The i18n object must have a maketext($key, @args) method.
    my $source = Database::BI::Model::DataSource->new(
        directory => '/path/to/data',
        table     => 'sales',
        i18n      => My::I18N::Handle->new,
    );

B<Open a remote HTML table from a URL:>

    # Requires LWP::UserAgent::Cached and HTML::TableExtract.
    # The table is fetched and cached in memory; no file is saved to disk.
    my $source = Database::BI::Model::DataSource->new(
        url => 'https://example.com/data-page.html',
    );
    my $records = $source->fetch_all;

B<Select a specific table when a page has more than one HTML table:>

    my $source = Database::BI::Model::DataSource->new(
        url              => 'https://example.com/page.html',
        html_table_index => 2,   # zero-based: 0 = first table, 2 = third table
    );

B<Open one specific internal table from a multi-table SQLite database:>

    # A SQLite file may contain more than one table.
    # Use internal_table to say which one you want.
    my $source = Database::BI::Model::DataSource->new(
        directory      => '/var/data',
        table          => 'store',          # looks for store.db, store.sql, etc.
        internal_table => 'customer',       # open just the "customer" table inside
    );
    my $records = $source->fetch_all;

B<Check whether a SQLite file has more than one table:>

    my $source = Database::BI::Model::DataSource->new(
        directory => '/var/data',
        table     => 'store',
    );
    my $tbl_list = $source->sqlite_tables;   # undef unless it is a multi-table SQLite
    if ($tbl_list && @{$tbl_list} > 1) {
        # let the user choose which table to open
        for my $name (@{$tbl_list}) {
            printf "  table: %s\n", $name;
        }
    }

B<Open a remote file over SSH (SFTP):>

    # Requires Net::SFTP::Foreign.
    my $source = Database::BI::Model::DataSource->new(
        directory => '/remote/data',
        table     => 'report',
        host      => 'deploy@dbserver.example.com',
        file_ext  => 'log',         # hint: try report.log first, then other exts
    );
    my $records = $source->fetch_all;

B<Handle errors gracefully:>

    my $source = eval {
        Database::BI::Model::DataSource->new(
            directory => $dir,
            table     => $table,
        );
    };
    if ($@) {
        carp "Could not open table: $@";
        # $@ contains a translated message from %MESSAGES
    }

    my $records = eval { $source->fetch_all };
    if ($@) {
        carp "Could not read records: $@";
    }

=head1 DESCRIPTION

C<Database::BI::Model::DataSource> is a thin, table-agnostic adapter that
wraps L<Database::Abstraction> and exposes three accessors (C<fetch_all>,
C<columns>, C<id_column>) used by the controller.

L<Database::Abstraction> is a read-only ORM that discovers data files
(CSV, PSV, TSV, SQLite, XML, etc.) automatically from a directory based on the
calling class name.  C<DataSource> generates an ephemeral subclass at
construction time so callers never interact with L<Database::Abstraction>
directly.  To swap the backend for L<Database::Join> in Phase 2, only the
C<open_table> helper in C<Database::BI> needs to change; the controller and
C<DataSource> are untouched.

C<_detect_file_info> peeks at the first header line of CSV/PSV/TSV files to
extract the correct separator character, the primary-key column name, and
the full ordered column list.  Without this, two silent L<Database::Abstraction>
defaults corrupt every result: C<sep_char> defaults to C<'!'> (turning a
comma-separated file into a single-field table) and C<id> defaults to
C<'entry'> (causing every row to be discarded when no C<entry> column
exists).

Result filtering (C<eq>, C<contains>, C<gt>, etc.) is performed at the
controller layer by C<Dashboard::_apply_filter_spec> after C<fetch_all>
returns.  C<DataSource> itself is filter-unaware.

All user-visible strings and exception messages are keyed through the
C<%MESSAGES> dictionary and routed via C<_msg()>, making every diagnostic
replaceable by an i18n object at instantiation time.

=cut

=head1 ENCODING

=head2 What is safe to put in cell values

Cell values (the actual data inside rows) are passed through as Perl
character strings exactly as C<Database::Abstraction> and the underlying
DBI driver return them.  Full Unicode -- including non-ASCII letters,
accented characters, CJK ideographs, and emoji -- is supported in cell
values, provided the source file is encoded in UTF-8 (or the encoding
declared in its HTTP headers for URL-backed tables).

=head2 What must stay ASCII

The following structural items must contain B<only ASCII characters>:

=over 4

=item C<table> constructor argument

The bare file stem used to look up the file on disk.  Non-ASCII characters
are not valid SQL identifiers and will be silently replaced with underscores
(C<_>) by the sanitization step in C<new()>.

=item Column header names (CSV / TSV / PSV first line)

Column names are used as hash keys and as SQL identifiers inside
C<Database::Abstraction>.  Non-ASCII headers cause C<DBD::CSV> to
fail or produce garbage keys.  If your source file has non-ASCII
column headers, rename them before opening via C<DataSource>.

=item C<host> argument

The hostname or C<user@hostname> string for SFTP access.  Must match
C<[A-Za-z0-9._@-]>; anything outside that character set is rejected by
the host-validation regex and produces C<error_backend_init>.

=back

=head2 URL-backed tables

URL-backed tables (the C<url =E<gt>> constructor path) are fetched with
L<LWP::UserAgent::Cached>.  If the remote server declares a charset in its
HTTP headers or in an HTML C<meta> tag, L<Database::Abstraction> uses it
to decode the response body.  If the charset declaration is absent or wrong,
cell values may arrive as raw bytes rather than character strings, and
multi-byte sequences will look garbled.

=head2 File-backed tables (CSV / TSV / PSV)

For files smaller than 16 KB, L<Text::xSV::Slurp> reads bytes and returns
them without re-encoding; for larger files the L<DBD::CSV> path is used
instead.  In both cases C<DataSource> forces the slurp path (by passing
C<max_slurp_size =E<gt> -s $file>) so that column names with spaces are
preserved as-is.  The caller (the Mojolicious controller) is responsible
for setting the correct C<Content-Type: text/html; charset=UTF-8> response
header.

=cut

# ---------------------------------------------------------------------------
# I18N message dictionary.
# All user-visible strings and exception messages are keyed here.
# To plug in a real i18n backend (e.g. Locale::Maketext), pass an object
# that responds to maketext($key, @args) as the "i18n" constructor argument;
# it will be called in preference to this table.
# ---------------------------------------------------------------------------

Readonly our %MESSAGES => (
	error_directory_required	=> 'DataSource: argument "directory" is required',
	error_table_required		=> 'DataSource: argument "table" is required',
	error_directory_missing		=> 'DataSource: directory "%s" does not exist or is not readable',
	error_table_name_invalid	=> 'DataSource: table name "%s" contains illegal characters (alphanumeric and underscore only)',
	error_backend_init		=> 'DataSource: failed to initialise database backend for table "%s": %s',
	error_fetch_failed		=> 'DataSource: fetch_all failed for table "%s": %s',
	error_url_invalid		=> 'DataSource: URL "%s" must begin with http:// or https://',
	error_url_fetch			=> 'DataSource: failed to open HTML table at "%s": %s',
	error_no_safe_id		=> 'DataSource: table "%s" has no column with a safe identifier name (letters, digits, underscore); rename at least one column header',
	error_no_tables			=> 'DataSource: SQLite file "%s" contains no user-defined tables',
	error_table_not_found		=> 'DataSource: SQLite file "%s" does not contain a table named "%s"',
	error_unsupported_db		=> 'DataSource: "%s" is a Berkeley DB file but the installed DB_File library cannot open it (file may use a newer Berkeley DB format)',
	error_redis_invalid		=> 'DataSource: Redis URL "%s" must begin with redis://',
	warn_empty_result		=> 'DataSource: fetch_all returned no records for table "%s"',
	warn_data_normalised		=> 'DataSource: result from backend was a hashref; converted to arrayref for table "%s"',
);

# A table name is a bare SQL-safe identifier: starts with a letter or
# underscore, followed by zero or more alphanumeric/underscore characters.
Readonly my $TABLE_NAME_RE => qr/\A[A-Za-z_][A-Za-z0-9_]*\z/;

# ---------------------------------------------------------------------------
# Protected helpers
# ---------------------------------------------------------------------------

# _url_label( $url ) -> $string
#
# Derive a safe, lowercase identifier from a URL for use as the table label.
# Takes the last non-empty path component, strips the extension, then replaces
# non-alphanumeric characters with underscores.  Falls back to the hostname
# when the path component is absent or starts with a digit.
sub _url_label {
	my $url = $_[0];
	my ($path) = $url =~ m{https?://[^/?#]+(.*)}i;
	my @parts  = grep { length } split m{/}, ($path // '');
	my $last   = @parts ? $parts[-1] : '';
	# /s: . must cross \n in case a percent-decoded newline hides inside the URL.
	$last =~ s/[?#].*//s;		# strip query / fragment
	$last =~ s/\.[^.]+\z//;	# strip file extension (\z: no trailing-\n loophole)
	$last =~ s/[^A-Za-z0-9_]/_/g;	# sanitize
	unless (length $last && $last =~ /\A[A-Za-z_]/) {
		# No usable path component -- fall back to hostname
		my ($host) = $url =~ m{https?://([^/:?#]+)};
		$last = defined $host ? do { (my $h = $host) =~ s/[^A-Za-z0-9_]/_/g; $h } : 'html';
	}
	# $last is always non-empty here: the unless-block sets it to either
	# the sanitized hostname (>= 1 char) or the literal 'html'.
	return lc($last);
}

# _fmt( $key [, @sprintf_args] ) -> $string
#
# Package-level (not a method) i18n formatter. Looks up $key in %MESSAGES and
# applies sprintf if positional arguments are supplied. This function is used
# in new() before the object exists; instance methods should use _msg() instead
# so that a caller-supplied i18n object can override the built-in strings.
sub _fmt :Protected {
	my ($key, @args) = @_;
	my $tmpl = $MESSAGES{$key} // "Internal error: unknown message key '$key'";
	return @args ? sprintf($tmpl, @args) : $tmpl;
}

# _msg( $self, $key [, @sprintf_args] ) -> $string
#
# Instance-level i18n formatter. Delegates to the caller-supplied i18n object
# (if any) before falling back to _fmt(). The i18n object must implement
# maketext($key, @args).
sub _msg :Protected {
	my ($self, $key, @args) = @_;
	if (my $i18n = $self->{_i18n}) {
		return $i18n->maketext($key, @args);
	}
	return _fmt($key, @args);
}

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

=head1 CONSTRUCTOR

=head2 new

Creates and returns a new C<Database::BI::Model::DataSource> instance.

=head3 API SPECIFICATION

=head4 INPUT

	{
	    directory      => 'string',   # required; local dir, or remote dir when host is set
	    table          => 'string',   # required; bare file stem (no extension)
	    host           => 'string',   # optional; "hostname" or "user@hostname" for SFTP access
	    file_ext       => 'string',   # optional; extension hint when remote file has non-standard suffix (e.g. "log")
	    internal_table => 'string',   # optional; name of a specific internal SQLite table to open
	    cache          => 'object',   # optional; CHI cache object for result caching
	    cache_ttl_url  => 'string',   # optional; CHI TTL string for URL-backed tables (default "15 min")
	    i18n           => 'object',   # optional; must implement maketext($key, @args) for i18n
	}

C<internal_table> selects a named table inside a multi-table SQLite file.
When omitted, C<DataSource> auto-selects the first user table whose name
matches the filename stem; if no match, it picks the first table found.
Supplying a name that does not exist in the file croaks C<error_table_not_found>.

Accepts a flat key/value list, a hashref, or positional arguments via
C<Params::Get>.

When C<host> is provided, C<directory> is treated as a path on the remote
host and is not checked with C<-d> locally.  C<DataSource> downloads the
file via SFTP (L<Net::SFTP::Foreign>) to a process-local temporary directory
and then processes the local copy.  The temporary directory persists for the
lifetime of the C<DataSource> object and is cleaned up automatically on
destruction.

When C<file_ext> is provided together with C<host>, it is used as the first
candidate extension when probing the remote host for the file.  If the
downloaded file does not have a standard extension (one of C<csv>, C<tsv>,
C<psv>, C<xlsx>, C<xls>, C<sql>, C<sqlite>, C<sqlite3>, C<db>, C<xml>),
the file content is sniffed (SQLite magic bytes, XML preamble, or first-line
field separator) and the file is renamed to the correct standard extension
before further processing.

=head4 DOMAIN CONSTRAINTS

=over 4

=item C<directory>

Must satisfy C<-d $directory> (must exist and be a directory).  An empty
string, a non-existent path, or the path to a regular file all produce
C<error_directory_missing>.

  Valid partition:   any existing directory path
  Invalid partition: non-existent path, regular file path, empty string ""

=item C<table>

The bare file stem (no extension).  Characters that are illegal in SQL
identifiers - hyphens, dots, spaces, etc. - are silently replaced with
underscores before the name is used internally.  A stem that starts with a
digit is prefixed with C<_>.  Only a completely empty string croaks.

  Valid partition:   "sales", "_tmp", "report_2024",
                     "Transactions-2026-09-08" (hyphens sanitized to underscores),
                     "my.data" (dot sanitized), "1sales" (prefixed to "_1sales")
  Invalid partition: "" (empty string)
  Boundary values:   "a" (length-1 letter, valid), "_" (length-1 underscore,
                     valid), "" (empty string, croaks error_table_name_invalid)

=back

=head4 OUTPUT

Returns C<$self> (a blessed hashref). Croaks on invalid arguments.

=head3 MESSAGES

  error_directory_required    -- "directory" argument was not supplied
  error_table_required        -- "table" argument was not supplied
  error_directory_missing     -- supplied directory does not exist / is unreadable
  error_table_name_invalid    -- table name contains illegal characters or is empty
  error_no_safe_id            -- no column in the file has a safe SQL identifier name;
                                 rename at least one column header to an alphanumeric name
  error_backend_init          -- backend initialisation failed; sub-cases:
                                   * Net::SFTP::Foreign is not installed
                                   * could not connect to <host> via SFTP
                                   * could not fetch any supported file from <host>:<dir>/<stem>.*
                                   * Database::Abstraction subclass could not be instantiated
  error_no_tables             -- SQLite file opened successfully but contains no user-defined tables
  error_unsupported_db        -- .db file has BerkeleyDB magic bytes but DB_File could not open it
                                 (file likely uses a newer BDB format than the installed libdb supports)
  error_fetch_failed          -- fetch_all raised an exception (wraps the underlying DBI/D::A error)
  error_url_invalid           -- URL passed to the url=> constructor path does not begin
                                 with http:// or https://
  error_url_fetch             -- fetching or parsing the HTML table at a URL failed

=cut

sub new {
	# Strategy: normalise the argument list with Params::Get so callers may
	# pass a hashref or a flat list interchangeably, then validate strictly
	# with Params::Validate before touching any value.
	# When a "url" key is present, dispatch to the URL/HTML-table path instead.
	my $class = shift;
	my $raw   = Params::Get::get_params(undef, \@_) // {};
	return $class->_new_from_url($raw)   if exists $raw->{url};
	return $class->_new_from_redis($raw) if exists $raw->{redis};

	my $args = validate_strict(
		schema => {
			directory      => { type => 'string' },
			table          => { type => 'string' },
			host           => { type => 'string', optional => 1, default => undef },
			file_ext       => { type => 'string', optional => 1, default => undef },
			internal_table => { type => 'string', optional => 1, default => undef },
			i18n           => { type => 'object', optional => 1, default => undef, can => 'maketext' },
			cache          => { type => 'object', optional => 1, default => undef },
			cache_ttl_url  => { type => 'string', optional => 1, default => '15 min' },
		},
		input => $raw,
	);

	# For remote files (host is set), the directory is on the remote host and
	# cannot be stat()d locally.  Only check local existence when no host is given.
	croak _fmt('error_directory_missing', $args->{directory})
		unless defined $args->{host} || -d $args->{directory};

	# Reject path-traversal characters first: '/', '\', and NUL are the only
	# characters that could let _raw_table escape the intended directory when
	# D::A constructs "$dir/$dbname.$ext".  Everything else is either safe as a
	# filename component or will be sanitized below.
	croak _fmt('error_table_name_invalid', $args->{table})
		if !length($args->{table}) || $args->{table} =~ m{[/\\\x00]};

	# Silently sanitize table names derived from file stems: replace characters
	# that are illegal in SQL identifiers (hyphens, dots, spaces, etc.) with
	# underscores.  A leading digit is prefixed with '_'.  The original name is
	# kept in _raw_table for filesystem lookup (dbname) so the actual file is
	# still found; the sanitized name is used only as the internal D::A
	# identifier and ephemeral package name.
	my $raw_table = $args->{table};
	(my $safe_table = $raw_table) =~ s/[^A-Za-z0-9_]/_/g;
	$safe_table = '_' . $safe_table if $safe_table =~ /\A[0-9]/;

	croak _fmt('error_table_name_invalid', $raw_table)
		unless $safe_table =~ $TABLE_NAME_RE;

	my $self = bless {
		_directory      => $args->{directory},
		_table          => $safe_table,
		_raw_table      => $raw_table,
		_host           => $args->{host},
		_file_ext       => $args->{file_ext},
		_internal_table => $args->{internal_table},
		_i18n           => $args->{i18n},
		_cache          => $args->{cache},
		_cache_ttl_url  => $args->{cache_ttl_url},
		_db             => undef,
	}, $class;

	$self->_init_backend();
	return $self;

}

# _new_from_url( $class, \%raw_params ) -> $self
#
# Alternate constructor path for URL-backed HTML tables.
#          Validates the URL scheme, derives a display label from the URL path,
#          then calls _init_url_backend to build the D::A in-memory table.
# Entry:   $raw->{url} must be an http:// or https:// URL.
#          $raw->{html_table_index} (optional, default 0): zero-based table index.
#          $raw->{i18n} (optional): Locale::Maketext-compatible object.
# Exit:    Returns $self.  Croaks on invalid URL scheme or backend init failure.
# Side Effects: Issues an HTTP GET to the URL via LWP::UserAgent.
sub _new_from_url :Protected {
	my ($class, $raw) = @_;

	my $url = $raw->{url} // croak _fmt('error_url_invalid', '');
	croak _fmt('error_url_invalid', $url)
		unless $url =~ m{\Ahttps?://}i;

	my $table_idx = $raw->{html_table_index} // 0;
	my $self = bless {
		_url              => $url,
		_table            => _url_label($url),
		_i18n             => $raw->{i18n},
		_cache            => $raw->{cache},
		_cache_ttl_url    => $raw->{cache_ttl_url} // '15 min',
		_html_table_index => $table_idx,
		_id_col           => undef,
		_columns          => undef,
		_db               => undef,
	}, $class;

	$self->_init_url_backend($table_idx);
	return $self;
}

# _init_url_backend( $self, $table_index ) -> void
#
# Purpose: Construct the Database::Abstraction backend for URL/HTML-table mode.
#          D::A fetches the page via LWP::UserAgent, parses it with
#          HTML::TableExtract, and stores all rows (including headers from row 0)
#          as an in-memory arrayref.  Column order is not recoverable after
#          construction (hash keys lose order), so _columns stays undef and
#          _get_columns in the controller falls back to alphabetical sorting.
# Entry:   $self->{_url} is a valid http(s) URL; $table_index is a non-negative int.
# Exit:    Sets $self->{_db}.  Croaks on LWP or HTML::TableExtract failure.
# Side Effects: Network I/O; may take up to LWP's default timeout.
sub _init_url_backend :Protected {
	my ($self, $table_index) = @_;
	my $url = $self->{_url};

	require Database::Abstraction;

	# Reuse a single generic package for all URL-backed instances.
	# The package name is irrelevant for the URL code path -- D::A branches on
	# the presence of $self->{'url'}, not on the class name.
	my $pkg = 'Database::BI::_DB::HtmlUrl';
	{
		no strict 'refs';
		push @{"${pkg}::ISA"}, 'Database::Abstraction'
			unless $pkg->isa('Database::Abstraction');
	}

	my $db = eval {
		$pkg->new({
			url              => $url,
			html_table_index => $table_index,
			no_entry         => 1,
		})
	};
	croak $self->_msg('error_url_fetch', $url, $@) if $@;

	$self->{_db} = $db;
	return;
}

# _new_from_redis( $class, \%raw_params ) -> $self
#
# Alternate constructor path for Redis-backed tables.
# Entry:   $raw->{redis} must be a redis:// URL.
#          $raw->{table} (required): table name -- becomes the Redis key prefix
#                         (keys in Redis must follow the pattern tablename:*).
#          $raw->{i18n} (optional): Locale::Maketext-compatible object.
# Exit:    Returns $self.  Croaks on invalid URL or table name.
sub _new_from_redis :Protected {
	my ($class, $raw) = @_;

	my $redis_url = $raw->{redis} // croak _fmt('error_redis_invalid', '');
	croak _fmt('error_redis_invalid', $redis_url)
		unless $redis_url =~ m{\Aredis://}i;

	my $table = $raw->{table} // croak _fmt('error_table_required');
	croak _fmt('error_table_name_invalid', $table)
		if !length($table) || $table =~ m{[/\\\x00]};

	my $raw_table = $table;
	(my $safe_table = $raw_table) =~ s/[^A-Za-z0-9_]/_/g;
	$safe_table = '_' . $safe_table if $safe_table =~ /\A[0-9]/;
	croak _fmt('error_table_name_invalid', $raw_table)
		unless $safe_table =~ $TABLE_NAME_RE;

	my $self = bless {
		_table         => $safe_table,
		_raw_table     => $raw_table,
		_redis_url     => $redis_url,
		_i18n          => $raw->{i18n},
		_cache         => $raw->{cache},
		_cache_ttl_url => $raw->{cache_ttl_url} // '15 min',
		_id_col        => 'entry',
		_columns       => undef,
		_db            => undef,
	}, $class;

	$self->_init_redis_backend();
	return $self;
}

# _init_redis_backend( $self ) -> void
#
# Purpose: Construct the Database::Abstraction backend for Redis mode.
#          D::A connects to the Redis server lazily (on first data access).
#          We pass redis_key => $raw_table so D::A uses the original key name
#          (which may contain colons, hyphens, etc.) for Redis lookups, while
#          the sanitized $table is used only as the Perl package-name suffix.
#          no_entry => 1 requests array-style rows (no id-keyed hash).
# Entry:   $self->{_redis_url} is a valid redis:// URL.
#          $self->{_table}     is a safe SQL identifier (sanitized key name).
#          $self->{_raw_table} is the original Redis key name.
# Exit:    Sets $self->{_db}.  Croaks when D::A construction fails.
sub _init_redis_backend :Protected {
	my $self  = shift;
	my $table = $self->{_table};

	require Database::Abstraction;

	my $pkg = 'Database::BI::_DB::' . ucfirst($table);
	{
		no strict 'refs';
		push @{"${pkg}::ISA"}, 'Database::Abstraction'
			unless $pkg->isa('Database::Abstraction');
	}

	my $db = eval { $pkg->new(
		database  => $self->{_redis_url},
		table     => $table,
		redis_key => $self->{_raw_table},
	) };
	croak $self->_msg('error_backend_init', $table, $@) if $@;

	$self->{_db} = $db;
	return;
}

# ---------------------------------------------------------------------------
# Protected initialisation
# ---------------------------------------------------------------------------

# _detect_file_info( $dir, $table ) -> \%info
#
# Peek at the first header line of a CSV, TSV or PSV file and return a hashref:
#   sep_char => field separator character (',' or '|')
#   id       => first column name (used as Database::Abstraction's id key)
#   columns  => arrayref of all column names in file order
#
# Two non-obvious defaults in Database::Abstraction make this necessary:
#   1. sep_char defaults to '!' -- so a plain CSV is read as one giant field
#      per row, producing a single comma-joined string instead of columns.
#   2. id defaults to 'entry' -- the slurp filter greps on that column; if it
#      doesn't exist every row is silently discarded.
# Returns an empty hashref for non-CSV/TSV/PSV/XLSX/SQLite formats (XML, etc.).
# For SQLite/.db files that can be opened, returns { sqlite_tables => [...] }.
sub _detect_file_info :Protected {
	my ($dir, $table) = @_;

	# XLSX: DBD::Excel 0.07 only handles .xls (its source skips files whose
	# name does not match /\.xls$/i, so .xlsx is silently ignored).  Parse
	# directly with Spreadsheet::ParseXLSX and return pre-loaded row data so
	# _init_backend can skip D::A entirely, exactly like the headerless-CSV path.
	{
		my $path = File::Spec->catfile($dir, "$table.xlsx");
		if (-r $path) {
			my $ok = eval { require Spreadsheet::ParseXLSX; 1 };
			if ($ok) {
				my $parser = Spreadsheet::ParseXLSX->new;
				my $wb     = $parser->parse($path);
				my $ws     = $wb ? $wb->worksheet(0) : undef;

				unless ($ws) {
					# Empty workbook or parse failure: sentinel so _init_backend
					# skips D::A (which would fail with "(no error string)").
					return { _file_is_empty => 1, file_size => -s $path };
				}

				my ($rmin, $rmax) = $ws->row_range;
				my ($cmin, $cmax) = $ws->col_range;

				# No rows at all (blank worksheet).
				return { _file_is_empty => 1, file_size => -s $path }
					if $rmax < $rmin;

				# Row 0 = column headers.
				my @cols;
				for my $c ($cmin .. $cmax) {
					my $cell = $ws->get_cell($rmin, $c);
					push @cols, defined $cell ? ($cell->value // '') : '';
				}
				for (@cols) { s/\A[\s"]+//; s/[\s"]+\z// }
				@cols = grep { length } @cols;

				# No parseable column names.
				return { _file_is_empty => 1, file_size => -s $path }
					unless @cols;

				my ($safe_id) = grep { $_ =~ $TABLE_NAME_RE } @cols;

				# Data rows.
				my @rows;
				for my $r ($rmin + 1 .. $rmax) {
					my %row;
					for my $i (0 .. $#cols) {
						my $cell = $ws->get_cell($r, $cmin + $i);
						$row{ $cols[$i] } = defined $cell ? ($cell->value // '') : '';
					}
					push @rows, \%row;
				}

				return {
					columns          => \@cols,
					id               => $safe_id,
					_headerless_data => \@rows,
					file_size        => -s $path,
				};
			}
		}
	}

	for my $ext (qw(csv psv tsv)) {
		my $path = File::Spec->catfile($dir, "$table.$ext");
		next unless -r $path;
		# "use autodie" makes open() die on failure, so "or next" would be dead
		# code.  Disable autodie for this open so a vanishing file (race between
		# the -r probe and the open) results in a clean skip rather than a croak.
		my $fh;
		{ no autodie 'open'; open $fh, '<', $path or next }
		my $line = <$fh>;
		# 0-byte file: no header, no rows.  Return a sentinel so _init_backend
		# can skip Database::Abstraction entirely.  If we let D::A see an empty
		# file it falls through to the DBD::CSV path, whose error handling on
		# an empty SELECT corrupts DBI's internal Errstr SV; on a DEBUGGING perl
		# (DBI 1.651 + perl 5.44.0) this triggers an XS assertion at cleanup.
		unless (defined $line) {
			close $fh;
			return { _file_is_empty => 1, file_size => 0 };
		}
		chomp $line;
		$line =~ s/\r\z//;	# strip CR from CRLF files before any split

		my $sep;
		if($ext eq 'psv') {
			$sep = '|';
		} elsif($ext eq 'tsv') {
			$sep = "\t";
		} else {
			# Sniff the separator: Database::Abstraction uses '!' natively and
			# sometimes stores those files with a .csv extension.  If splitting
			# on ',' yields a single field that itself contains '!', the real
			# separator is almost certainly '!'.
			my @probe = split /,/, $line, -1;
			$sep = (@probe == 1 && $line =~ /!/) ? '!' : ',';
		}

		my @cols = split /\Q$sep\E/, $line;
		# Two separate substitutions: the /g on an anchored alternation wastes
		# O(N) engine cycles retrying \A (which can only match at position 0).
		for (@cols) { s/\A[\s"]+//; s/[\s"]+\z// }	# strip whitespace and quotes
		@cols = grep { length } @cols;

		# A blank first line (e.g. a file containing only "\n") produces an
		# empty column list.  Treat that the same as a 0-byte file: return the
		# _file_is_empty sentinel so _init_backend skips D::A entirely.
		# Attempting to construct D::A with id => undef and an empty columns
		# list would croak error_no_safe_id -- misleading for what is effectively
		# an empty file.
		if (!@cols) {
			close $fh;
			return { _file_is_empty => 1, file_size => -s $path };
		}

		# Database::Abstraction validates id against $SAFE_IDENTIFIER
		# (/\A[a-zA-Z_][a-zA-Z0-9_]*\z/) at construction time and uses it as
		# a row-existence sentinel: every data row must have a defined, non-#
		# value in the id column or D::A drops it (empty_is_undef => 1 makes
		# truly empty cells undef).
		#
		# Strategy: read the first non-empty data row and find the first safe
		# column whose value in that row is non-empty.  A simple split (same
		# separator) is used rather than a full CSV parse; it may mis-index
		# fields that contain the separator inside quotes, but correctly detects
		# whether a given index position is blank -- sufficient for id selection.
		# Fall back to the first safe column in the header if the data row
		# check is inconclusive (e.g. file has only a header line).
		my ($safe_id) = grep { $_ =~ $TABLE_NAME_RE } @cols;	# header-only fallback

		my $data_line;
		while (defined($data_line = <$fh>)) {
			chomp $data_line;
			$data_line =~ s/\r\z//;
			last if length $data_line;	# skip blank lines between header and data
		}
		if (defined $data_line) {
			my @vals = split /\Q$sep\E/, $data_line, -1;
			for my $i (0 .. $#cols) {
				next unless $cols[$i] =~ $TABLE_NAME_RE;
				my $val = $vals[$i] // '';
				$val =~ s/\A[\s"]+//;
				$val =~ s/[\s"]+\z//;
				if (length $val) {
					$safe_id = $cols[$i];
					last;
				}
			}
		}
		# If no safe identifier was found in the header, check whether the first
		# row looks like data values rather than column names.  A CSV exported
		# from a bank or accounting system often has no header row at all -- the
		# first line is already a transaction record.  When that is the case,
		# synthesize safe column names by inferring the type of each value
		# (date, amount, description) and pre-read the entire file so
		# _init_backend can return the rows directly without touching D::A.
		unless (defined $safe_id) {
			if (_values_are_data_like(\@cols)) {
				my @synth = _synthesize_col_names(\@cols);
				seek $fh, 0, 0;	# rewind: first line is a data row, not a header
				my @rows;
				while (defined(my $dline = <$fh>)) {
					chomp $dline;
					$dline =~ s/\r\z//;
					next unless length $dline;
					my @vals = split /\Q$sep\E/, $dline, scalar @synth;
					for (@vals) { s/\A[\s"]+//; s/[\s"]+\z// }
					my %row;
					for my $i (0 .. $#synth) {
						$row{ $synth[$i] } = $vals[$i] // '';
					}
					push @rows, \%row;
				}
				close $fh;
				return {
					sep_char         => $sep,
					id               => $synth[0],
					columns          => \@synth,
					_headerless_data => \@rows,
					file_size        => -s $path,
				};
			}
		}

		close $fh;

		# Return file_size so _init_backend can pass it as max_slurp_size to
		# Database::Abstraction.  Without this, files larger than D::A's default
		# 16 KB threshold go through the DBI/DBD::CSV path, which lowercases
		# column names and replaces spaces with underscores ("Account Number" ->
		# "account_number").  The slurp path (Text::xSV::Slurp) preserves the
		# original header names, so forcing it avoids the mismatch.
		return {
			sep_char  => $sep,
			id        => $safe_id,
			columns   => \@cols,
			file_size => -s $path,
		};
	}

	# SQLite / Berkeley DB: peek at sqlite_master to discover the internal table
	# names.  _init_backend uses this list to auto-select the correct table when
	# the filename stem (dbname) differs from the table name inside the file --
	# e.g. obituaries.sql whose internal table is called "deceased".  If the
	# file is not a valid SQLite database (e.g. a Berkeley DB file) the eval
	# fails; for .db files we then check for BerkeleyDB magic so we can read
	# the data directly (or return an error sentinel) instead of letting D::A
	# fall through to its CSV path, which would read a large binary file as text.
	# .sqlite and .sqlite3 are common alternative SQLite extensions -- treated identically to .sql.
	my $non_sqlite_db;	# set to path when a .db file fails the SQLite probe
	for my $ext (qw(sql sqlite sqlite3 db)) {
		my $path = File::Spec->catfile($dir, "$table.$ext");
		next unless -r $path;
		my $tables = eval {
			require DBI;
			my $dbh = DBI->connect(
				"dbi:SQLite:dbname=$path", q{}, q{},
				{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
			my $t = $dbh->selectcol_arrayref(
				q{SELECT name FROM sqlite_master }
				. q{WHERE type='table' AND name NOT LIKE 'sqlite_%' }
				. q{ORDER BY name});
			$dbh->disconnect;
			$t;
		};
		# defined $tables means the eval succeeded (even an empty list is valid)
		return { sqlite_tables => ($tables // []), file_size => -s $path }
			if defined $tables;
		$non_sqlite_db = $path if $ext eq 'db';
		last;	# file found but not SQLite -- do not try the other ext
	}

	# A .db file that is not SQLite: check for BerkeleyDB magic bytes.
	# BerkeleyDB Hash/Btree/Queue files begin with a 32-bit magic number either
	# at offset 0 (big-endian files) or at offset 12 (little-endian files).
	# If found, try to open via DB_File under a 10-second alarm so a version-
	# incompatible file does not block the server for minutes.
	if (defined $non_sqlite_db) {
		my $magic_ok = 0;
		if (open(my $fh, '<:raw', $non_sqlite_db)) {
			my $buf = '';
			if (read($fh, $buf, 4) == 4) {
				my %MAGIC = map { $_ => 1 }
					(0x00061561, 0x00053162, 0x00042253, 0x00052444);
				$magic_ok = 1 if $MAGIC{unpack('N', $buf)} || $MAGIC{unpack('V', $buf)};
			}
			unless ($magic_ok) {
				if (seek $fh, 12, 0) {
					my $b12 = '';
					if (read($fh, $b12, 4) == 4) {
						my $hex = substr(unpack('H*', $b12), 0, 4);
						$magic_ok = 1 if $hex eq '6115' || $hex eq '1561';
					}
				}
			}
			close $fh;
		}
		if ($magic_ok) {
			my $fsize = -s $non_sqlite_db;
			# BerkeleyDB magic confirmed.  Attempt to read via DB_File,
			# but only for reasonably-sized files (<= 100 MB).  Opening a
			# multi-GB BerkeleyDB file with an incompatible library version
			# causes multi-minute disk I/O that cannot be interrupted with
			# alarm() (XS I/O in libdb-5.x ignores SIGALRM via SA_RESTART).
			# For large files, return the unsupported sentinel immediately.
			Readonly my $BDB_MAX_BYTES => 100 * 1024 * 1024;	# 100 MB
			if (defined $fsize && $fsize > $BDB_MAX_BYTES) {
				return { _unknown_binary_db => 1, file_size => $fsize };
			}
			my $data = eval {
				require DB_File;
				my %bdb;
				# Capture the tie object so we can undef it before untie --
				# DB_File warns "untie while N inner references" if the object
				# reference count is > 0 when untie fires.
				my $db_obj = tie %bdb, 'DB_File', $non_sqlite_db,
					Fcntl::O_RDONLY(), 0644, $DB_File::DB_HASH;
				return undef unless $db_obj;
				my @rows = map { { entry => $_, value => $bdb{$_} } } sort keys %bdb;
				undef $db_obj;
				untie %bdb;
				\@rows;
			};
			if (defined $data) {
				return {
					_headerless_data => $data,
					columns          => ['entry', 'value'],
					id               => 'entry',
					file_size        => $fsize,
				};
			}
			# tie failed: return a sentinel so _init_backend can show a proper
			# error instead of letting D::A read the binary file as CSV text.
			return { _unknown_binary_db => 1, file_size => $fsize };
		}
	}
	return {};
}

# _values_are_data_like( \@vals ) -> bool
#
# Return true when the values look like actual data (dates, numbers, free text)
# _sniff_data_ext( $path ) -> $ext
#
# Peek at the content of $path and return the standard file extension that best
# describes its format.  Used when a remote file has a non-standard extension
# (e.g. ".log") and we need to rename it so that _detect_file_info and
# Database::Abstraction can discover it automatically.
#
# Detection order:
#   1. SQLite magic bytes ("SQLite format 3") -> 'db'
#   2. XML preamble ("<?xml" or "<" as first non-space character) -> 'xml'
#   3. First data line contains tabs -> 'tsv'
#   4. First data line contains pipes -> 'psv'
#   5. Fallback -> 'csv'
sub _sniff_data_ext {
	my $path = $_[0];
	open(my $fh, '<:raw', $path) or return 'csv';
	my $header = '';
	read $fh, $header, 20;
	close $fh;
	return 'db'  if $header =~ /\ASQLite format/;
	return 'xml' if $header =~ /\A\s*<\?xml/i;
	return 'xml' if $header =~ /\A\s*</;
	open(my $lh, '<', $path) or return 'csv';
	my $line = <$lh>;
	close $lh;
	return 'csv' unless defined $line;
	return 'tsv' if $line =~ /\t/;
	return 'psv' if $line =~ /\|/;
	return 'csv';
}

# _values_are_data_like( \@vals ) -> bool
#
# Returns true when the values look like a row of real data (dates / numbers)
# rather than column headers.  Used to detect header-less CSV files where the
# first line is a data row.  At least one value must match a date or numeric
# pattern -- a row of plain hyphenated identifiers (e.g. "First-Name") is NOT
# considered data-like.
sub _values_are_data_like {
	my $vals = $_[0];
	for my $v (@{$vals}) {
		return 1 if $v =~ /\A\d{4}-\d{2}-\d{2}\z/;		# YYYY-MM-DD
		return 1 if $v =~ /\A\d{1,2}\/\d{1,2}\/\d{4}\z/;	# M/D/YYYY or D/M/YYYY
		return 1 if $v =~ /\A[+\-]\d+(?:\.\d+)?\z/;		# signed numeric (e.g. -75.13)
		return 1 if $v =~ /\A\(\d+(?:\.\d+)?\)\z/;		# accounting negative (e.g. (75.13))
	}
	return 0;
}

# _synthesize_col_names( \@vals ) -> @names
#
# Infer a safe SQL identifier for each positional value by examining its
# content: ISO dates become "Date", numeric/currency values become "Amount",
# and free text becomes "Description".  Duplicate types are disambiguated with
# a numeric suffix (Date, Date2, Date3, ...).
sub _synthesize_col_names {
	my $vals = $_[0];
	my %type_count;
	my @names;
	for my $v (@{$vals}) {
		my $type;
		if ($v =~ /\A\d{4}-\d{2}-\d{2}\z/ || $v =~ /\A\d{1,2}\/\d{1,2}\/\d{4}\z/) {
			$type = 'Date';
		} elsif ($v =~ /\A[+\-]?\d+(?:\.\d+)?\z/ || $v =~ /\A\(\d+(?:\.\d+)?\)\z/) {
			$type = 'Amount';
		} else {
			$type = 'Description';
		}
		$type_count{$type}++;
		push @names, $type_count{$type} == 1 ? $type : $type . $type_count{$type};
	}
	return @names;
}

# _cache_key( $self ) -> $key | undef
#
# Purpose: Derive a stable cache key for this DataSource's full result set.
#          URL tables use a fixed key (TTL handles invalidation).
#          File tables encode the file's mtime in the key so a changed file
#          naturally produces a miss -- the stale entry is orphaned and evicts
#          passively when the CHI driver reclaims memory.
# Entry:   $self->{_cache} must be defined (caller checks this before calling).
# Exit:    Returns a non-empty string key, or undef when no key is derivable
#          (no URL, no file path on disk).
sub _cache_key :Protected {
	my $self = shift;

	if (defined $self->{_url}) {
		my $idx = $self->{_html_table_index} // 0;
		# Include the table index in the key: a different index on the same URL
		# selects a different table from the page and must not share a cache entry.
		return 'bi:url:' . $self->{_url} . ':' . $idx;
	}

	if (defined $self->{_file_path} && -f $self->{_file_path}) {
		my $mtime = (stat($self->{_file_path}))[9];
		return defined $mtime
			? 'bi:file:' . $self->{_file_path} . ':' . $mtime
			: undef;
	}

	return undef;
}

# _init_backend( $self ) -> void
#
# Strategy: Database::Abstraction is designed as a base class where the
# lowercased package name maps to the data file in the directory
# (e.g. "Database::BI::_DB::Sales" -> data/sales.csv or data/sales.db).
# We synthesise an ephemeral subclass at runtime so DataSource remains
# fully table-agnostic and callers never need to touch Database::Abstraction
# directly. In Phase 2, this method can be replaced with Database::Join
# instantiation without any change to the public API.
#
# no_entry => 1: a BI viewer wants every row; we do not need O(1) keyed
# lookups on a primary key.  This stores data as an arrayref instead of a
# hashref, which the fast-track path in selectall_arrayref returns directly.
sub _init_backend :Protected {
	my $self      = shift;
	my $table     = $self->{_table};     # sanitized: used for pkg name and D::A table param
	my $raw_table = $self->{_raw_table} // $table;  # original: used for file lookup and dbname
	my $dir       = $self->{_directory};

	# Remote file path (host is set): download via SFTP to a local temp directory,
	# then proceed with normal local processing on the downloaded copy.
	# Net::SFTP::Foreign is loaded lazily so non-remote usage has no extra deps.
	if (defined $self->{_host}) {
		eval { require Net::SFTP::Foreign }
			or croak $self->_msg('error_backend_init', $table,
				'Net::SFTP::Foreign is not installed (required for remote file access)');
		require File::Temp;
		# Split optional user@host into ($user, $host).
		my ($user, $host) = $self->{_host} =~ /\A([^@]+)\@(.+)\z/
			? ($1, $2) : (undef, $self->{_host});
		my $tmpdir = File::Temp->newdir(CLEANUP => 1);
		my @remote_exts = qw(csv tsv psv xlsx xls sql sqlite sqlite3 db xml);
		# Try the caller-supplied extension first (e.g. .log), then fall back.
		if (defined $self->{_file_ext}) {
			my $hint = lc $self->{_file_ext};
			@remote_exts = ($hint, grep { $_ ne $hint } @remote_exts);
		}
		# One SFTP connection shared across all extension attempts.
		my $sftp = eval { Net::SFTP::Foreign->new($host,
			defined $user ? (user => $user) : (),
			timeout => 10,
		) };
		croak $self->_msg('error_backend_init', $table,
			"could not connect to $host via SFTP: " . ($@ || ($sftp ? $sftp->error : 'unknown')))
			unless defined $sftp && !$sftp->error;
		my $fetched_ext;
		for my $ext (@remote_exts) {
			my $remote_path = "$dir/$raw_table.$ext";
			my $local_file  = File::Spec->catfile("$tmpdir", "$raw_table.$ext");
			$sftp->get($remote_path, $local_file);
			# Verify the file landed on disk; sftp->error may be set on ENOENT.
			next if $sftp->error || !-f $local_file || !-s $local_file;
			$fetched_ext = $ext;
			last;
		}
		croak $self->_msg('error_backend_init', $table,
			"could not fetch any supported file from $self->{_host}:$dir/$raw_table.*")
			unless defined $fetched_ext;
		$self->{_remote_tmpdir} = $tmpdir;	# prevents cleanup until $self is destroyed

		# If the downloaded file has a non-standard extension (e.g. .log), rename
		# it to one that _detect_file_info and D::A can discover automatically.
		# We do this by sniffing the first bytes/line for format signatures.
		my %KNOWN_EXT = map { $_ => 1 }
			qw(csv tsv psv xlsx xls sql sqlite sqlite3 db xml);
		unless ($KNOWN_EXT{lc $fetched_ext}) {
			my $orig_file = File::Spec->catfile("$tmpdir", "$raw_table.$fetched_ext");
			my $std_ext   = _sniff_data_ext($orig_file);
			if ($std_ext ne lc $fetched_ext) {
				my $new_file = File::Spec->catfile("$tmpdir", "$raw_table.$std_ext");
				{ no autodie; rename $orig_file, $new_file }
				$fetched_ext = $std_ext;
			}
		}

		$dir = "$tmpdir";	# switch to local temp dir for all subsequent processing
	}

	require Database::Abstraction;

	my $pkg = 'Database::BI::_DB::' . ucfirst($table);
	{
		no strict 'refs';
		push @{"${pkg}::ISA"}, 'Database::Abstraction'
			unless $pkg->isa('Database::Abstraction');
	}

	my $info   = _detect_file_info($dir, $raw_table);

	# Probe for the actual file on disk so _cache_key can compute its mtime.
	# This runs before the early-return paths so even empty files get a path.
	for my $e (qw(csv tsv psv sql sqlite sqlite3 xml db xlsx xls)) {
		my $p = File::Spec->catfile($dir, "$raw_table.$e");
		if (-f $p) {
			$self->{_file_path} = File::Spec->rel2abs($p);
			last;
		}
	}

	# BerkeleyDB file detected by magic bytes, but tie() failed (version
	# incompatibility -- e.g. the file uses BDB format 9 but the installed
	# libdb only supports an older format).  Croak now so D::A never falls
	# through to its CSV path and reads the entire binary file as text.
	if ($info->{_unknown_binary_db}) {
		croak $self->_msg('error_unsupported_db', $raw_table);
	}

	# 0-byte file: skip D::A/DBI entirely.  D::A on an empty file falls through
	# to DBD::CSV, whose error handling corrupts DBI's Errstr SV and triggers an
	# XS assertion failure at cleanup on DEBUGGING perls (DBI 1.651, perl 5.44).
	if ($info->{_file_is_empty}) {
		$self->{_columns}       = [];
		$self->{_id_col}        = 'entry';
		$self->{_file_is_empty} = 1;
		return;
	}

	# Headerless CSV or XLSX: _detect_file_info already pre-loaded all rows.
	# MUST check before error_no_safe_id: XLSX files with all-unsafe column
	# headers (e.g. "First Name", "Account Number") have id => undef because
	# none of the headers match the safe-identifier regex, but the data is
	# pre-loaded and the id column is irrelevant for the direct-data fast path.
	# Checking error_no_safe_id first would croak spuriously for valid XLSX files.
	if ($info->{_headerless_data}) {
		$self->{_id_col}  = $info->{id} // 'entry';
		$self->{_columns} = $info->{columns};
		$self->{_file_data} = $info->{_headerless_data};
		return;
	}

	# _detect_file_info returns undef for id when every column header contains
	# characters that are not safe SQL identifiers (spaces, hyphens, etc.).
	# Falling back to the D::A default ('entry') would silently return 0 rows
	# since no 'entry' column exists.  Croak with a human-readable message.
	# This guard applies only to CSV/TSV/PSV/SQLite/XML -- headerless and XLSX paths
	# are handled by the _headerless_data check immediately above.
	croak $self->_msg('error_no_safe_id', $table)
		if exists $info->{columns} && !defined $info->{id};
	my $id_col = $info->{id} // 'entry';
	$self->{_id_col}  = $id_col;
	$self->{_columns} = $info->{columns};	# undef for SQLite/XML

	# D::A validates dbname as a SQL identifier and rejects names that contain
	# spaces or other characters that are illegal in SQL (e.g. "transactions for
	# Nigel").  This check fires at query time (inside selectall_arrayref) for
	# the DBI path used by XLSX, SQLite, and XML files -- after construction
	# succeeds -- so the error surfaces as error_fetch_failed, not error_backend_init.
	#
	# Fix: when the original filename stem was sanitized (raw_table != table),
	# create a temporary directory with a symlink that uses the safe name.
	# D::A opens the symlink, sees a space-free dbname, and builds valid SQL.
	# The temp-dir object is kept in $self so the symlink persists for the full
	# lifetime of this DataSource instance and is cleaned up automatically when
	# $self is destroyed.
	my $dbname = $raw_table;
	my $da_dir = $dir;
	if ($raw_table ne $table) {
		my $safe_ext;
		for my $e (qw(xlsx xls db sql sqlite sqlite3 xml csv tsv psv)) {
			$safe_ext = $e, last
				if -f File::Spec->catfile($dir, "$raw_table.$e");
		}
		if (defined $safe_ext) {
			require File::Temp;
			my $tmp     = File::Temp->newdir(CLEANUP => 1);
			my $abs_src = File::Spec->rel2abs(
				File::Spec->catfile($dir, "$raw_table.$safe_ext"));
			my $link    = File::Spec->catfile("$tmp", "$table.$safe_ext");
			{
				no autodie;	# symlink failure gives our message, not autodie's
				symlink($abs_src, $link)
					or croak $self->_msg('error_backend_init', $table,
						"cannot create safe-name symlink for '$raw_table.$safe_ext': $!");
			}
			$self->{_tmpdir} = $tmp;	# prevents cleanup until $self is destroyed
			$dbname = $table;
			$da_dir = "$tmp";
		}
	}

	# SQLite: _detect_file_info probed sqlite_master and returned the internal
	# table names.  When $dbname (the filename stem or its safe alias) is not
	# among those names, auto-select the first user table (or use the caller-
	# supplied internal_table) and create a symlink from <target>.<ext> to the
	# original file so D::A can issue SQL against the real table name.
	# D::A uses 'dbname' to find the file and 'table' for the SELECT statement,
	# so both must be set to the actual table name when a mismatch is corrected.
	my $da_table = $table;	# D::A 'table' param -- controls the SQL table name
	if (exists $info->{sqlite_tables}) {
		my @tbls = @{ $info->{sqlite_tables} };
		croak $self->_msg('error_no_tables', $raw_table) unless @tbls;

		# Store the full table list so callers (e.g. the tables_view action)
		# can detect multi-table databases after construction.
		$self->{_sqlite_tables} = \@tbls;

		# Determine target table: caller-specified or auto-detected.
		my $desired = $self->{_internal_table};
		my $target;
		if (defined $desired) {
			my ($found) = grep { $_ eq $desired } @tbls;
			croak $self->_msg('error_table_not_found', $raw_table, $desired)
				unless defined $found;
			$target = $desired;
		} else {
			my ($match) = grep { $_ eq $dbname } @tbls;
			$target = defined $match ? $match : $tbls[0];
		}

		# When the target differs from dbname, create a symlink so D::A can
		# find the file by target name and issue SELECT * FROM <target>.
		# Always use a D::A-recognised SQLite extension (.sql, .sqlite, .sqlite3)
		# for the symlink name -- D::A does not use the DBI/SQLite backend for
		# .db files, so a customer.db symlink would be read as CSV.
		if ($target ne $dbname) {
			my ($src_ext) = grep { -f File::Spec->catfile($dir, "$raw_table.$_") }
				qw(sql sqlite sqlite3 db);
			$src_ext //= 'sql';
			my $link_ext = ($src_ext eq 'db') ? 'sql' : $src_ext;
			require File::Temp;
			my $tmp     = File::Temp->newdir(CLEANUP => 1);
			my $abs_src = File::Spec->rel2abs(
				File::Spec->catfile($dir, "$raw_table.$src_ext"));
			my $link = File::Spec->catfile("$tmp", "$target.$link_ext");
			{
				no autodie;
				symlink($abs_src, $link)
					or croak $self->_msg('error_backend_init', $raw_table,
						"cannot create table-name symlink for '$raw_table.$src_ext': $!");
			}
			$self->{_tmpdir} = $tmp;
			$dbname   = $target;		# D::A uses this for the filename stem
			$da_table = $target;		# D::A uses this for SELECT * FROM <table>
			$da_dir   = "$tmp";
		}
	}

	my $db = eval {
		$pkg->new({
			directory      => $da_dir,
			table          => $da_table,
			# D::A >= 0.41 uses the class-name suffix as dbname, not the table
			# parameter, so a package like Database::BI::_DB::Orders would look
			# for Orders.csv on a case-sensitive filesystem even when table =>
			# 'orders' is passed.  Passing dbname explicitly keeps the filename
			# stem correct regardless of the package name or D::A version.
			# When the table name was sanitized (spaces, hyphens -> underscores),
			# $dbname is the safe name so D::A never sees illegal SQL characters,
			# and D::A finds the file via the symlink in $da_dir.
			dbname         => $dbname,
			id             => $id_col,
			no_entry       => 1,
			defined($info->{sep_char})  ? (sep_char       => $info->{sep_char})  : (),
			# Force the Text::xSV::Slurp path for CSV/TSV/PSV files: D::A's default
			# slurp threshold is 16 KB; larger files fall back to DBD::CSV, which
			# sanitizes column names (lowercases and replaces spaces with
			# underscores).  Passing the actual file size ensures the slurp path
			# is always taken, so "Account Number" stays "Account Number" rather
			# than becoming "account_number".
			defined($info->{file_size}) ? (max_slurp_size => $info->{file_size}) : (),
		});
	};
	if ($@) {
		croak $self->_msg('error_backend_init', $table, $@);
	}

	$self->{_db} = $db;
	return;
}

# ---------------------------------------------------------------------------
# Public accessors
# ---------------------------------------------------------------------------

=head1 ACCESSORS

=head2 table_name

Returns the (lowercased) table name this instance was opened against.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Returns a C<SCALAR> string.

=head3 MESSAGES

None.

=cut

sub table_name {
	my $self = shift;
	return $self->{_table};
}

=head2 sqlite_tables

Returns an arrayref of internal table names when the backing file is a
multi-table SQLite database, or C<undef> for single-table and non-SQLite
sources.  Set during C<_init_backend> after probing C<sqlite_master>.

When the return value is a reference to a list with B<more than one
element>, the caller should redirect the user to the schema browser
(C</tables>) so they can pick which table to open, rather than
silently opening the first one.

Example:

    my $tbls = $source->sqlite_tables;
    if ($tbls && @{$tbls} > 1) {
        # multiple tables -- let the user choose
        print "Tables: ", join(', ', @{$tbls}), "\n";
    }

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

    ARRAYREF of SCALAR    # ['customer', 'product', 'sales'] for a 3-table SQLite file
    undef                 # for CSV, TSV, PSV, XML, URL-backed, and single-table SQLite

The arrayref contains the names in the order returned by C<sqlite_master>
(alphabetical).  It is set once during construction and never changes.

=head3 MESSAGES

None.

=cut

sub sqlite_tables {
	my $self = shift;
	return $self->{_sqlite_tables};
}

=head2 columns

Returns an arrayref of column names in file order, or C<undef> when no order
is available.

=over 4

=item CSV / TSV / PSV / XLSX

Column names come from the file header (first row).  They are returned in
the order they appear in the file.  For header-less files (detected
automatically) the synthesized names (C<Date>, C<Amount>, C<Description>,
etc.) are returned in the same synthesized order.

=item SQLite / XML

Falls back to the underlying C<Database::Abstraction> object's C<columns()>
method.  This is useful when a C<DataSource> is passed directly to
C<Database::Join> as a component database.

=item URL-backed tables

Always returns C<undef>.  C<Database::Abstraction> fetches URL data lazily,
so calling C<_db-E<gt>columns()> here would trigger a live network request even
when the data came from the CHI cache.  The controller derives column order
from the data records instead (alphabetical fallback).

=item Redis-backed tables

Delegates to the underlying C<Database::Abstraction> C<columns()>, which
triggers a lazy open of the Redis connection on first call and returns the
column names derived from the first stored row (alphabetical order, includes
C<entry>).  This is required so that C<Database::Join> can validate the
join column at construction time.

=back

Always check the return value before dereferencing:

    my $cols = $source->columns;
    if ($cols) {
        print join(', ', @{$cols}), "\n";
    } else {
        # URL-backed tables: derive columns from the first data row
    }

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

    ARRAYREF of SCALAR    # ['id', 'name', 'price', ...] -- original header order
    undef                 # SQLite, XML, URL-backed tables

=head3 MESSAGES

None.

=cut

sub columns {
	my $self = shift;
	return $self->{_columns} if defined $self->{_columns};
	# URL-backed tables have no canonical column order at construction time;
	# calling _db->columns() would trigger a live HTTP request which may fail.
	# Return undef so _get_columns derives column names from fetched data.
	return undef if defined $self->{_url};
	# Redis-backed tables: delegate to _db->columns() which triggers the lazy
	# open() on first call.  D::J requires a real column list at construction
	# time so returning undef here would make join validation always fail.
	# D::A builds its Redis column list from hgetall fields only and omits the
	# entry key (the suffix of the Redis key pattern tablename:entryid).
	# Prepend the id column so callers and D::J see a complete column list.
	if (defined $self->{_redis_url} && $self->{_db}) {
		my $da_cols  = $self->{_db}->columns() // [];
		my $id       = $self->{_id_col} // 'entry';
		my @full     = ($id, grep { $_ ne $id } @{$da_cols});
		$self->{_columns} = \@full;
		return $self->{_columns};
	}
	return $self->{_db} ? $self->{_db}->columns() : undef;
}

=head2 dbi_source

Returns a hashref C<{ dbh =E<gt> $dbh, table =E<gt> $name }> for SQLite-backed
instances, and C<undef> for everything else.

C<Database::Join> 0.009.0 probes C<dbi_source> at join-construction time to
decide whether it can take the zero-copy C<ATTACH> path (avoiding a row-by-row
spill into a temporary SQLite file).  Without this method, every C</join> on a
SQLite-backed C<DataSource> uses the spill path regardless of row count.

Returns C<undef> for:

=over 4

=item *

0-byte and header-less pre-parsed files (C<_file_is_empty>, C<_file_data> set).

=item *

Redis-backed and URL-backed sources (no DBI handle).

=item *

Any backend that does not itself implement C<dbi_source>.

=back

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

    { dbh => $dbh_object, table => 'table_name' }   # SQLite-backed
    undef                                            # all other backends

=head3 MESSAGES

None.

=cut

sub dbi_source {
	my $self = shift;
	return undef if $self->{_file_is_empty};
	return undef if $self->{_file_data};
	return undef unless $self->{_db};
	return undef unless $self->{_db}->can('dbi_source');
	my $result = eval { $self->{_db}->dbi_source() };
	return undef if $@;
	return $result;
}

=head2 aggregate

Delegates to the inner C<Database::Abstraction> backend's C<aggregate()> method
(requires C<Database::Abstraction> E<gt>= 0.49).

Returns C<[]> for in-memory backends (headerless CSV, XLSX, empty files) and for
URL-backed sources where aggregation is not available.

Accepts the same C<by>, C<measures>, C<having>, C<sort_by>, C<limit>, C<offset>,
and WHERE-criteria parameters as C<Database::Abstraction::aggregate()>.

=head3 API SPECIFICATION

=head4 INPUT

  by        arrayref    Column names to GROUP BY.
  measures  arrayref    Measure descriptors (see Database::Abstraction::aggregate).
  having    hashref     Optional HAVING criteria.
  sort_by   string      Optional ORDER BY column.
  limit     integer     Optional result limit.
  offset    integer     Optional result offset.
  (any other key)       WHERE column criteria passed through to D::A.

=head4 OUTPUT

  arrayref of hashrefs   -- one row per group.
  []                     -- in-memory / empty / URL-backed sources.

=head3 MESSAGES

None.

=cut

sub aggregate {
	my ($self, @args) = @_;
	return [] if $self->{_file_is_empty};
	return [] if $self->{_file_data};
	return [] unless $self->{_db};
	return [] unless $self->{_db}->can('aggregate');
	return $self->{_db}->aggregate(@args);
}

=head2 id_column

Returns the name of the column used as the primary key and as
C<Database::Abstraction>'s row-existence anchor.

For file-backed tables this is the first column in the CSV/TSV/PSV header
whose name is a valid SQL identifier (letters, digits, underscores only,
not starting with a digit) B<and> whose value in the first data row is
non-empty.  C<DataSource> detects this automatically to avoid the
C<Database::Abstraction> default of C<'entry'>, which would silently
discard every row in a file that has no C<entry> column.

Returns C<undef> for URL/HTML-table backends (no primary-key concept applies).

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

    SCALAR string    # e.g. 'id', 'date', 'sku' -- the first safe-identifier column
    undef            # URL-backed (HTML table import) sources

=head3 MESSAGES

None.

=cut

sub id_column {
	my $self = shift;
	return $self->{_id_col};
}

=head2 source_url

Returns the source URL for URL/HTML-table-backed instances.
Returns C<undef> for all file-backed instances (local files and SFTP-fetched
remote files).

Use this to distinguish a URL-backed C<DataSource> from a file-backed one
when you need to decide whether to show a "re-fetch" button to the user.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

    SCALAR string    # 'https://example.com/data.html' -- the original URL
    undef            # file-backed (local or SFTP) sources

=head3 MESSAGES

None.

=cut

sub source_url {
	my $self = shift;
	return $self->{_url};
}

=head2 updated

Returns the Unix epoch timestamp (mtime) of the backing data file, or
C<undef> for URL-backed tables and for sources whose file cannot be
C<stat()>-ed.

C<Database::Join> calls C<updated()> on each component database to
detect whether its SQLite spill cache is stale.  When a source file changes
on disk, the mtime increases, the join detects the change, and re-runs the
join rather than serving stale cached data.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

    SCALAR integer   # Unix epoch seconds, e.g. 1728601234
    undef            # URL-backed tables, or file cannot be stat()-ed

=head3 MESSAGES

None.

=cut

sub updated {
	my $self = shift;
	# Delegate to the D::A backend when available -- it tracks mtime internally.
	return $self->{_db}->updated() if $self->{_db} && $self->{_db}->can('updated');
	# Fallback: stat the file path directly (header-less CSV and XLSX bypass D::A).
	return (stat($self->{_file_path}))[9] if defined $self->{_file_path} && -f $self->{_file_path};
	return undef;
}

# ---------------------------------------------------------------------------
# Public data-access methods
# ---------------------------------------------------------------------------

=head1 METHODS

=head2 fetch_all

Returns every record in the table as an arrayref of hashrefs (one hashref
per row; keys are the column names).

This is the primary data-retrieval method.  It is equivalent to calling
C<selectall_arrayref> with no arguments and normalising the result to an
arrayref.  Prefer C<selectall_arrayref> when passing to C<Database::Join>
(it is the method that C<Database::Join> calls internally).

Filtering (C<eq>, C<contains>, C<gt>, C<lt>, etc.) is applied at the
controller layer by C<Dashboard::_apply_filter_spec> after C<fetch_all>
returns.  C<DataSource> itself is filter-unaware.

Three fast-path shortcuts are checked before touching the DBI backend,
in this order:

=over 4

=item 1.

C<_file_is_empty> is set (0-byte or blank-first-line file) -- returns C<[]>
immediately, no DBI connection.

=item 2.

C<_file_data> is set (pre-parsed header-less CSV, XLSX, or BerkeleyDB data) --
returns the in-memory arrayref directly.

=item 3.

A matching CHI cache entry exists -- returns the cached arrayref without
calling C<Database::Abstraction>.

=back

=head3 API SPECIFICATION

=head4 INPUT

None.  Filtering is applied at the controller layer, not inside C<DataSource>.

=head4 OUTPUT

    ARRAYREF of HASHREF   # one hashref per row; keys are column names
    []                    # empty arrayref when the file is empty or has no data rows

Croaks (via C<croak>) when the backend raises an exception.  Emits a
warning via C<carp> (non-fatal) when the result set is empty, so the
caller can distinguish "opened successfully, no data" from a silent
failure.

=head3 MESSAGES

  error_fetch_failed     -- backend threw an exception during retrieval
  warn_empty_result      -- query succeeded but returned zero records
  warn_data_normalised   -- backend returned a hashref; converted to arrayref

=cut

=head2 selectall_arrayref

C<Database::Abstraction>-compatible alias that allows a C<DataSource> object
to be passed directly to C<Database::Join> as a component database.

When called with no arguments (the normal path for a full-table scan),
results are served from the CHI cache when available.  When called with
arguments (e.g. C<limit =E<gt> N, offset =E<gt> M> for server-side
pagination), the cache is bypassed -- narrowed results must not pollute
the full-table cache entry.

Three fast-path shortcuts are checked before touching the DBI backend:

=over 4

=item 1.

C<_file_is_empty> is set -- returns C<[]> immediately.

=item 2.

C<_file_data> is set (pre-parsed headerless CSV / XLSX / BerkeleyDB) -- returns
the in-memory rows directly.

=item 3.

A matching CHI cache entry exists for the full-table scan -- returns the
cached arrayref.

=back

=head3 API SPECIFICATION

=head4 INPUT

Optional flat key/value list passed through to C<Database::Abstraction>:

    limit  => N    # return at most N rows (used by pagination)
    offset => M    # skip the first M rows (used by pagination)

When no arguments are given, the full table is returned (and cached).

=head4 OUTPUT

    ARRAYREF of HASHREF   # one hashref per row; keys are column names
    []                    # empty arrayref when the file is empty or no rows match

=head3 MESSAGES

None.  Errors from the DBI backend propagate as uncaught exceptions; wrap
calls in C<eval> if you need to recover.

=cut

sub selectall_arrayref {
	my ($self, @args) = @_;
	return [] if $self->{_file_is_empty};
	return $self->{_file_data} if $self->{_file_data};

	# Cache only plain unfiltered calls -- Database::Join passes no args for the
	# full table scan; a non-empty @args means a narrowed query whose result must
	# not be mistaken for the full-table cache entry.
	my $cache = $self->{_cache};
	if ($cache && !@args) {
		my $key = $self->_cache_key;
		if (defined $key) {
			my $hit = $cache->get($key);
			return $hit if defined $hit;
		}
	}

	my $data = $self->{_db}->selectall_arrayref(@args);

	if ($cache && !@args && defined $data) {
		my $key = $self->_cache_key;
		if (defined $key) {
			defined $self->{_url}
				? $cache->set($key, $data, $self->{_cache_ttl_url})
				: $cache->set($key, $data);
		}
	}

	return $data;
}

sub fetch_all {
	my $self  = shift;
	my $table = $self->{_table};

	# 0-byte file: no backend was created; nothing to fetch.
	return [] if $self->{_file_is_empty};

	# Headerless CSV/XLSX: data was pre-parsed with synthesized column names.
	return $self->{_file_data} if $self->{_file_data};

	# Cache check: URL tables benefit from avoiding repeated HTTP round-trips;
	# file tables benefit from skipping disk I/O and CSV/TSV/PSV parsing.
	my $cache = $self->{_cache};
	if ($cache) {
		my $key = $self->_cache_key;
		if (defined $key) {
			my $hit = $cache->get($key);
			return $hit if defined $hit;
		}
	}

	my $data = eval { $self->{_db}->selectall_hashref() };
	if ($@) {
		croak $self->_msg('error_fetch_failed', $table, $@);
	}

	return [] unless defined $data;

	# Strategy: Database::Abstraction can return either an arrayref (when the
	# underlying driver iterates rows) or a hashref keyed by primary key (when
	# it mirrors DBI's selectall_hashref semantics). We normalise to arrayref
	# here so every caller above this layer sees a uniform structure.
	if (ref $data eq 'HASH') {
		carp $self->_msg('warn_data_normalised', $table);
		$data = [ values %{$data} ];
	}

	if (!@{$data}) {
		carp $self->_msg('warn_empty_result', $table);
	}

	# Cache store: URL tables use a TTL so stale pages expire automatically;
	# file tables encode mtime in the key so a changed file produces a natural
	# miss without any explicit invalidation.
	if ($cache) {
		my $key = $self->_cache_key;
		if (defined $key) {
			defined $self->{_url}
				? $cache->set($key, $data, $self->{_cache_ttl_url})
				: $cache->set($key, $data);
		}
	}

	return $data;
}

=head2 count

Returns the total number of rows in the table.

For pre-parsed sources (header-less CSV, XLSX, BerkeleyDB) the count comes
from the already-loaded in-memory slice and is instant (no I/O).  For
empty-file sentinels it returns C<0> immediately.  For all DBI-backed
sources (SQLite, large CSV via DBD::CSV) it delegates to
C<Database::Abstraction::count()>, which issues a
C<SELECT COUNT(*) FROM E<lt>tableE<gt>> query against the file.

B<Warning: do not call C<count()> on a very large SQLite file> if you
only need to know whether a next page exists.  The pagination controller
uses the N+1 trick (fetch C<per_page + 1> rows via C<limit/offset>)
specifically to avoid a C<COUNT(*)> on multi-gigabyte databases, which
can block the server for minutes.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

    SCALAR non-negative integer   # total row count, 0 for empty files

=head3 MESSAGES

None.

=cut

sub count {
	my ($self) = @_;
	return 0 if $self->{_file_is_empty};
	return scalar @{ $self->{_file_data} } if $self->{_file_data};
	return $self->{_db}->count();
}

1;

__END__

=head1 COMMON PITFALLS

These are the most common mistakes when using C<DataSource>.

=over 4

=item B<SQLite databases may use .sql, .sqlite, or .sqlite3 as their file extension>

C<DataSource> recognises C<.sql>, C<.sqlite>, and C<.sqlite3> as SQLite
database files.  It does B<not> recognise C<.db3>.  If you have a file called
C<inventory.db3>, rename it to C<inventory.sql> before passing it to
C<DataSource>.

=item B<The table name is always lowercased>

The constructor lowercases the C<table> argument before using it.  Passing
C<table =E<gt> 'Sales'> and C<table =E<gt> 'sales'> both look for
C<sales.csv> (or C<sales.sql>, etc.).  The matching is case-insensitive on the
table name but B<case-sensitive on the directory path>.

=item B<CSV files with the wrong separator appear as one giant field per row>

C<Database::Abstraction> defaults to C<!> (exclamation mark) as its field
separator.  A standard comma-separated CSV file will look like one big field
per row (for example, C<1,Widget A,North,100>) because the library never sees
the commas as separators.  C<DataSource> fixes this automatically by reading
the first line of the file and detecting the actual separator.  If you bypass
C<DataSource> and call C<Database::Abstraction> directly, you B<must> pass
C<sep_char =E<gt> ','> yourself.

=item B<A table with no "entry" column returns zero rows (without DataSource)>

C<Database::Abstraction> uses C<entry> as its default primary-key column name.
When slurping a CSV, it discards any row where C<$row-E<gt>{entry}> is
undefined.  Because most CSV files do not have an C<entry> column, B<all rows
are silently discarded>.  C<DataSource> prevents this by reading the actual
first column name from the CSV header and passing it as C<id>, and also by
setting C<no_entry =E<gt> 1> so all rows are kept as an ordered array.

=item B<columns() returns undef for SQLite and XML files>

C<columns()> only returns an arrayref for file formats where the header order
is visible before data is read (CSV, TSV and PSV).  For SQLite and XML files it
returns C<undef>.  Always check: C<if ($source-E<gt>columns) { ... }>.  The
controller falls back to putting C<id_column> first and then sorting the rest
alphabetically when C<columns()> is C<undef>.

=item B<XML elements named "name", "id", or "key" cause parse failures>

C<XML::Simple> (used by C<Database::Abstraction> for XML files) automatically
turns a child element called C<name>, C<id>, or C<key> into a hash key instead
of keeping it as an array element.  This breaks the expected data structure.
Use different element names in your XML: for example, C<E<lt>skuE<gt>>,
C<E<lt>labelE<gt>>, or C<E<lt>codeE<gt>> instead of C<E<lt>idE<gt>> and
C<E<lt>nameE<gt>>.

  <!-- WRONG: these element names trigger XMLin key-folding -->
  <items>
    <item><id>1</id><name>Widget</name></item>
  </items>

  <!-- CORRECT: use neutral element names -->
  <items>
    <item><sku>1</sku><label>Widget</label></item>
  </items>

=item B<fetch_all returns an empty arrayref, not undef, for an empty table>

When a table exists but contains no data rows, C<fetch_all> returns C<[]> (an
empty arrayref), not C<undef>.  Check with C<scalar @{$records}>, not with
C<defined $records> or C<$records>.

=item B<0-byte CSV/TSV/PSV files bypass Database::Abstraction entirely>

When C<_detect_file_info> opens a CSV, TSV or PSV file and the first C<readline>
returns C<undef> (the file is 0 bytes), it returns a C<{ _file_is_empty =E<gt>
1 }> sentinel instead of the normal C<{ id, sep_char, columns, file_size }>
hashref.  C<_init_backend> detects this sentinel and skips
C<Database::Abstraction> construction; C<fetch_all> returns C<[]> immediately.
B<No DBI connection is created for 0-byte files.>  If you mock or spy on DBI
handles and open a 0-byte CSV, the mock will never fire - this is expected
behaviour, not a mock misconfiguration.

=item B<Remote files require Net::SFTP::Foreign; one connection per open>

When C<host> is set, C<DataSource> makes one SFTP connection per C<new()>
call.  It tries the extension list in order (the C<file_ext> hint first,
if provided, then the full standard-extension list) and downloads the first
file it finds.  If no file is found under any tried extension, C<new()>
croaks C<error_backend_init>.  B<Connections are not pooled or reused>
between C<DataSource> instances.

If the remote file has a non-standard extension (e.g. C<.log>, C<.dat>),
the content is sniffed: SQLite magic bytes map to C<.db>, an XML preamble
to C<.xml>, a tab-delimited first line to C<.tsv>, a pipe-delimited line to
C<.psv>, and everything else to C<.csv>.  The temp file is then renamed to
the detected extension before further processing.

=item B<Multi-table SQLite: opening without internal_table silently picks the first table>

When a SQLite file contains more than one user-defined table and you call
C<new()> without C<internal_table>, C<DataSource> auto-selects the first
table whose name matches the filename stem; if there is no match, it picks
whatever C<sqlite_master> lists first.  This is B<silent> -- you get data
from a table you may not have intended to open.

Always check C<sqlite_tables()> after construction if you are dealing
with a SQLite file that might have multiple tables:

    my $tbl_list = $source->sqlite_tables;
    if ($tbl_list && @{$tbl_list} > 1) {
        # warn the user or redirect to the schema browser
    }

=item B<The symlink used for .db-extension SQLite files is named .sql, not .db>

C<Database::Abstraction> does not use its DBI/SQLite backend for files
with a C<.db> extension -- it falls through to the CSV reader, which tries
to read a SQLite binary file as text and fails with a parse error.

When C<DataSource> detects a multi-table SQLite C<.db> file, it creates a
temporary symlink named C<E<lt>tableE<gt>.sql> (not C<.db>) pointing to the
original C<.db> file.  SQLite follows symlinks transparently, so the data is
read correctly.  If you ever audit temporary directories and see C<*.sql>
symlinks pointing at C<*.db> files, this is expected and intentional.

=item B<DBD::CSV silently lowercases column names for files larger than 16 KB>

C<Database::Abstraction> uses C<Text::xSV::Slurp> for files up to 16 KB and
DBD::CSV for larger ones.  The DBD::CSV path lowercases column names and
replaces spaces with underscores (C<Account Number> becomes
C<account_number>), which causes a C<"disallowed key"> error at render time
when the template iterates the original column names.  C<DataSource> avoids
this by always passing C<max_slurp_size =E<gt> -s $path> to
C<Database::Abstraction>, forcing the slurp path regardless of file size.
If you call C<Database::Abstraction> directly, you B<must> pass this option
yourself for any file whose column names contain spaces or mixed case.

=back

=head1 LIMITATIONS

=over 4

=item *

Only read operations are supported.  Write-back is not in scope.

=item *

One C<DataSource> instance corresponds to exactly one table.  Multi-table
joins are now delegated to C<Database::Join> (see L<Database::Join>), which
accepts C<DataSource> objects directly as component databases via the
C<selectall_arrayref> and C<columns> methods this class exposes.

=item *

The ephemeral backend class is generated into a package namespace
(C<Database::BI::_DB::*>) that persists for the lifetime of the process.
Instantiating two C<DataSource> objects for the same table name reuses
the same ephemeral class.

=item *

The C<i18n> object, if supplied, must implement C<maketext($key, @args)>
compatible with L<Locale::Maketext>.

=back

=head1 CONFIGURATION AND ENVIRONMENT

No environment variables are read.  All configuration is passed through
the constructor.

=head1 DEPENDENCIES

L<Carp>, L<Readonly>, L<Scalar::Util>, L<Params::Validate::Strict>, L<Params::Get>,
L<Database::Abstraction>.

Optional (loaded lazily):

L<Net::SFTP::Foreign> -- required for remote file access (C<host =E<gt> ...>).
L<Spreadsheet::ParseXLSX> -- required for opening C<.xlsx> files.

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

Please report bugs via L<https://github.com/nigelhorne/Database-BI/issues>.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 FORMAL SPECIFICATION

The following specifications use a Z-calculus notation.
C<undef> represents the undefined Perl value.
C<seq T> means an ordered sequence of values of type T.
C<\A...\z> denotes a Perl regular expression match.
C<|S|> means the cardinality (size) of set or sequence S.

=head2 new

  new == [directory : PATH; table : NAME;
          host? : HOST_STRING; file_ext? : EXT_STRING;
          internal_table? : STRING;
          cache? : CHI_OBJECT; cache_ttl_url? : TTL_STRING;
          i18n? : I18N_OBJECT]
         pre  (host = undef => is_dir directory)
              /\ (host /= undef => host =~ /\A(?:[a-zA-Z0-9][a-zA-Z0-9._-]*\@)?[a-zA-Z0-9][a-zA-Z0-9._-]*\z/)
              /\ table /= ""
              /\ table =~ /[^\/\\\x00]/
         post result.class = DataSource
              /\ (host = undef => result._db.class = Database::Abstraction | result._file_data /= undef | result._file_is_empty)
              /\ (host /= undef => result._remote_tmpdir /= undef)
              /\ (internal_table /= undef => internal_table in result._sqlite_tables)

=head2 table_name

  table_name == lambda self . self._table

  pre  self._table /= undef
  post result : STRING /\ result =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/

=head2 sqlite_tables

  sqlite_tables == lambda self . self._sqlite_tables

  pre  true
  post (result = undef /\ self._url /= undef)
       \/ (result = undef /\ source is not SQLite)
       \/ (result : seq STRING /\ forall t in result . t =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/)

=head2 columns

  columns == lambda self .
    if defined self._columns then self._columns
    else if defined self._url then undef
    else if defined self._db  then self._db.columns()
    else undef

  pre  true
  post (result : seq STRING /\ |result| >= 1)
       \/ (result = undef)

=head2 id_column

  id_column == lambda self . self._id_col

  pre  true
  post (result : STRING /\ result =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/)
       \/ (result = undef)

=head2 source_url

  source_url == lambda self . self._url

  pre  true
  post (result : STRING /\ result =~ /\Ahttps?:\/\//)
       \/ (result = undef)

=head2 updated

  updated == lambda self .
    if defined self._db /\ can(self._db, 'updated')  then self._db.updated()
    else if defined self._file_path /\ -f self._file_path then (stat self._file_path)[9]
    else undef

  pre  true
  post (result : N /\ result > 0) \/ (result = undef)

=head2 fetch_all

  fetch_all == lambda self .
    if self._file_is_empty                     then []
    else if defined self._file_data            then self._file_data
    else if cache_hit(self)                    then cache_get(self)
    else
      let rows = self._db.selectall_hashref() in
      normalise(rows)

  pre  self._file_is_empty \/ defined self._file_data \/ defined self._db
  post result : seq HASHREF
       /\ |result| >= 0

=head2 selectall_arrayref

  selectall_arrayref == lambda self args .
    if self._file_is_empty                         then []
    else if defined self._file_data /\ args = ()   then self._file_data
    else if cache_hit(self) /\ args = ()           then cache_get(self)
    else self._db.selectall_arrayref(args)

  pre  self._file_is_empty \/ defined self._file_data \/ defined self._db
  post result : seq HASHREF /\ |result| >= 0

=head2 count

  count == lambda self .
    if self._file_is_empty     then 0
    else if defined self._file_data then |self._file_data|
    else self._db.count()

  pre  self._file_is_empty \/ defined self._file_data \/ defined self._db
  post result : N /\ result >= 0

=head1 STATE DIAGRAM

The lifecycle of a single C<DataSource> object from creation to destruction.
Each state is stable until the trigger event listed to its right fires.

    +------------------+
    |     [START]      |  -- new() called
    +------------------+
             |
             v
    +------------------+  _detect_file_info + _init_backend run
    |   INITIALISING   |  (SFTP download, BerkeleyDB probe, SQLite
    |                  |   sqlite_master probe, CSV header parse,
    |                  |   XLSX parse, or URL fetch)
    +------------------+
          /     \
         /       \
        v         v
  +----------+  +-----------+
  |  ERROR   |  |   READY   |
  | (croaks) |  |           |
  +----------+  +-----------+
                 |         |
                 |         |
    fetch_all()  |         |  selectall_arrayref()
    called       |         |  called
                 v         v
         +---------------+
         |   FETCHING    |  DBI query or pre-loaded data returned;
         |               |  result stored in CHI cache (if configured)
         +---------------+
                 |
                 v
         +---------------+
         | DATA RETURNED |  arrayref of hashrefs delivered to caller
         +---------------+
                 |
                 | (next call to fetch_all or selectall_arrayref)
                 v
         +---------------+
         | CACHE CHECK   |  CHI cache hit? -> DATA RETURNED immediately
         |               |  CHI cache miss? -> FETCHING
         +---------------+

    Special cases branching from INITIALISING:

    1. File is 0 bytes or blank first line
       -> _file_is_empty flag set -> READY (fetch_all returns [] instantly)

    2. Header-less CSV / XLSX / BerkeleyDB
       -> _file_data pre-loaded -> READY (fetch_all returns pre-loaded rows)

    3. Multi-table SQLite without internal_table
       -> _sqlite_tables set -> READY
       -> caller inspects sqlite_tables() and may redirect to /tables
          before calling fetch_all (which would open the auto-selected table)

    4. Multi-table SQLite WITH internal_table
       -> symlink created for named table -> READY -> fetch_all opens that table

    5. SFTP remote file
       -> Net::SFTP::Foreign::get() -> local tmpdir -> normal init -> READY
       -> tmpdir kept alive via $self->{_remote_tmpdir} until DESTROY

    Object lifetime ends when $self goes out of scope:

    +---------------+
    |   DESTROY     |  File::Temp tmpdirs auto-cleaned (symlinks removed,
    |               |  SFTP tmpdir removed)
    +---------------+

    Valid state transitions summary:

    [START]          -> INITIALISING     (new() invoked)
    INITIALISING     -> ERROR            (croak on bad args, SFTP failure,
                                          no safe id, no SQLite tables, etc.)
    INITIALISING     -> READY            (all checks passed)
    READY            -> FETCHING         (fetch_all / selectall_arrayref, cache miss)
    READY            -> DATA RETURNED    (fetch_all, _file_is_empty or _file_data fast-path)
    READY            -> CACHE CHECK      (fetch_all / selectall_arrayref, cache configured)
    CACHE CHECK      -> DATA RETURNED    (cache hit)
    CACHE CHECK      -> FETCHING         (cache miss)
    FETCHING         -> DATA RETURNED    (DBI query completed)
    DATA RETURNED    -> CACHE CHECK      (next call, cache configured)
    DATA RETURNED    -> FETCHING         (next call, no cache)
    READY / DATA RETURNED -> DESTROY     ($self goes out of scope)

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
