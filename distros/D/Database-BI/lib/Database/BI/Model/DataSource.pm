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

our $VERSION = '0.009.0';

=head1 NAME

Database::BI::Model::DataSource - Table-agnostic adapter around Database::Abstraction

=head1 VERSION

0.007.0

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

=head2 UTF-8 and Encoding

C<DataSource> passes cell values through as Perl character strings exactly
as L<Database::Abstraction> and the underlying DBI driver return them.
For CSV, TSV and PSV files smaller than 16 KB, L<Text::xSV::Slurp> is used and
bytes are returned without re-encoding; for larger files the L<DBD::CSV>
path is used.  In both cases the caller (the controller) is responsible
for setting the correct C<Content-Type> header.

The C<table> argument and all column names must be B<ASCII-only>
identifiers.  Full Unicode is supported inside B<cell values> -- the
restriction applies only to structural metadata (column headers, table
name), not to the data itself.

URL-backed tables (the C<url =E<gt>> constructor path) are fetched with
L<LWP::UserAgent::Cached>.  If the remote server declares a charset in
its HTTP headers or HTML meta tag, L<Database::Abstraction> uses it to
decode the response body.  If the declaration is absent or wrong, cell
values may contain raw bytes rather than character strings.

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
	    directory     => 'string',   # required; local dir, or remote dir when host is set
	    table         => 'string',   # required; bare file stem (no extension)
	    host          => 'string',   # optional; "hostname" or "user@hostname" for SFTP access
	    file_ext      => 'string',   # optional; extension hint when remote file has non-standard suffix (e.g. "log")
	    cache         => 'object',   # optional; CHI cache object for result caching
	    cache_ttl_url => 'string',   # optional; CHI TTL string for URL-backed tables (default "15 min")
	    i18n          => 'object',   # optional; must implement maketext($key, @args) for i18n
	}

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
	return $class->_new_from_url($raw) if exists $raw->{url};

	my $args = validate_strict(
		schema => {
			directory     => { type => 'string' },
			table         => { type => 'string' },
			host          => { type => 'string', optional => 1, default => undef },
			file_ext      => { type => 'string', optional => 1, default => undef },
			i18n          => { type => 'object', optional => 1, default => undef, can => 'maketext' },
			cache         => { type => 'object', optional => 1, default => undef },
			cache_ttl_url => { type => 'string', optional => 1, default => '15 min' },
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
		_directory    => $args->{directory},
		_table        => $safe_table,
		_raw_table    => $raw_table,
		_host         => $args->{host},
		_file_ext     => $args->{file_ext},
		_i18n         => $args->{i18n},
		_cache        => $args->{cache},
		_cache_ttl_url => $args->{cache_ttl_url},
		_db           => undef,
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

				my $safe_re = qr/\A[a-zA-Z_][a-zA-Z0-9_]*\z/;
				my ($safe_id) = grep { $_ =~ $safe_re } @cols;

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
		my $safe_re = qr/\A[a-zA-Z_][a-zA-Z0-9_]*\z/;
		my ($safe_id) = grep { $_ =~ $safe_re } @cols;	# header-only fallback

		my $data_line;
		while (defined($data_line = <$fh>)) {
			chomp $data_line;
			$data_line =~ s/\r\z//;
			last if length $data_line;	# skip blank lines between header and data
		}
		if (defined $data_line) {
			my @vals = split /\Q$sep\E/, $data_line, -1;
			for my $i (0 .. $#cols) {
				next unless $cols[$i] =~ $safe_re;
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
	# fails and we return {} so _init_backend/D::A handles it natively.
	# .sqlite and .sqlite3 are common alternative SQLite extensions -- treated identically to .sql.
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
		last;	# file found but not SQLite -- do not try the other ext
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
	# among those names, auto-select the first user table and create a symlink
	# from <actual_table>.<ext> to the original file so D::A can issue SQL
	# against the real table name without needing the filename to match.
	# D::A uses 'dbname' to find the file and 'table' for the SELECT statement,
	# so both must be set to the actual table name when a mismatch is corrected.
	my $da_table = $table;	# D::A 'table' param -- controls the SQL table name
	if (exists $info->{sqlite_tables}) {
		my @tbls = @{ $info->{sqlite_tables} };
		croak $self->_msg('error_no_tables', $raw_table) unless @tbls;
		my ($match) = grep { $_ eq $dbname } @tbls;
		unless (defined $match) {
			my $actual   = $tbls[0];
			my ($src_ext) = grep { -f File::Spec->catfile($dir, "$raw_table.$_") }
				qw(sql sqlite sqlite3 db);
			$src_ext //= 'sql';
			require File::Temp;
			my $tmp     = File::Temp->newdir(CLEANUP => 1);
			my $abs_src = File::Spec->rel2abs(
				File::Spec->catfile($dir, "$raw_table.$src_ext"));
			my $link = File::Spec->catfile("$tmp", "$actual.$src_ext");
			{
				no autodie;
				symlink($abs_src, $link)
					or croak $self->_msg('error_backend_init', $raw_table,
						"cannot create table-name symlink for '$raw_table.$src_ext': $!");
			}
			$self->{_tmpdir} = $tmp;
			$dbname   = $actual;	# D::A uses this for the filename stem
			$da_table = $actual;	# D::A uses this for SELECT * FROM <table>
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

=head2 columns

Returns an arrayref of column names in file order, or C<undef> when no order
is available.  For CSV, TSV and PSV files the order comes from the file header.
For SQLite and XML, falls back to the underlying C<Database::Abstraction>
object's C<columns()> - useful when a C<DataSource> is passed directly to
C<Database::Join> as a component database.

=cut

sub columns {
	my $self = shift;
	return $self->{_columns} if defined $self->{_columns};
	# URL-backed tables have no canonical column order; D::A fetches lazily so
	# calling _db->columns() here would trigger a live network request even when
	# the data came from the CHI cache.  Return undef and let _get_columns derive
	# the list from the data records instead.
	return undef if defined $self->{_url};
	return $self->{_db} ? $self->{_db}->columns() : undef;
}

=head2 id_column

Returns the name of the column used as the primary key / slurp-filter anchor.
Returns C<undef> for URL/HTML-table backends (no primary-key concept applies).

=cut

sub id_column {
	my $self = shift;
	return $self->{_id_col};
}

=head2 source_url

Returns the source URL for URL/HTML-table-backed instances, or C<undef> for
file-backed instances.

=cut

sub source_url {
	my $self = shift;
	return $self->{_url};
}

# ---------------------------------------------------------------------------
# Public data-access methods
# ---------------------------------------------------------------------------

=head1 METHODS

=head2 fetch_all

Returns every record in the table as an arrayref of hashrefs.

=head3 API SPECIFICATION

=head4 INPUT

None.  Filtering is performed at the controller layer (C<Dashboard::_apply_filter_spec>)
after C<fetch_all> returns, not inside C<DataSource>.

=head4 OUTPUT

	ARRAYREF of HASHREF   # one hashref per row, keys are column names
	                      # returns [] when the table exists but is empty

Croaks if the backend raises an exception. Carps (non-fatal) when the result
set is empty so the caller can distinguish "open succeeded, no rows" from a
silent failure.

=head3 MESSAGES

  error_fetch_failed     -- backend threw an exception during retrieval
  warn_empty_result      -- query succeeded but returned zero records
  warn_data_normalised   -- backend returned a hashref; converted to arrayref

=cut

=head2 selectall_arrayref

C<Database::Abstraction>-compatible alias that allows a C<DataSource> object
to be passed directly to C<Database::Join> as a component database.  Passes
any criteria through to the underlying backend; the BI viewer always calls it
with no arguments.

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

=head2 new

  new == [directory : PATH; table : NAME;
          host? : HOST_STRING; file_ext? : EXT_STRING;
          cache? : CHI_OBJECT; cache_ttl_url? : TTL_STRING;
          i18n? : I18N_OBJECT]
         pre  (host = undef => is_dir directory)
              /\ (host /= undef => host =~ REMOTE_HOST_RE)
              /\ table /= ""
         post result.class = DataSource
              /\ (host = undef => result._db.class = Database::Abstraction)
              /\ (host /= undef => result._remote_tmpdir /= undef)

=head2 table_name

  table_name == lambda self . self._table

=head2 fetch_all

  fetch_all == lambda self .
    let rows = self._db.selectall_hashref() in
    pre  self._db /= undef
    post result : seq HASHREF
         /\ #result >= 0

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
