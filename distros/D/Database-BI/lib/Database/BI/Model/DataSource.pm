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

our $VERSION = '0.005.2';

=head1 NAME

Database::BI::Model::DataSource - Table-agnostic adapter around Database::Abstraction

=head1 VERSION

Version 0.005.2

=head1 SYNOPSIS

B<Read all rows from a CSV file:>

    use Database::BI::Model::DataSource;

    my $source = Database::BI::Model::DataSource->new(
        directory => '/path/to/data',
        table     => 'sales',           # looks for data/sales.csv, .psv, .sql, .xml, etc.
    );

    my $records = $source->fetch_all;   # arrayref of hashrefs -- one hashref per row

    for my $row (@{$records}) {
        printf "Product: %s, Amount: %s\n", $row->{product}, $row->{amount};
    }

B<Get column names in the original file order (CSV/PSV only):>

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

B<Use a custom i18n object to translate error messages:>

    # The i18n object must have a maketext($key, @args) method.
    my $source = Database::BI::Model::DataSource->new(
        directory => '/path/to/data',
        table     => 'sales',
        i18n      => My::I18N::Handle->new,
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
(CSV, PSV, SQLite, XML, etc.) automatically from a directory based on the
calling class name.  C<DataSource> generates an ephemeral subclass at
construction time so callers never interact with L<Database::Abstraction>
directly.  To swap the backend for L<Database::Join> in Phase 2, only the
C<open_table> helper in C<Database::BI> needs to change; the controller and
C<DataSource> are untouched.

C<_detect_file_info> peeks at the first header line of CSV/PSV files to
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
	my ($url) = @_;
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
	    directory => 'string',           # required; path to the data directory
	    table     => 'string',           # required; bare table/file name (no extension)
	    i18n      => { type => 'object', optional => 1, can => 'maketext' } # must implement maketext($key, @args)
	}

Accepts a flat key/value list, a hashref, or positional arguments via
C<Params::Get>.

=head4 DOMAIN CONSTRAINTS

=over 4

=item C<directory>

Must satisfy C<-d $directory> (must exist and be a directory).  An empty
string, a non-existent path, or the path to a regular file all produce
C<error_directory_missing>.

  Valid partition:   any existing directory path
  Invalid partition: non-existent path, regular file path, empty string ""

=item C<table>

Must match C<TABLE_NAME_RE = \A[A-Za-z_][A-Za-z0-9_]*\z>.  The first
character must be a letter (A-Z, a-z) or underscore; subsequent
characters may also be digits.

  Valid partition:   "sales", "_tmp", "report_2024" (letter/underscore start)
  Invalid partition: "1sales" (digit-start), "my.data" (dot),
                     "my-data" (hyphen), "" (empty string)
  Boundary values:   "a" (length-1 letter, valid), "_" (length-1 underscore,
                     valid), "1" (length-1 digit, croaks error_table_name_invalid)

=back

=head4 OUTPUT

Returns C<$self> (a blessed hashref). Croaks on invalid arguments.

=head3 MESSAGES

  error_directory_required    -- "directory" argument was not supplied
  error_table_required        -- "table" argument was not supplied
  error_directory_missing     -- supplied directory does not exist / is unreadable
  error_table_name_invalid    -- table name fails the safe-identifier check
  error_backend_init          -- Database::Abstraction subclass could not be instantiated

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
			directory => { type => 'string' },
			table     => { type => 'string' },
			i18n      => { type => 'object', optional => 1, default => undef, can => 'maketext' },
		},
		input => $raw,
	);

	croak _fmt('error_directory_missing', $args->{directory})
		unless -d $args->{directory};

	croak _fmt('error_table_name_invalid', $args->{table})
		unless $args->{table} =~ $TABLE_NAME_RE;

	my $self = bless {
		_directory => $args->{directory},
		_table     => $args->{table},
		_i18n      => $args->{i18n},
		_db        => undef,
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

	my $self = bless {
		_url   => $url,
		_table => _url_label($url),
		_i18n  => $raw->{i18n},
		_id_col  => undef,
		_columns => undef,
		_db      => undef,
	}, $class;

	$self->_init_url_backend($raw->{html_table_index} // 0);
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
# Peek at the first header line of a CSV or PSV file and return a hashref:
#   sep_char => field separator character (',' or '|')
#   id       => first column name (used as Database::Abstraction's id key)
#   columns  => arrayref of all column names in file order
#
# Two non-obvious defaults in Database::Abstraction make this necessary:
#   1. sep_char defaults to '!' — so a plain CSV is read as one giant field
#      per row, producing a single comma-joined string instead of columns.
#   2. id defaults to 'entry' — the slurp filter greps on that column; if it
#      doesn't exist every row is silently discarded.
# Returns an empty hashref for non-CSV/PSV formats (SQLite, XML, etc.).
sub _detect_file_info :Protected {
	my ($dir, $table) = @_;
	for my $ext (qw(csv psv)) {
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
		if ($ext eq 'psv') {
			$sep = '|';
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
		# whether a given index position is blank — sufficient for id selection.
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
	return {};
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
	my $self  = shift;
	my $table = $self->{_table};
	my $dir   = $self->{_directory};

	require Database::Abstraction;

	my $pkg = 'Database::BI::_DB::' . ucfirst($table);
	{
		no strict 'refs';
		push @{"${pkg}::ISA"}, 'Database::Abstraction'
			unless $pkg->isa('Database::Abstraction');
	}

	my $info   = _detect_file_info($dir, $table);

	# 0-byte file: skip D::A/DBI entirely.  D::A on an empty file falls through
	# to DBD::CSV, whose error handling corrupts DBI's Errstr SV and triggers an
	# XS assertion failure at cleanup on DEBUGGING perls (DBI 1.651, perl 5.44).
	if ($info->{_file_is_empty}) {
		$self->{_columns}       = [];
		$self->{_id_col}        = 'entry';
		$self->{_file_is_empty} = 1;
		return;
	}

	# _detect_file_info returns undef for id when every column header contains
	# characters that are not safe SQL identifiers (spaces, hyphens, etc.).
	# Falling back to the D::A default ('entry') would silently return 0 rows
	# since no 'entry' column exists.  Croak with a human-readable message.
	croak $self->_msg('error_no_safe_id', $table)
		if exists $info->{columns} && !defined $info->{id};
	my $id_col = $info->{id} // 'entry';
	$self->{_id_col}  = $id_col;
	$self->{_columns} = $info->{columns};	# undef for SQLite/XML

	my $db = eval {
		$pkg->new({
			directory      => $dir,
			table          => $table,
			# D::A >= 0.41 uses the class-name suffix as dbname, not the table
			# parameter, so a package like Database::BI::_DB::Orders would look
			# for Orders.csv on a case-sensitive filesystem even when table =>
			# 'orders' is passed.  Passing dbname explicitly keeps the filename
			# stem correct regardless of the package name or D::A version.
			dbname         => $table,
			id             => $id_col,
			no_entry       => 1,
			defined($info->{sep_char})  ? (sep_char       => $info->{sep_char})  : (),
			# Force the Text::xSV::Slurp path for CSV/PSV files: D::A's default
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

Returns an arrayref of column names in file order, or C<undef> when the
backend does not expose a fixed column order (e.g. SQLite, XML).

=cut

sub columns {
	my $self = shift;
	return $self->{_columns};
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

sub fetch_all {
	my $self  = shift;
	my $table = $self->{_table};

	# 0-byte file: no backend was created; nothing to fetch.
	return [] if $self->{_file_is_empty};

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

	return $data;
}

1;

__END__

=head1 COMMON PITFALLS

These are the most common mistakes when using C<DataSource>.

=over 4

=item B<SQLite databases must use .sql as their file extension>

C<Database::Abstraction> looks for SQLite databases with the C<.sql> extension.
It does B<not> recognise C<.sqlite>, C<.sqlite3>, or C<.db3>.  If you have a
file called C<inventory.sqlite>, rename it to C<inventory.sql> before passing
it to C<DataSource>.

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
is visible before data is read (CSV and PSV).  For SQLite and XML files it
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

=item B<0-byte CSV/PSV files bypass Database::Abstraction entirely>

When C<_detect_file_info> opens a CSV or PSV file and the first C<readline>
returns C<undef> (the file is 0 bytes), it returns a C<{ _file_is_empty =E<gt>
1 }> sentinel instead of the normal C<{ id, sep_char, columns, file_size }>
hashref.  C<_init_backend> detects this sentinel and skips
C<Database::Abstraction> construction; C<fetch_all> returns C<[]> immediately.
B<No DBI connection is created for 0-byte files.>  If you mock or spy on DBI
handles and open a 0-byte CSV, the mock will never fire — this is expected
behaviour, not a mock misconfiguration.

=back

=head1 LIMITATIONS

=over 4

=item *

Only read operations are supported.  Write-back is not in scope.

=item *

One C<DataSource> instance corresponds to exactly one table.  Multi-table
left joins are composed at the controller layer by C<Dashboard::_left_join>;
C<Database::Join> (Phase 2) is not yet in use.

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

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

Please report bugs via L<https://github.com/nigelhorne/Database-BI/issues>.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 FORMAL SPECIFICATION

=head2 new

  new == [directory : PATH; table : NAME; i18n? : I18N_OBJECT]
         pre  (directory in dom FILE_SYSTEM /\ is_dir directory)
              /\ table =~ TABLE_NAME_RE
         post result.class = DataSource
              /\ result._db.class = Database::Abstraction

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
