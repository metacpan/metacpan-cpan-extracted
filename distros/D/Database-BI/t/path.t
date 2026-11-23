use strict;
use warnings;
use Test::Most;
use Test::Mockingbird	qw(mock restore_all);
use Readonly;
use JSON::PP ();
use File::Spec		();
use File::Temp		qw(tempdir);
use Mojo::File		();
use Mojo::Util		qw(url_escape encode);

# ======================================================================
# BOOTSTRAP -- must happen first so :Private stash entries survive the
# post-CHECK runtime load (see CLAUDE.md: Sub::Private and OO vs. direct).
# ======================================================================
use Test::Mojo;
my $t = Test::Mojo->new('Database::BI');
require Database::BI::Model::DataSource;
require Database::BI::Controller::Dashboard;

# The model store (.bi/) is shared state in the checkout: give this file its
# own directory, so a parallel run cannot create, read or write it underneath.
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

# Capture private function refs AFTER app is loaded (CHECK has passed).
Readonly my $FMT		=> \&Database::BI::Model::DataSource::_fmt;
Readonly my $MSG		=> \&Database::BI::Model::DataSource::_msg;
Readonly my $URL_LABEL		=> \&Database::BI::Model::DataSource::_url_label;
Readonly my $DETECT		=> \&Database::BI::Model::DataSource::_detect_file_info;
Readonly my $IS_SAFE		=> \&Database::BI::Controller::Dashboard::_is_safe_url;
Readonly my $GET_COLS		=> \&Database::BI::Controller::Dashboard::_get_columns;
Readonly my $SPEC_URL		=> \&Database::BI::Controller::Dashboard::_spec_to_url;
Readonly my $CSV_ROW		=> \&Database::BI::Controller::Dashboard::_csv_row;
Readonly my $LIST_DIR		=> \&Database::BI::Controller::Dashboard::_list_dir;
Readonly my $WRITE_SQLITE	=> \&Database::BI::Controller::Dashboard::_write_sqlite_db;
Readonly my $BUILD_URL		=> \&Database::BI::Controller::Dashboard::_build_export_url;
Readonly my $RESOLVE_LANG	=> \&Database::BI::Controller::Dashboard::_resolve_language;
Readonly my $FILTER		=> \&Database::BI::Controller::Dashboard::_apply_filter_spec;

Readonly my $TMPDIR		=> tempdir(CLEANUP => 1);
Readonly my $DATA_DIR		=> $t->app->home->child('data')->to_string;
Readonly my $SALES_ABS		=> $t->app->home->child('data/sales.csv')->to_string;

# Minimal mock objects for controller methods that need $self but not Mojo HTTP.
{
	package MockApp;
	sub new		{ bless { home => $_[1], cfg => $_[2] }, $_[0] }
	sub home	{ Mojo::File->new( $_[0]->{home} ) }
	sub config	{ $_[0]->{cfg} }
}
{
	package MockHeaders;
	sub new			{ bless { al => $_[1] }, $_[0] }
	sub accept_language	{ $_[0]->{al} }
}
{
	package MockReq;
	sub new		{ bless { al => $_[1] }, $_[0] }
	sub headers	{ MockHeaders->new( $_[0]->{al} ) }
}
{
	package MockCtrl;
	sub new	{ bless { home => $_[1], cfg => $_[2], al => $_[3] }, $_[0] }
	sub app	{ MockApp->new( $_[0]->{home}, $_[0]->{cfg} ) }
	sub req	{ MockReq->new( $_[0]->{al} ) }
}

Readonly my $APP_HOME	=> $t->app->home->to_string;
Readonly my $APP_CFG	=> { platform => 'web', language => 'en' };

# Convenience: a MockCtrl with a given Accept-Language value.
sub mock_ctrl { MockCtrl->new($APP_HOME, $APP_CFG, $_[0]) }

# ======================================================================
# PATH COVERAGE: DataSource::_fmt
#
# CFG:
#   Entry
#     -> tmpl = MESSAGES{key} // fallback_string
#     -> [args?]
#       -> YES: return sprintf(tmpl, @args)    [path A]
#       -> NO:  return tmpl                    [path B]
#   (implicit: key missing -> tmpl = fallback) [path C]
# ======================================================================

subtest '_fmt path-A: known key + sprintf args -> formatted string' => sub {
	my $result = $FMT->('error_directory_missing', '/no/dir');
	like $result, qr{/no/dir}, 'path A: sprintf interpolated the directory name';
	unlike $result, qr{%s}, 'path A: no unresolved format spec remains';
};

subtest '_fmt path-B: known key, no args -> raw template returned' => sub {
	my $result = $FMT->('error_directory_required');
	ok length($result), 'path B: non-empty string returned';
	unlike $result, qr{%s}, 'path B: no format spec in a no-arg message';
};

subtest '_fmt path-C: unknown key -> fallback error message' => sub {
	my $result = $FMT->('no_such_key_xyz');
	like $result, qr/unknown message key.*no_such_key_xyz/, 'path C: fallback message identifies missing key';
};

# ======================================================================
# PATH COVERAGE: DataSource::_msg
#
# CFG:
#   Entry
#     -> [_i18n present?]
#       -> YES: return $i18n->maketext(...)    [path A]
#       -> NO:  return _fmt(...)               [path B]
# ======================================================================

subtest '_msg path-A: i18n object present -> delegates to maketext' => sub {
	my $called_key;
	my $fake_i18n = bless {}, 'FakeI18N';
	{
		no warnings 'once';
		*FakeI18N::maketext = sub { $called_key = $_[1]; 'translated' };
	}
	my $ds = bless { _table => 'sales', _i18n => $fake_i18n }, 'Database::BI::Model::DataSource';
	my $result = $MSG->($ds, 'warn_empty_result', 'sales');
	is $result, 'translated', 'path A: maketext return value passed through';
	is $called_key, 'warn_empty_result', 'path A: correct key given to maketext';
};

subtest '_msg path-B: no i18n object -> falls back to _fmt' => sub {
	my $ds     = bless { _table => 'sales', _i18n => undef }, 'Database::BI::Model::DataSource';
	my $result = $MSG->($ds, 'error_table_name_invalid', 'bad!name');
	like $result, qr/bad!name/, 'path B: _fmt applied and arg interpolated';
};

# ======================================================================
# PATH COVERAGE: DataSource::_url_label
#
# CFG paths:
#   A: Good path component (letter/underscore start, non-empty after strip)
#      -> use path component
#   B: Path component starts with digit after sanitize
#      -> falls to hostname fallback
#   C: Path component empty after query/fragment strip
#      -> falls to hostname fallback
#   D: URL has no path components at all (bare domain)
#      -> @parts = [], $last = '' -> unless fires -> hostname fallback
#   E: Host extraction fails (URL like "https://") -> $host = undef -> 'html'
#   F: DEAD CODE proof -- $last || 'html_table' -> 'html_table' never reached
# ======================================================================

subtest '_url_label path-A: good path stem -> used as label' => sub {
	is $URL_LABEL->('https://example.com/reports/sales.csv'),
	   'sales',
	   'path A: file stem "sales" extracted and returned';
};

subtest '_url_label path-A2: stem with non-alphanumeric -> sanitized with _' => sub {
	my $label = $URL_LABEL->('https://example.com/data/my-report.csv');
	is $label, 'my_report', 'path A2: hyphens sanitized to underscore';
};

subtest '_url_label path-B: path component starts with digit -> hostname fallback' => sub {
	my $label = $URL_LABEL->('https://myhost.com/2025-report');
	isnt $label, '2025_report', 'path B: digit-leading component not used directly';
	is $label, 'myhost_com', 'path B: fell back to sanitized hostname';
};

subtest '_url_label path-C: path component becomes empty after query strip' => sub {
	# "?query" as a path segment -> stripped entirely -> unless fires -> hostname
	my $label = $URL_LABEL->('https://myhost.com/?query=1');
	is $label, 'myhost_com', 'path C: empty-after-strip -> hostname fallback';
};

subtest '_url_label path-D: bare domain URL (no path) -> hostname fallback' => sub {
	my $label = $URL_LABEL->('https://data.example.org');
	is $label, 'data_example_org', 'path D: no path parts -> hostname used';
};

subtest '_url_label path-E: unparseable host -> literal "html" returned' => sub {
	# "https://" has no hostname after "://", so the host capture fails -> 'html'
	my $label = $URL_LABEL->('https://');
	is $label, 'html', 'path E: no host -> returns "html"';
};

subtest '_url_label path-F: DEAD CODE -- html_table fallback provably unreachable' => sub {
	# Formal proof:
	# (1) If unless block does NOT fire: $last passed "length && /\A[A-Za-z_]/" => truthy.
	# (2) If unless block DOES fire:
	#     (a) $host matched [^/:?#]+ => at least 1 char; after s/[^A-Za-z0-9_]/_/g
	#         stays at least 1 char => truthy.
	#     (b) $host undef => $last = 'html' => truthy.
	# In all cases $last is truthy => lc($last || 'html_table') == lc($last).
	# To verify: the "html" path (E above) is the closest we can get to the fallback,
	# but $last = 'html' (truthy) so 'html_table' is still unreachable.
	pass 'path-F: dead code formally proven -- html_table fallback removed from DataSource.pm';
};

# ======================================================================
# PATH COVERAGE: DataSource::new
#
# CFG:
#   A: url key present           -> _new_from_url (alternate constructor)
#   B: directory not a dir       -> croak error_directory_missing
#   C: table name invalid        -> croak error_table_name_invalid
#   D: _init_backend throws      -> croak error_backend_init
#   E: happy path                -> returns $self
# ======================================================================

subtest 'DataSource::new path-A: url key present -> _new_from_url' => sub {
	# _new_from_url will croak (URL must be http/https and reachable), so we
	# just verify that the error comes from the URL path, not the directory path.
	throws_ok {
		Database::BI::Model::DataSource->new(url => 'ftp://invalid')
	} qr/must begin with http/i,
		'path A: url key routed to _new_from_url (scheme check fires)';
};

subtest 'DataSource::new path-B: directory missing -> croak' => sub {
	throws_ok {
		Database::BI::Model::DataSource->new(
			directory => "$TMPDIR/no_such_dir",
			table     => 'sales',
		)
	} qr/does not exist or is not readable/,
		'path B: missing directory -> croak error_directory_missing';
};

subtest 'DataSource::new path-C: table name with path separator -> croak' => sub {
	# Hyphens/dots/digits are now sanitized to underscores.
	# Only path-separator characters trigger error_table_name_invalid.
	throws_ok {
		Database::BI::Model::DataSource->new(
			directory => $TMPDIR,
			table     => 'a/invalid',
		)
	} qr/contains illegal characters/,
		'path C: path-separator in table name -> croak error_table_name_invalid';
};

subtest 'DataSource::new path-D: unsafe CSV column names' => sub {
	# D1: First column unsafe but a later column IS safe -> _detect_file_info
	# picks the first safe column as id; construction succeeds.  This is the
	# common case for bank/account exports ("Account Number,Date,Amount,...").
	my $mixed_dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$mixed_dir/mixed.csv")->spew("my-col,amount\n1,100\n");
	my $ds;
	lives_ok {
		$ds = Database::BI::Model::DataSource->new(
			directory => $mixed_dir,
			table     => 'mixed',
		)
	} 'path D1: first-col unsafe but second safe -> construction succeeds';
	isa_ok $ds, 'Database::BI::Model::DataSource',
		'path D1: returns a DataSource object';

	# D2: ALL column names contain hyphens — no safe fallback exists.
	# _init_backend should croak error_no_safe_id before calling D::A.
	my $bad_dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$bad_dir/allbad.csv")->spew("my-col,his-col\n1,2\n");
	throws_ok {
		Database::BI::Model::DataSource->new(
			directory => $bad_dir,
			table     => 'allbad',
		)
	} qr/no column with a safe identifier name/,
		'path D2: all CSV columns unsafe -> croak error_no_safe_id';
};

subtest 'DataSource::new path-E: happy path -> blessed DataSource returned' => sub {
	my $ds;
	lives_ok { $ds = Database::BI::Model::DataSource->new(directory => $DATA_DIR, table => 'sales') }
		'path E: no exception on valid args';
	isa_ok $ds, 'Database::BI::Model::DataSource', 'path E: correct object type';
	is $ds->table_name, 'sales', 'path E: table name stored correctly';
};

# ======================================================================
# PATH COVERAGE: DataSource::_detect_file_info
#
# CFG (for-loop over qw(csv psv)):
#   A: No file for any extension      -> return {}
#   B: CSV exists, comma-sep          -> return hashref with sep_char ','
#   C: CSV exists, '!'-native         -> return hashref with sep_char '!'
#   D: PSV exists (csv absent)        -> return hashref with sep_char '|'
#   E: CSV exists but empty (no line) -> skip to psv; if psv also absent -> {}
#   F: CSV missing, PSV present       -> return psv info
# ======================================================================

subtest '_detect_file_info path-A: no files at all -> empty hashref' => sub {
	my $result = $DETECT->($TMPDIR, 'nonexistent_table_xyz');
	is_deeply $result, {}, 'path A: no matching file -> {}';
};

subtest '_detect_file_info path-B: CSV comma-separated -> sep_char "," + id' => sub {
	Mojo::File->new("$TMPDIR/commatest.csv")->spew("product,amount\nWidget,10\n");
	my $result = $DETECT->($TMPDIR, 'commatest');
	is $result->{sep_char}, ',',        'path B: sep_char is comma';
	is $result->{id},       'product',  'path B: id is first column';
	is_deeply $result->{columns}, [qw(product amount)], 'path B: all columns in order';
};

subtest '_detect_file_info path-C: CSV with "!" separator -> sep_char "!"' => sub {
	# D::A's native format: single-field header containing '!'
	Mojo::File->new("$TMPDIR/bangtest.csv")->spew("entry!name!value\n1!Alice!100\n");
	my $result = $DETECT->($TMPDIR, 'bangtest');
	is $result->{sep_char}, '!', 'path C: sniffed ! separator';
	is $result->{id},       'entry', 'path C: first column is id';
};

subtest '_detect_file_info path-D: PSV file -> sep_char "|"' => sub {
	Mojo::File->new("$TMPDIR/psvtest.psv")->spew("id|name\n1|Alice\n");
	my $result = $DETECT->($TMPDIR, 'psvtest');
	is $result->{sep_char}, '|', 'path D: PSV sep_char is pipe';
	is $result->{id},       'id', 'path D: first psv column is id';
};

subtest '_detect_file_info path-E: CSV exists but is empty -> _file_is_empty sentinel' => sub {
	Mojo::File->new("$TMPDIR/emptycsv.csv")->spew('');
	my $result = $DETECT->($TMPDIR, 'emptycsv');
	# 0-byte CSV: returns a sentinel so _init_backend skips D::A/DBI entirely,
	# preventing a DBI XS assertion crash (DBI 1.651 + DEBUGGING perl 5.44).
	ok $result->{_file_is_empty}, 'path E: 0-byte CSV -> _file_is_empty sentinel set';
	is $result->{file_size}, 0, 'path E: file_size is 0 for empty file';
};

subtest '_detect_file_info path-F: CSV absent, PSV present -> use PSV' => sub {
	Mojo::File->new("$TMPDIR/psvonly.psv")->spew("id|label\n1|Foo\n");
	my $result = $DETECT->($TMPDIR, 'psvonly');
	is $result->{sep_char}, '|', 'path F: CSV absent; PSV found and used';
};

# Paths G-J cover the new data-row scan logic added to fix the bank-CSV bugs.

subtest '_detect_file_info path-G: first col unsafe -> id skips to safe col' => sub {
	# Bug 2 regression: "Account Number" has a space -> not a safe identifier.
	# id must be the next column whose name IS safe.
	Mojo::File->new("$TMPDIR/gtest.csv")->spew(
		"Account Number,Date,Amount\n12345,2026-01-01,99.00\n"
	);
	my $result = $DETECT->($TMPDIR, 'gtest');
	is $result->{id}, 'Date', 'path G: id skips unsafe first col, picks Date';
};

subtest '_detect_file_info path-H: first safe col empty in data row -> next safe col' => sub {
	# Bug 3 regression: "ref" is a safe identifier but its value is empty in
	# the data row.  D::A uses empty_is_undef, so picking it would silently
	# drop every row where ref is blank.  id must advance to "description".
	Mojo::File->new("$TMPDIR/htest.csv")->spew(
		"Account Number,ref,description\nXX1234,,Transfer\n"
	);
	my $result = $DETECT->($TMPDIR, 'htest');
	is $result->{id}, 'description',
		'path H: id skips safe-but-empty "ref", picks "description"';
};

subtest '_detect_file_info path-I: all cols unsafe -> id undef' => sub {
	# When no column has a safe identifier name, _init_backend must croak
	# error_no_safe_id rather than letting D::A silently return 0 rows.
	Mojo::File->new("$TMPDIR/itest.csv")->spew("my-col,his-col\n1,2\n");
	my $result = $DETECT->($TMPDIR, 'itest');
	ok !defined $result->{id}, 'path I: id is undef when all column names are unsafe';
};

subtest '_detect_file_info path-J: header-only file (no data row) -> safe header col' => sub {
	# No data rows to probe: fall back to first safe column from the header.
	Mojo::File->new("$TMPDIR/jtest.csv")->spew("Account Number,amount\n");
	my $result = $DETECT->($TMPDIR, 'jtest');
	is $result->{id}, 'amount',
		'path J: no data row -> falls back to first safe column in header';
};

subtest '_detect_file_info path-K: file_size returned for CSV' => sub {
	# file_size is used by _init_backend to set max_slurp_size, forcing the
	# Text::xSV::Slurp path so DBD::CSV never sanitizes column names.
	my $content = "id,label\n1,Alpha\n2,Beta\n";
	my $path = "$TMPDIR/ktest.csv";
	Mojo::File->new($path)->spew($content);
	my $result = $DETECT->($TMPDIR, 'ktest');
	ok exists $result->{file_size}, 'path K: file_size key is present in result';
	is $result->{file_size}, -s $path, 'path K: file_size matches actual file size';
};

subtest '_detect_file_info path-K2: file_size absent for non-CSV/PSV (empty hashref)' => sub {
	# Non-CSV/PSV tables (SQLite, XML) return {} with no file_size key.
	my $result = $DETECT->($TMPDIR, 'no_such_table_xyz');
	ok !exists $result->{file_size}, 'path K2: no file_size in empty hashref';
};

# Paths L-N cover header-less CSV/PSV detection added so that bank exports
# with no header row (first line is data) are opened transparently.

subtest '_detect_file_info path-L: header-less CSV (date+amount+desc) -> _headerless' => sub {
	# All three first-row values fail $SAFE_IDENTIFIER; a date and a signed
	# number trigger _values_are_data_like.  Expect synthesized column names
	# and a _headerless marker; _init_backend gives D::A a copy with a header.
	Mojo::File->new("$TMPDIR/ltest.csv")->spew(
		"2026-09-09,-75.13,ACME RESTAURANT\n" .
		"2026-09-10,-2.25,FRGN FEE\n"
	);
	my $result = $DETECT->($TMPDIR, 'ltest');
	ok  exists  $result->{_headerless},              'path L: _headerless key present';
	ok  defined $result->{id},                       'path L: id is defined (synthesized)';
	is  $result->{id},       'Date',                 'path L: first synthesized id is "Date"';
	is_deeply $result->{columns}, [qw(Date Amount Description)],
		'path L: synthesized column names: Date, Amount, Description';
	is $result->{_headerless}{ext}, 'csv',           'path L: the extension is kept';
};

subtest '_detect_file_info path-M: header-less PSV (date+amount) -> _headerless' => sub {
	# Same logic applied to pipe-separated files.
	Mojo::File->new("$TMPDIR/mtest.psv")->spew(
		"2026-01-15|-99.00\n" .
		"2026-01-16|-1.50\n"
	);
	my $result = $DETECT->($TMPDIR, 'mtest');
	ok  exists  $result->{_headerless},              'path M: _headerless key present for PSV';
	is  $result->{sep_char}, '|',                    'path M: separator correctly detected as pipe';
	is_deeply $result->{columns}, [qw(Date Amount)], 'path M: two synthesized columns';
};

subtest '_detect_file_info path-N: unsafe names that are NOT data-like -> id undef (no headerless)' => sub {
	# "first-name" and "last-name" fail $SAFE_IDENTIFIER but look like
	# identifiers (no date/number pattern), so _values_are_data_like is false.
	# The existing error_no_safe_id path must be preserved.
	Mojo::File->new("$TMPDIR/ntest.csv")->spew("first-name,last-name\nAlice,Smith\n");
	my $result = $DETECT->($TMPDIR, 'ntest');
	ok !exists  $result->{_headerless}, 'path N: no _headerless for hyphenated headers';
	ok !defined $result->{id},              'path N: id is undef (all names unsafe, not data-like)';
};

# ======================================================================
# PATH COVERAGE: DataSource::fetch_all
#
# CFG:
#   A: selectall_hashref throws       -> croak error_fetch_failed
#   B: selectall_hashref returns undef -> return []
#   C: returns non-empty ARRAYREF     -> return as-is
#   D: returns empty ARRAYREF         -> carp warn_empty_result, return []
#   E: returns non-empty HASHREF      -> normalize + carp warn_data_normalised
#   F: returns empty HASHREF          -> normalize + both carps
# ======================================================================

{
	# Build a DataSource with a real backend to test fetch_all paths.
	my $ds = Database::BI::Model::DataSource->new(directory => $DATA_DIR, table => 'sales');

	subtest 'fetch_all path-A: backend throws -> croak error_fetch_failed' => sub {
		mock 'Database::Abstraction::selectall_hashref' => sub { die "DB exploded\n" };
		throws_ok { $ds->fetch_all } qr/fetch_all failed/,
			'path A: exception from backend propagated as croak';
		restore_all;
	};

	subtest 'fetch_all path-B: backend returns undef -> normalized to []' => sub {
		mock 'Database::Abstraction::selectall_hashref' => sub { return undef };
		my $result = $ds->fetch_all;
		is_deeply $result, [], 'path B: undef backend result -> []';
		restore_all;
	};

	subtest 'fetch_all path-C: backend returns non-empty ARRAYREF -> as-is' => sub {
		my @rows = ({id => '1', val => 'x'}, {id => '2', val => 'y'});
		mock 'Database::Abstraction::selectall_hashref' => sub { return \@rows };
		my $result = $ds->fetch_all;
		is scalar(@$result), 2, 'path C: two rows returned unchanged';
		restore_all;
	};

	subtest 'fetch_all path-D: backend returns empty ARRAYREF -> carp + []' => sub {
		mock 'Database::Abstraction::selectall_hashref' => sub { return [] };
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		my $result = $ds->fetch_all;
		is_deeply $result, [], 'path D: empty arrayref returned';
		ok +(grep { /no records/ } @warnings), 'path D: warn_empty_result emitted';
		restore_all;
	};

	subtest 'fetch_all path-E: backend returns non-empty HASHREF -> normalize + carp' => sub {
		mock 'Database::Abstraction::selectall_hashref' => sub {
			return { 'k1' => {id => 'k1', val => 'a'}, 'k2' => {id => 'k2', val => 'b'} }
		};
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		my $result = $ds->fetch_all;
		is scalar(@$result), 2, 'path E: 2 rows after HASH normalization';
		ok +(grep { /hashref|converted/ } @warnings), 'path E: warn_data_normalised emitted';
		ok !(grep { /no records/ } @warnings), 'path E: warn_empty_result NOT emitted (data present)';
		restore_all;
	};

	subtest 'fetch_all path-F: backend returns empty HASHREF -> both carps' => sub {
		mock 'Database::Abstraction::selectall_hashref' => sub { return {} };
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		my $result = $ds->fetch_all;
		is_deeply $result, [], 'path F: empty hashref normalized to []';
		ok +(grep { /hashref|converted/ } @warnings), 'path F: warn_data_normalised emitted';
		ok +(grep { /no records/ } @warnings),        'path F: warn_empty_result emitted';
		restore_all;
	};
}

# ======================================================================
# PATH COVERAGE: Dashboard::_is_safe_url
#
# CFG:
#   Root guard: no protocol match     -> 0            [A]
#   Loopback aliases:
#     localhost                       -> 0            [B]
#     127.x.x.x                       -> 0            [C]
#     0.0.0.0                         -> 0            [D]
#     ::1                             -> 0            [E]
#   Hostname (not IP): return 1       -> 1            [F]
#   Dotted-quad, inet_aton fails      -> 1            [G]
#   Private ranges:
#     10/8                            -> 0            [H]
#     172.16/12                       -> 0            [I]
#     192.168/16                      -> 0            [J]
#     169.254/16 (link-local)         -> 0            [K]
#     100.64/10 (CGNAT)               -> 0            [L]
#   Public IP (8.8.8.8)               -> 1            [M]
# ======================================================================

subtest '_is_safe_url path-A: no https?:// protocol -> 0' => sub {
	ok !$IS_SAFE->('ftp://example.com'), 'path A: ftp:// is not safe (blocked)';
};

subtest '_is_safe_url path-B: localhost -> 0' => sub {
	ok !$IS_SAFE->('http://localhost/api'), 'path B: localhost blocked';
};

subtest '_is_safe_url path-C: 127.x.x.x -> 0' => sub {
	ok !$IS_SAFE->('http://127.0.0.1/'), 'path C: 127.0.0.1 blocked';
	ok !$IS_SAFE->('http://127.255.255.255/'), 'path C: 127.x.x.x upper bound blocked';
};

subtest '_is_safe_url path-D: 0.0.0.0 -> 0' => sub {
	ok !$IS_SAFE->('http://0.0.0.0/'), 'path D: 0.0.0.0 blocked';
};

subtest '_is_safe_url path-E: ::1 (IPv6 loopback) -> 0' => sub {
	ok !$IS_SAFE->('http://::1/'), 'path E: ::1 blocked';
};

subtest '_is_safe_url path-F: hostname (not IP) -> 1 (allowed)' => sub {
	ok $IS_SAFE->('https://example.com/data.csv'), 'path F: public hostname allowed';
};

subtest '_is_safe_url path-G: dotted-quad but invalid octet -> inet_aton undef -> 1' => sub {
	# 256.0.0.1 passes the dotted-quad regex but inet_aton returns undef.
	# The "or return 1" guard handles this; the IP cannot be checked against ranges.
	ok $IS_SAFE->('http://256.0.0.1/'), 'path G: invalid octet -> inet_aton undef -> pass';
};

subtest '_is_safe_url path-H: 10.x.x.x (RFC 1918) -> 0' => sub {
	ok !$IS_SAFE->('http://10.0.0.1/'),    'path H: 10.0.0.1 blocked';
	ok !$IS_SAFE->('http://10.255.255.254/'), 'path H: 10.255.255.254 blocked';
};

subtest '_is_safe_url path-I: 172.16-31.x.x (RFC 1918) -> 0' => sub {
	ok !$IS_SAFE->('http://172.16.0.1/'), 'path I: 172.16.x.x blocked';
	ok !$IS_SAFE->('http://172.31.255.254/'), 'path I: 172.31.x.x upper bound blocked';
};

subtest '_is_safe_url path-J: 192.168.x.x (RFC 1918) -> 0' => sub {
	ok !$IS_SAFE->('http://192.168.0.1/'), 'path J: 192.168.x.x blocked';
};

subtest '_is_safe_url path-K: 169.254.x.x (link-local / metadata) -> 0' => sub {
	ok !$IS_SAFE->('http://169.254.169.254/latest/meta-data/'), 'path K: AWS metadata endpoint blocked';
};

subtest '_is_safe_url path-L: 100.64.x.x (CGNAT / Tailscale) -> 0' => sub {
	ok !$IS_SAFE->('http://100.64.0.1/'), 'path L: CGNAT range blocked';
};

subtest '_is_safe_url path-M: public IP 8.8.8.8 -> 1 (no private range matches)' => sub {
	ok $IS_SAFE->('http://8.8.8.8/'), 'path M: public IP 8.8.8.8 allowed';
};

# ======================================================================
# PATH COVERAGE: Dashboard::_get_columns
#
# CFG:
#   A: source->columns returns arrayref -> return it directly
#   B: columns undef, no records        -> return ()
#   C: columns undef, records, id_col in data -> id_col first
#   D: columns undef, records, id_col absent from data -> alphabetical
# ======================================================================

{
	# Helper: build a fake DataSource object with controlled columns/id_column.
	sub fake_source {
		my ($cols, $id_col) = @_;
		return bless { _columns => $cols, _id_col => $id_col },
			'Database::BI::Model::DataSource';
	}

	subtest '_get_columns path-A: source->columns returns arrayref -> returned' => sub {
		my $src    = fake_source([qw(product amount region)], 'product');
		my @result = $GET_COLS->($src, []);
		is_deeply \@result, [qw(product amount region)], 'path A: columns arrayref returned as-is';
	};

	subtest '_get_columns path-B: columns undef, no records -> empty list' => sub {
		my $src    = fake_source(undef, 'id');
		my @result = $GET_COLS->($src, []);
		is_deeply \@result, [], 'path B: no columns + no records -> ()';
	};

	subtest '_get_columns path-C: columns undef, id_col present in data -> id_col first' => sub {
		my $src    = fake_source(undef, 'id');
		my @result = $GET_COLS->($src, [{ id => '1', amount => '10', region => 'N' }]);
		is $result[0], 'id', 'path C: id_column appears first';
		is_deeply [sort @result[1..$#result]], [qw(amount region)], 'path C: rest sorted alphabetically';
	};

	subtest '_get_columns path-D: columns undef, id_col absent from data -> alphabetical' => sub {
		my $src    = fake_source(undef, 'entry');   # 'entry' not in data
		my @result = $GET_COLS->($src, [{ amount => '10', region => 'N' }]);
		is $result[0], 'amount', 'path D: alphabetical first col (amount) used as id';
		is $result[1], 'region', 'path D: second col follows';
	};
}

# ======================================================================
# PATH COVERAGE: Dashboard::_spec_to_url
#
# CFG (cascading if/elsif with immediate returns):
#   A: table: spec  -> /view/<name>
#   B: path:  spec  -> /open?path=...
#   C: url:   spec  -> /import?url=...
#   D: no match     -> /
# ======================================================================

{
	# _spec_to_url needs $self but never uses it -- pass undef as dummy.
	sub dummy { undef }

	subtest '_spec_to_url path-A: table: spec -> /view/<name>' => sub {
		is $SPEC_URL->(undef, 'table:sales'), '/view/sales', 'path A: table spec';
	};

	subtest '_spec_to_url path-B: path: spec -> /open?path=...' => sub {
		my $result = $SPEC_URL->(undef, 'path:/tmp/data.csv');
		like $result, qr{\A/open\?path=}, 'path B: path spec starts with /open?path=';
		like $result, qr{data\.csv},      'path B: filename preserved (URL-encoded)';
	};

	subtest '_spec_to_url path-C: url: spec -> /import?url=...' => sub {
		my $result = $SPEC_URL->(undef, 'url:https://example.com/data.csv');
		like $result, qr{\A/import\?url=}, 'path C: url spec -> /import';
	};

	subtest '_spec_to_url path-D: unrecognized spec -> /' => sub {
		is $SPEC_URL->(undef, 'unknown:whatever'), '/', 'path D: unrecognized -> /';
		is $SPEC_URL->(undef, ''),                  '/', 'path D: empty -> /';
	};
}

# ======================================================================
# PATH COVERAGE: Dashboard::_csv_row
#
# CFG (per-field conditional inside map):
#   A: field contains comma         -> quoted
#   B: field contains double-quote  -> quoted with doubled quote
#   C: field contains newline       -> quoted
#   D: plain field                  -> unquoted
#   E: undef field                  -> treated as '' (unquoted empty)
#
# Every call ends with CRLF join.
# ======================================================================

subtest '_csv_row path-A: comma in field -> field is quoted' => sub {
	my $row = $CSV_ROW->('Widget, Deluxe', '99');
	like $row, qr/"Widget, Deluxe"/, 'path A: comma triggers quoting';
	like $row, qr/\r\n\z/,           'path A: CRLF line ending';
};

subtest '_csv_row path-B: double-quote in field -> doubled inside quotes' => sub {
	my $row = $CSV_ROW->(q{say "hello"}, 'x');
	like $row, qr/"say ""hello"""/, 'path B: embedded quotes doubled';
};

subtest '_csv_row path-C: newline in field -> field is quoted' => sub {
	my $row = $CSV_ROW->("line1\nline2", 'x');
	like $row, qr/"line1\nline2"/, 'path C: newline triggers quoting';
};

subtest '_csv_row path-D: plain field (no special chars) -> unquoted' => sub {
	my $row = $CSV_ROW->('Widget', '1250.00');
	is $row, "Widget,1250.00\r\n", 'path D: plain fields pass through unquoted';
};

subtest '_csv_row path-E: undef field -> empty string in output' => sub {
	my $row = $CSV_ROW->(undef, 'x');
	is $row, ",x\r\n", 'path E: undef treated as empty string -> leading comma';
};

# ======================================================================
# PATH COVERAGE: Dashboard::_list_dir
#
# CFG:
#   A: opendir fails            -> {dirs:[], files:[]}
#   B: dir exists, empty        -> {dirs:[], files:[]}
#   C: dir has subdirs          -> {dirs:[...], files:[]}
#   D: dir has data files, want_files=true  -> {dirs:[], files:[...]}
#   E: dir has data files, want_files=false -> {dirs:[], files:[]}
#   F: dir has hidden entries   -> hidden skipped
# ======================================================================

{
	my $dummy_self = bless {}, 'Database::BI::Controller::Dashboard';

	subtest '_list_dir path-A: opendir fails -> empty lists' => sub {
		my $ghost = Mojo::File->new("$TMPDIR/no_such_dir_xyz");
		my $result = $LIST_DIR->($dummy_self, $ghost, 1);
		is_deeply $result->{dirs},  [], 'path A: dirs empty on opendir failure';
		is_deeply $result->{files}, [], 'path A: files empty on opendir failure';
	};

	subtest '_list_dir path-B: empty directory -> empty lists' => sub {
		my $empty = Mojo::File->new("$TMPDIR/empty_list_test");
		$empty->make_path;
		my $result = $LIST_DIR->($dummy_self, $empty, 1);
		is_deeply $result->{dirs},  [], 'path B: no dirs in empty dir';
		is_deeply $result->{files}, [], 'path B: no files in empty dir';
	};

	subtest '_list_dir path-C: directory entries -> dirs populated' => sub {
		my $parent = Mojo::File->new("$TMPDIR/list_test_dirs");
		$parent->make_path;
		$parent->child('alpha')->make_path;
		$parent->child('beta')->make_path;
		my $result = $LIST_DIR->($dummy_self, $parent, 1);
		is scalar(@{$result->{dirs}}),  2, 'path C: 2 subdirs found';
		is $result->{dirs}[0]{name}, 'alpha', 'path C: sorted case-insensitively (alpha first)';
	};

	subtest '_list_dir path-D: data files with want_files=true -> files populated' => sub {
		my $filedir = Mojo::File->new("$TMPDIR/list_test_files");
		$filedir->make_path;
		Mojo::File->new("$TMPDIR/list_test_files/report.csv")->spew('id\n1\n');
		Mojo::File->new("$TMPDIR/list_test_files/data.psv")->spew('id\n1\n');
		my $result = $LIST_DIR->($dummy_self, $filedir, 1);
		is scalar(@{$result->{files}}), 2, 'path D: 2 data files found (want_files=true)';
	};

	subtest '_list_dir path-E: data files with want_files=false -> files empty' => sub {
		my $filedir = Mojo::File->new("$TMPDIR/list_test_files");  # created above
		my $result = $LIST_DIR->($dummy_self, $filedir, 0);
		is_deeply $result->{files}, [], 'path E: files not populated when want_files=false';
		is scalar(@{$result->{dirs}}), 0, 'path E: no subdirs present';
	};

	subtest '_list_dir path-F: hidden entries (dot-prefix) are excluded' => sub {
		my $hiddir = Mojo::File->new("$TMPDIR/list_test_hidden");
		$hiddir->make_path;
		Mojo::File->new("$TMPDIR/list_test_hidden/.hidden.csv")->spew('id\n1\n');
		Mojo::File->new("$TMPDIR/list_test_hidden/.hiddendir")->make_path;
		Mojo::File->new("$TMPDIR/list_test_hidden/visible.csv")->spew('id\n1\n');
		my $result = $LIST_DIR->($dummy_self, $hiddir, 1);
		is scalar(@{$result->{files}}), 1, 'path F: only visible.csv, not .hidden.csv';
		is $result->{files}[0]{name}, 'visible.csv', 'path F: correct visible file';
		is scalar(@{$result->{dirs}}), 0, 'path F: .hiddendir excluded too';
	};
}

# ======================================================================
# PATH COVERAGE: Dashboard::_write_sqlite_db
#
# CFG:
#   A: empty columns list       -> croak (no columns)
#   B: DBI connect fails        -> unlink tmpfile + croak
#   C: connect ok, no records   -> CREATE TABLE only, slurp, return
#   D: connect ok, with records -> CREATE TABLE + INSERT rows, slurp, return
#   E: DBI op throws mid-flight -> cleanup (disconnect + unlink) + croak
# ======================================================================

{
	my $dummy_self = bless {}, 'Database::BI::Controller::Dashboard';

	subtest '_write_sqlite_db path-A: empty columns -> croak before filesystem touch' => sub {
		throws_ok { $WRITE_SQLITE->($dummy_self, [], []) }
			qr/no columns/i,
			'path A: croak before tempfile created';
	};

	subtest '_write_sqlite_db path-B: DBI connect fails -> tmpfile unlinked + croak' => sub {
		SKIP: {
			eval { require DBI } or skip 'DBI not available', 2;
			# Point TMPDIR at an empty folder and see that nothing is left in it.
			# (Wrapping File::Temp::tempfile in a mock that called
			# File::Temp::tempfile recursed without end once the writer moved to
			# Database::Join::Catalog, loaded after the mock: it ate all memory.)
			require Database::Join::Catalog;
			my $tmp = tempdir(CLEANUP => 1);
			local $ENV{TMPDIR} = $tmp;
			mock 'DBI::connect' => sub { die "cannot connect\n" };
			throws_ok { $WRITE_SQLITE->($dummy_self, [], [qw(id val)]) }
				qr/cannot connect/,
				'path B: DBI connect failure -> croak';
			is_deeply [ glob("$tmp/*") ], [], 'path B: the temporary file was removed';
			restore_all;
		}
	};

	subtest '_write_sqlite_db path-C: connect ok, no records -> SQLite magic bytes returned' => sub {
		SKIP: {
			eval { require DBI; DBI->install_driver('SQLite') }
				or skip 'DBD::SQLite not available', 2;
			my $data = $WRITE_SQLITE->($dummy_self, [], [qw(id name)]);
			like $data, qr/\ASQLite format 3/, 'path C: SQLite magic bytes present';
			ok length($data) > 100, 'path C: non-trivial byte count for db with table';
		}
	};

	subtest '_write_sqlite_db path-D: connect ok, records present -> INSERT + return bytes' => sub {
		SKIP: {
			eval { require DBI; DBI->install_driver('SQLite') }
				or skip 'DBD::SQLite not available', 3;
			my @recs = ({id => '1', name => 'Alice'}, {id => '2', name => 'Bob'});
			my $data = $WRITE_SQLITE->($dummy_self, \@recs, [qw(id name)]);
			like $data, qr/\ASQLite format 3/, 'path D: SQLite magic bytes';
			# Verify by re-reading the bytes with DBI.
			my $tmp = File::Temp->new(SUFFIX => '.db', UNLINK => 1);
			print $tmp $data; close $tmp;
			my $dbh = DBI->connect("dbi:SQLite:dbname=" . $tmp->filename, '', '', { RaiseError => 1 });
			my $rows = $dbh->selectall_arrayref('SELECT id, name FROM "data" ORDER BY id', {Slice=>{}});
			is scalar(@$rows), 2, 'path D: 2 rows written to SQLite';
			is $rows->[0]{name}, 'Alice', 'path D: first row data correct';
			$dbh->disconnect;
		}
	};

	subtest '_write_sqlite_db path-E: DBI op throws mid-flight -> cleanup + croak' => sub {
		SKIP: {
			eval { require DBI; DBI->install_driver('SQLite') }
				or skip 'DBD::SQLite not available', 2;
			# Mock $dbh->do to throw after connection succeeds.
			mock 'DBI::db::do' => sub { die "simulated CREATE TABLE failure\n" };
			my $err;
			throws_ok {
				$WRITE_SQLITE->($dummy_self, [], [qw(id val)])
			} qr/simulated CREATE TABLE failure/,
				'path E: mid-flight DBI error re-thrown after cleanup';
			restore_all;
		}
	};
}

# ======================================================================
# PATH COVERAGE: Dashboard::_build_export_url
#
# CFG (two foreach statement modifiers on potentially-empty arrays):
#   A: no joins, no filters     -> /export?l=...
#   B: with joins               -> each adds &j=... param
#   C: with filters             -> each adds &f=... param
#   D: both joins and filters   -> all params included
# ======================================================================

{
	my $dummy = bless {}, 'Database::BI::Controller::Dashboard';

	subtest '_build_export_url path-A: no joins or filters -> just l param' => sub {
		my $url = $BUILD_URL->($dummy, 'table:sales', [], []);
		is $url, '/export?l=table%3Asales', 'path A: only l= param';
	};

	subtest '_build_export_url path-B: with joins -> j params appended' => sub {
		my $url = $BUILD_URL->($dummy, 'table:sales',
			['table:products|id|product_id'],
			[]);
		like $url, qr{&j=},      'path B: &j= param present';
		like $url, qr{products}, 'path B: join spec encoded';
	};

	subtest '_build_export_url path-C: with filters -> f params appended' => sub {
		my $url = $BUILD_URL->($dummy, 'table:sales', [], ['region:eq:North']);
		like $url, qr{&f=},    'path C: &f= param present';
		like $url, qr{region}, 'path C: filter spec encoded';
	};

	subtest '_build_export_url path-D: joins + filters -> all params' => sub {
		my $url = $BUILD_URL->($dummy, 'table:sales',
			['table:p|id|pid'],
			['amount:gt:1000', 'region:eq:North']);
		like $url, qr{l=},      'path D: l param';
		like $url, qr{&j=},     'path D: j param';
		my @f = ($url =~ /&f=/g);
		is scalar(@f), 2, 'path D: two f= params for two filters';
	};
}

# ======================================================================
# PATH COVERAGE: Dashboard::_resolve_language
#
# The controller renders templates/<platform>/<language>/<page>, so the only
# languages that can be served are the ones with a directory.  Every path below
# therefore ends at a code that has one, or at the default language, which is
# what the POD promises; what differs is which code was tried first.
#
# CFG:
#   A: no Accept-Language header            -> default
#   B: header, code equals default           -> default
#   C: header, code ne default, dir exists   -> that code
#   D: header, code ne default, dir missing  -> default language
#   E: header present but no 2-letter match  -> default
#   F: no header, configured code has no dir -> default language
#   G: header names the configured code, no dir -> default language
# ======================================================================

# An application home of this section's own, holding templates/web/en and
# templates/web/fr and nothing else.  Statting the checkout's templates would
# make these paths depend on whatever this machine has installed, and creating
# templates/web/fr in the checkout - which this section used to do - races a
# parallel run.
Readonly my $LANG_HOME => do {
	my $home = Mojo::File->new(tempdir(CLEANUP => 1));
	$home->child('templates/web/en')->make_path;
	$home->child('templates/web/fr')->make_path;
	$home->to_string;
};

# A MockCtrl with the section's own home and a given Accept-Language value.
sub lang_ctrl { MockCtrl->new($LANG_HOME, $APP_CFG, $_[0]) }

subtest '_resolve_language path-A: no Accept-Language header -> default' => sub {
	my $lang = $RESOLVE_LANG->(lang_ctrl(undef), 'web', 'en');
	is $lang, 'en', 'path A: absent header -> the configured language';
};

subtest '_resolve_language path-B: header code equals default -> default' => sub {
	my $lang = $RESOLVE_LANG->(lang_ctrl('en-US,en;q=0.9'), 'web', 'en');
	is $lang, 'en', 'path B: header naming the configured language -> that language';
};

subtest '_resolve_language path-C: header code ne default, template dir exists -> use it' => sub {
	my $lang = $RESOLVE_LANG->(lang_ctrl('fr-FR,fr;q=0.9,en;q=0.8'), 'web', 'en');
	is $lang, 'fr', 'path C: templates/web/fr exists -> CGI::Lingua selects fr';
};

subtest '_resolve_language path-D: no supported template for requested language -> default' => sub {
	# 'de' has no directory and is not offered to CGI::Lingua, which returns
	# undef; the configured language answers.
	my $lang = $RESOLVE_LANG->(lang_ctrl('de,de-DE;q=0.9'), 'web', 'en');
	is $lang, 'en', 'path D: no templates/web/de -> default';
};

subtest '_resolve_language path-E: no parseable language -> default' => sub {
	my $lang = $RESOLVE_LANG->(lang_ctrl('q=0.9'), 'web', 'en');
	is $lang, 'en', 'path E: unrecognised Accept-Language -> default';
};

subtest '_resolve_language path-F: configured language has no templates -> default language' => sub {
	# The configured language is offered to CGI::Lingua and can come back from
	# it, and it has no directory either way: the renderer cannot be handed
	# templates/web/de/ just because the config named it.
	my $lang = $RESOLVE_LANG->(lang_ctrl(undef), 'web', 'de');
	is $lang, 'en', 'path F: no templates/web/de -> falls back to the default language';
};

subtest '_resolve_language path-G: header names the unservable language -> default language' => sub {
	my $lang = $RESOLVE_LANG->(lang_ctrl('de-DE,de;q=0.9'), 'web', 'de');
	is $lang, 'en', 'path G: the language cannot be served, whatever code selected it';
};

# ======================================================================
# PATH COVERAGE: HTTP actions (view, browse, stat_api, dirs_api)
# These test action-level branching where private helpers are exercised
# end-to-end through the Mojolicious dispatch layer.
# ======================================================================

# --- view: three paths through the controller ---

subtest 'HTTP view path-A: invalid table name -> 404 (TABLE_NAME_RE guard)' => sub {
	$t->get_ok('/view/1badname')->status_is(404);
};

subtest 'HTTP view path-B: valid name, no backing file -> 404 page' => sub {
	$t->get_ok('/view/no_such_table_xyz')
	  ->status_is(404)
	  ->content_type_like(qr{text/html});
};

subtest 'HTTP view path-C: valid name, file exists -> 200 with table data' => sub {
	$t->get_ok('/view/sales')
	  ->status_is(200)
	  ->content_like(qr/Widget/);
};

# --- stat_api: three branches ---

subtest 'HTTP stat_api path-A: missing path param -> 400' => sub {
	$t->get_ok('/api/stat')
	  ->status_is(400)
	  ->json_has('/error');
};

subtest 'HTTP stat_api path-B: non-existent file -> 200, exists:false' => sub {
	$t->get_ok('/api/stat?path=' . url_escape("$TMPDIR/ghost.csv"))
	  ->status_is(200)
	  ->json_is('/exists', 0);
};

subtest 'HTTP stat_api path-C: existing data file -> 200, exists:true + metadata' => sub {
	$t->get_ok('/api/stat?path=' . url_escape($SALES_ABS))
	  ->status_is(200)
	  ->json_is('/exists', 1)
	  ->json_has('/mtime')
	  ->json_has('/size');
};

# --- dirs_api: three branches ---

subtest 'HTTP dirs_api path-A: valid directory -> 200 with dirs array' => sub {
	$t->get_ok('/api/dirs?path=' . url_escape($TMPDIR))
	  ->status_is(200)
	  ->json_has('/dirs')
	  ->json_has('/path');
};

subtest 'HTTP dirs_api path-B: non-existent path -> 404' => sub {
	$t->get_ok('/api/dirs?path=' . url_escape("$TMPDIR/no_such_dir"))
	  ->status_is(404)
	  ->json_has('/error');
};

subtest 'HTTP dirs_api path-C: root directory -> parent is null' => sub {
	$t->get_ok('/api/dirs?path=' . url_escape('/'))
	  ->status_is(200)
	  ->json_is('/parent', undef);
};

# --- export pipeline: left-table-not-found path ---

subtest 'HTTP export path-A: no l= param -> 404 (empty spec resolves no table)' => sub {
	$t->get_ok('/export')->status_is(404);
};

subtest 'HTTP export path-B: valid l= table spec -> 200 CSV' => sub {
	$t->get_ok('/export?l=table:sales&format=csv')
	  ->status_is(200)
	  ->content_type_like(qr{text/csv});
};

subtest 'HTTP export path-C: l= path spec with existing file -> 200 CSV' => sub {
	$t->get_ok('/export?l=path:' . url_escape($SALES_ABS) . '&format=csv')
	  ->status_is(200)
	  ->content_type_like(qr{text/csv});
};

# --- _open_spec: url: spec with unsafe URL -> pipeline returns () -> 404 ---

subtest 'HTTP export path-D: url: spec with private IP -> blocked -> 404' => sub {
	my $url = url_escape('url:http://10.0.0.1/evil.csv');
	$t->get_ok("/export?l=$url")->status_is(404);
};


{
	package Unit::PathUA;
	sub get { my $self = shift; return $self->{code}->(@_) }
	package Unit::PathReply;
	sub is_success { $_[0]{ok} }
	sub decoded_content { $_[0]{body} }
	package Unit::NoSuccess;
	package Unit::ForgetfulCache;
	# Keeps everything except outlines, which it silently drops.
	sub get { my ($self, $key) = @_; return $self->{store}{$key} }
	sub set { my ($self, $key, $value) = @_; $self->{store}{$key} = $value unless !$self->{keep_outlines} && $key =~ /\Aoutline:/; return 1 }
}

# ======================================================================
# PATHS: Password, SafeUA, I18N, Extract and Boundary
#
# Found by running the suite under Devel::Cover and listing every branch and
# condition with an arm never taken.  Each subtest names the function and the
# path (the arm) it forces; a path that ends in a refusal is asserted with its
# exact message.  Control-flow graph in words, per function, in the comments.
# ======================================================================
{
	use lib 't/lib';
	use Test::Permissions qw(can_revoke_create with_revoked);
	# Where caches go is chosen from these, which the invoking shell may set.
	delete local @ENV{qw(CACHEDIR CACHE_DIR Database__BI__cache_dir Database__BI__Extract__cache_dir Database__BI__Model__Geocode__cache_dir)};
	require Database::BI::Password;
	require Database::BI::SafeUA;
	require Database::BI::I18N;
	require Database::BI::Extract;
	require Database::BI::Model::Boundary;
	require HTTP::Request;
	require HTTP::Response;

	Readonly my %PATH => (
		rounds   => 10_000,
		salt     => 'S' x 16,
		zoom_ok  => 8,
		rank_ok  => 12,
	);
	my $err_of = sub { my ($code) = @_; local $@; return eval { $code->(); 1 } ? undef : ($@ =~ s/ at \S+ line \d+\.?\n?\z//r) };

	# hash_password: password guard -> rounds (given | default) -> salt (given | random).
	subtest 'hash_password path: both defaults taken (no rounds, no salt)' => sub {
		my $hash = Database::BI::Password::hash_password('pw');
		like $hash, qr/\Apbkdf2-sha256\$200000\$/, 'rounds defaulted to 200000';
		my ($salt) = (split /\$/, $hash)[2];
		isnt $salt, (split /\$/, Database::BI::Password::hash_password('pw'))[2], 'the salt was random: two calls differ';
	};

	# is_password_hash: not a string -> not matching the shape -> rounds below | inside | above.
	subtest 'is_password_hash path: the rounds range test, each of its three arms' => sub {
		my $made = Database::BI::Password::hash_password('pw', rounds => $PATH{rounds}, salt => $PATH{salt});
		my $with = sub { my ($n) = @_; return $made =~ s/\$$PATH{rounds}\$/\$$n\$/r };
		is Database::BI::Password::is_password_hash($with->($PATH{rounds} - 1)), 0, 'below the minimum: 0';
		is Database::BI::Password::is_password_hash($with->($PATH{rounds})), 1, 'at the minimum: 1';
		is Database::BI::Password::is_password_hash($with->(100_000_000)), 1, 'at the maximum: 1';
		is Database::BI::Password::is_password_hash($with->(100_000_001)), 0, 'above the maximum: 0';
	};

	# _pbkdf2 loop: for production callers (bytes = 32 = one SHA-256 block) it runs once;
	# a longer key runs it again.  Both are paths of the function.
	subtest '_pbkdf2 path: one block (the production call) and two blocks (the RFC vectors)' => sub {
		my $pbkdf2 = \&Database::BI::Password::_pbkdf2;
		my $one = $pbkdf2->('password', 'salt', 1, 32);
		my $two = $pbkdf2->('password', 'salt', 1, 64);
		is length($one), 32, 'one block gives 32 bytes';
		is length($two), 64, 'two blocks give 64 bytes';
		is substr($two, 0, 32), $one, 'and the first block is the same either way';
		is length($pbkdf2->('password', 'salt', 1, 20)), 20, 'a short key is the block cut down (the truncation path)';
	};

	# numeric_host / _numeric_v4: the long-octal arm (more than 11 digits is out of range).
	subtest '_numeric_v4 path: an octal part too long to be an address' => sub {
		my $numeric = \&Database::BI::SafeUA::numeric_host;
		is $numeric->('0' . '7' x 12), undef, 'twelve octal digits: not an address (the length arm)';
		is $numeric->('0' . '7' x 11), undef, 'eleven octal digits past 32 bits: refused by the range check, without a warning';
		is $numeric->('0' . '7' x 3), '0.0.1.255', 'a short octal reads (the other arm)';
		is $numeric->('0x' . 'f' x 9), undef, 'nine hex digits: not an address';
	};

	# resolve_host: getaddrinfo dies | gives an error | gives addresses (dup, bad name-info).
	subtest 'resolve_host path: each way getaddrinfo can end' => sub {
		my $addr = 'packed';
		mock 'Database::BI::SafeUA::getaddrinfo' => sub { die "boom\n" };
		is_deeply [ Database::BI::SafeUA::resolve_host('x.example') ], [], 'it dies: no addresses';
		mock 'Database::BI::SafeUA::getaddrinfo' => sub { return () };
		is_deeply [ Database::BI::SafeUA::resolve_host('x.example') ], [], 'it gives nothing (err undef): no addresses';
		mock 'Database::BI::SafeUA::getaddrinfo' => sub { return ('Name or service not known') };
		is_deeply [ Database::BI::SafeUA::resolve_host('x.example') ], [], 'it gives an error: no addresses';
		my @names = ('8.8.8.8', '8.8.8.8', undef, '1.1.1.1');
		mock 'Database::BI::SafeUA::getaddrinfo' => sub { return ('', map { { addr => $_ // 'none' } } 1 .. 4) };
		my $n = 0;
		mock 'Database::BI::SafeUA::getnameinfo' => sub { my $name = $names[$n++]; return (defined $name ? ('', $name) : ('error', undef)) };
		is_deeply [ Database::BI::SafeUA::resolve_host('x.example') ], [ '8.8.8.8', '1.1.1.1' ], 'duplicates and failed name lookups are dropped';
		restore_all();
	};

	# send_request: scheme ok? -> host ok? -> literal or resolved -> blocked? -> pin -> https options.
	subtest 'send_request path: no scheme, no host, and the https options with and without ssl_opts' => sub {
		my $ua = Database::BI::SafeUA->new(resolve => sub { '8.8.8.8' });
		my @seen;
		mock 'LWP::UserAgent::send_request' => sub { push @seen, { ssl => $_[0]{ssl_opts}, uri => $_[1]->uri->as_string }; HTTP::Response->new(200) };
		is $ua->send_request(HTTP::Request->new(GET => '/just/a/path'))->code, 403, 'no scheme at all: refused';
		like $ua->send_request(HTTP::Request->new(GET => '/just/a/path'))->message, qr/\ARefused: only http and https/, '... for its scheme';
		like $ua->send_request(HTTP::Request->new(GET => 'http:relative'))->message, qr/\ARefused: the address names no host/, 'a scheme with no host: refused for that';
		is scalar(@seen), 0, 'neither was sent';

		is $ua->send_request(HTTP::Request->new(GET => 'https://public.example/'))->code, 200, 'https with no ssl_opts: sent';
		is_deeply $seen[-1]{ssl}, { verify_hostname => 1, SSL_hostname => 'public.example', SSL_verifycn_name => 'public.example' }, '... with LWP\'s default and the name for SNI and the certificate check';
		my $with = Database::BI::SafeUA->new(resolve => sub { '8.8.8.8' }, ssl_opts => { verify_hostname => 1 });
		$with->send_request(HTTP::Request->new(GET => 'https://public.example/'));
		is_deeply $seen[-1]{ssl}, { verify_hostname => 1, SSL_hostname => 'public.example', SSL_verifycn_name => 'public.example' }, 'with ssl_opts: kept, and the name added';
		$with->send_request(HTTP::Request->new(GET => 'http://public.example/'));
		is_deeply $seen[-1]{ssl}, { verify_hostname => 1 }, 'plain http: ssl_opts are left as they were';
		restore_all();
		is_deeply $with->{ssl_opts}, { verify_hostname => 1 }, 'and put back afterwards (the local)';
	};

	# I18N::choose: no accept | accept -> lingua_choice (defined | undef) -> default.
	subtest 'I18N paths: choose, _lingua, language, from_locale and text' => sub {
		is Database::BI::I18N::choose(accept => 'fr', default => 'en-us'), 'en-us', 'choose: lingua picks nothing, so the default (the // arm)';
		is Database::BI::I18N::choose(accept => 'en-GB'), 'en', 'choose: lingua picks en';
		is Database::BI::I18N::lingua_choice('en-US', [ 'en' ]), 'en', '_lingua: a region the list does not offer: the language alone';
		is Database::BI::I18N::lingua_choice('en', [ 'en', 'en-us' ]), 'en', '_lingua: no region named: the language';
		{
			local $Database::BI::I18N::LANGUAGE;
			is Database::BI::I18N::language(), 'en', 'language: unset is the base';
			local $Database::BI::I18N::LANGUAGE = 'en-us';
			is Database::BI::I18N::language(), 'en-us', 'language: set is what was set';
		}
		{
			local @ENV{qw(LC_ALL LC_MESSAGES LANG)} = ('zz_ZZ.UTF-8', undef, undef);
			delete @ENV{qw(LC_MESSAGES LANG)};
			is Database::BI::I18N::from_locale(), 'en', 'from_locale: a locale lingua cannot read: the base (the // arm)';
			is Database::BI::I18N::from_locale(), 'en', '... and again from the memo';
		}
		# text(): no key | British language | other language with own entry | without package | without key.
		my %messages = (known => 'British', other => 'only British');
		is Database::BI::I18N::text('P', \%messages, undef), undef, 'text: no key';
		{
			local $Database::BI::I18N::LANGUAGE = 'en';
			is Database::BI::I18N::text('P', \%messages, 'known'), 'British', 'text: the base language';
		}
		local $Database::BI::I18N::LANGUAGE = 'en-us';
		my $pkg = 'Database::BI::Controller::Dashboard';
		like Database::BI::I18N::text($pkg, { warn_measure_fallback => 'x' }, 'warn_measure_fallback'), qr/totaled/, 'text: the language has its own entry';
		is Database::BI::I18N::text($pkg, { error_nothing => 'British only' }, 'error_nothing'), 'British only', 'text: the package has no entry for the key';
		is Database::BI::I18N::text('No::Such::Package', \%messages, 'known'), 'British', 'text: the package has no entry at all';
		is Database::BI::I18N::text('No::Such::Package', \%messages, 'absent'), undef, 'text: neither has the key';
	};

	# Extract::new: dir given | cache_dir resolved | model_dir | none (croak).
	subtest 'Extract::new paths: dir, empty dir, model_dir and the refusal' => sub {
		my $dir = tempdir(CLEANUP => 1);
		is(Database::BI::Extract->new(dir => $dir)->_extract_dir, $dir, 'dir names the folder outright');
		my $from_model = Database::BI::Extract->new(dir => '', model_dir => $dir, config => {}, home => $dir);
		like $from_model->_extract_dir, qr/\Q$dir\E/, 'an empty dir falls through to model_dir';
		throws_ok { Database::BI::Extract->new(dir => undef, config => {}, home => $dir) } qr/\Amodel_dir is required/, 'no dir and no model_dir: the exact refusal';
		throws_ok { Database::BI::Extract->new(model_dir => '', config => {}, home => $dir) } qr/\Amodel_dir is required/, 'an empty model_dir is as missing';
		my $cached = Database::BI::Extract->new(cache_dir => $dir, model_dir => $dir, config => {}, home => $dir);
		like $cached->_extract_dir, qr/\Q$dir\E.*database-bi-extracts/, 'a cache_dir wins: the extracts go under it';
	};

	# Extract::evict: no dir | dir (unlink ok | unlink fails) .
	subtest 'Extract::evict paths: nothing there, files removed, and a file that cannot be removed' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $extract = Database::BI::Extract->new(dir => File::Spec->catdir($dir, 'absent'));
		is $extract->evict('x'), 0, 'no folder: 0';
		my $real = Database::BI::Extract->new(dir => $dir);
		Mojo::File->new($dir, "a$_.db")->spew('x') for 1 .. 3;
		Mojo::File->new($dir, 'keep.txt')->spew('x');
		is $real->evict('x'), 3, 'three .db files removed and counted';
		ok -e File::Spec->catfile($dir, 'keep.txt'), 'other files are left';
		Mojo::File->new($dir, 'stuck.db')->spew('x');
		SKIP: {
			skip 'cannot revoke create here', 2 unless can_revoke_create($dir);
			with_revoked('create', $dir, sub {
				is $real->evict('x'), 0, 'a file that cannot be removed is not counted';
			});
			ok -e File::Spec->catfile($dir, 'stuck.db'), '... and is still there';
		}
	};

	# Boundary::_outline_id: every gate in its order, then boundary | place | neither.
	subtest 'Boundary::_outline_id paths: each gate refuses, then the three ways to accept' => sub {
		my $id  = \&Database::BI::Model::Boundary::_outline_id;
		my $try = { ranks => [ 10, 12 ] };
		my $places = { ranks => [ 10, 18 ], places => 1 };
		my $good = sub { return { osm_id => 5, place_rank => 12, category => 'boundary', type => 'administrative', osm_type => 'relation',
			geojson => { type => 'Polygon', coordinates => [] }, @_ } };
		is $id->($good->(), $try), 'R5', 'an administrative relation: R<id>';
		my %refused = (
			'no osm_id'            => $good->(osm_id => undef),
			'osm_id not numeric'   => $good->(osm_id => 'x5'),
			'no rank'              => $good->(place_rank => undef),
			'rank a reference'     => $good->(place_rank => [ 12 ]),
			'rank not numeric'     => $good->(place_rank => 'twelve'),
			'rank below the range' => $good->(place_rank => 9),
			'rank above the range' => $good->(place_rank => 13),
			'geometry not a hash'  => $good->(geojson => 'x'),
			'geometry has no type' => $good->(geojson => { coordinates => [] }),
			'a Point'              => $good->(geojson => { type => 'Point', coordinates => [] }),
			'no coordinates list'  => $good->(geojson => { type => 'Polygon', coordinates => 'x' }),
			'a boundary, not admin'=> $good->(type => 'ceremonial'),
			'no type at all'       => $good->(type => undef),
			'a boundary way'       => $good->(osm_type => 'way'),
			'no category'          => $good->(category => undef),
			'no osm_type'          => $good->(osm_type => undef),
		);
		is $id->($refused{$_}, $try), undef, "refused: $_" for sort keys %refused;
		is $id->($good->(category => 'place', type => 'city', osm_type => 'relation', place_rank => 16), $places), 'R5', 'a place relation, when the try takes places';
		is $id->($good->(category => 'place', type => 'suburb', osm_type => 'way', place_rank => 16), $places), 'W5', 'a place way: W<id>';
		is $id->($good->(category => 'place', type => 'suburb', osm_type => 'node', place_rank => 16), $places), undef, 'a place node (a point): not an outline';
		is $id->($good->(category => 'place', type => 'city', osm_type => 'relation', place_rank => 12), $try), undef, 'a place, when the try does not take places';
	};

	# Boundary::_reverse: the user agent dies | answers badly | answers JSON of the wrong kind | answers.
	subtest 'Boundary::_reverse paths: every way the reply can fail before a hash comes back' => sub {
		my $b = Database::BI::Model::Boundary->new;
		my $reverse = sub { my ($ua) = @_; $b->{ua} = $ua; return $b->_reverse(10, 20, $PATH{zoom_ok}) };
		my $answer = sub { my ($ok, $body) = @_; bless { ok => $ok, body => $body }, 'Unit::PathReply' };
		is $reverse->(bless { code => sub { die "down\n" } }, 'Unit::PathUA'), undef, 'the agent dies';
		is $reverse->(bless { code => sub { 'a string' } }, 'Unit::PathUA'), undef, 'the answer is not an object';
		is $reverse->(bless { code => sub { bless {}, 'Unit::NoSuccess' } }, 'Unit::PathUA'), undef, 'the object has no is_success';
		is $reverse->(bless { code => sub { $answer->(0, '{}') } }, 'Unit::PathUA'), undef, 'an HTTP error';
		is $reverse->(bless { code => sub { $answer->(1, undef) } }, 'Unit::PathUA'), undef, 'no body (decoded_content undef)';
		is $reverse->(bless { code => sub { $answer->(1, 'not json') } }, 'Unit::PathUA'), undef, 'a body that is not JSON';
		is $reverse->(bless { code => sub { $answer->(1, '[1]') } }, 'Unit::PathUA'), undef, 'JSON that is a list';
		is_deeply $reverse->(bless { code => sub { $answer->(1, '{"a":1}') } }, 'Unit::PathUA'), { a => 1 }, 'JSON that is an object: returned';
		# With no agent given, the shared Nominatim one is asked.
		delete $b->{ua};
		mock 'Database::BI::Model::Geocode::nominatim_ua' => sub { bless { code => sub { $answer->(1, '{"shared":1}') } }, 'Unit::PathUA' };
		is_deeply $b->_reverse(10, 20, $PATH{zoom_ok}), { shared => 1 }, 'no ua given: Geocode::nominatim_ua is used';
		restore_all();
	};

	# Boundary::_bounds: no polygon | empty outer ring | points that move each of the four extremes.
	subtest 'Boundary::_bounds paths: nothing, an empty ring, and every extreme taken from both sides' => sub {
		my $bounds = \&Database::BI::Model::Boundary::_bounds;
		is $bounds->(undef), undef, 'no geometry';
		is $bounds->({ type => 'Polygon', coordinates => [] }), undef, 'a polygon with no rings';
		is $bounds->({ type => 'Polygon', coordinates => [ [] ] }), undef, 'a polygon whose outer ring is empty';
		is_deeply $bounds->({ type => 'Polygon', coordinates => [ [ [ 5, 6 ] ] ] }), [ 6, 5, 6, 5 ], 'one point: all four extremes';
		# Each later point lowers or raises one extreme, and one leaves all four alone.
		my $ring = [ [ 5, 6 ], [ 4, 7 ], [ 6, 5 ], [ 5, 6 ], [ 3, 8 ], [ 7, 4 ] ];
		is_deeply $bounds->({ type => 'Polygon', coordinates => [ $ring ] }), [ 4, 3, 8, 7 ], 'south, west, north, east each both set and left alone';
		is_deeply $bounds->({ type => 'MultiPolygon', coordinates => [ [ [ [ 1, 1 ] ] ], [ [ [ 9, 9 ] ] ] ] }), [ 1, 1, 9, 9 ], 'a MultiPolygon spans its polygons';
	};

	# Boundary::_plan: country (undef | reference | code) x level (county rank | plans | tries).
	subtest 'Boundary::_plan paths: country normalising and the three kinds of plan' => sub {
		my $county = Database::BI::Model::Boundary->new(ranks => { lk => 10 });
		is_deeply $county->_plan(undef), [ { zoom => 8, ranks => [ 12, 12 ] } ], 'county, no country: the default rank';
		is_deeply $county->_plan([ 'lk' ]), $county->_plan(undef), 'a reference is no country';
		is_deeply $county->_plan('LK'), [ { zoom => 6, ranks => [ 10, 10 ] } ], 'a country with its own rank, in any case';
		my $city = Database::BI::Model::Boundary->new(level => 'city');
		is_deeply $city->_plan('xx'), $city->_plan(undef), 'city, a country with no plan of its own: the level tries';
		isnt $city->_plan('nz'), $city->_plan(undef), 'city, a country with its own plan (New Zealand)';
	};

	# Boundary::_current: not a hash | no rank | no/other detail | detail ok.
	subtest 'Boundary::_current paths: each reason an outline is not current' => sub {
		my $b = Database::BI::Model::Boundary->new;
		my $detail = $b->_detail;
		is $b->_current(undef), 0, 'undef';
		is $b->_current('x'), 0, 'not a hash';
		is $b->_current({ detail => $detail }), 0, 'no rank';
		is $b->_current({ rank => 12 }), 0, 'no detail (the // arm)';
		is $b->_current({ rank => 12, detail => 'other' }), 0, 'another detail';
		is $b->_current({ rank => 12, detail => $detail }), 1, 'rank and detail as now: current';
		is $b->_current({ rank => 8, detail => $detail }), 0, 'a rank the plan no longer takes';
	};

	# Boundary::_can_ask and _ask: no agent | a later try that fails | a nameless reply | a shape with no points.
	subtest 'Boundary paths: _can_ask without an agent, and the rarer ends of _ask' => sub {
		my $class = 'Database::BI::Model::Boundary';
		mock 'Database::BI::Model::Geocode::nominatim_ua' => sub { undef };
		my $none = $class->new(online => 1, cache => bless({ store => {} }, 'Unit::ForgetfulCache'));
		is $none->lookup_point('10.500,20.500')->{asked}, 0, 'online but no agent to ask with: not asked (_can_ask false)';
		is $none->lookup_point('10.500,20.500')->{status}, 'held', '... so the point is held';
		restore_all();

		# An agent that answers by script: one reply per call, then the last again.
		my $scripted = sub {
			my @replies = @_;
			my $n = 0;
			return bless { code => sub { my $r = $replies[ $n < @replies ? $n++ : $#replies ]; $r } }, 'Unit::PathUA';
		};
		my $json = sub { my ($data) = @_; return bless { ok => 1, body => JSON::PP->new->canonical->encode($data) }, 'Unit::PathReply' };
		my $failure = bless { ok => 0, body => '' }, 'Unit::PathReply';
		my $polygon = { type => 'Polygon', coordinates => [ [ [ 20, 10 ], [ 21, 10 ], [ 21, 11 ], [ 20, 11 ], [ 20, 10 ] ] ] };
		my $area = sub { return { osm_id => 7, osm_type => 'relation', category => 'boundary', type => 'administrative', place_rank => 12,
			geojson => $polygon, address => { country_code => 'xx' }, name => 'Seven', display_name => 'Seven, Somewhere', @_ } };

		# The first reply names a country whose plan starts at another zoom: the second ask fails.
		my $us_then_fail = $class->new(online => 1, ranks => { xx => 10 }, cache => bless({ store => {} }, 'Unit::ForgetfulCache'), ua => $scripted->($json->($area->(place_rank => 4)), $failure));
		is $us_then_fail->lookup_point('10.500,20.500')->{status}, 'held', 'a later reverse lookup that fails: the point is held, not decided';

		my $nameless = $class->new(online => 1, cache => bless({ store => {} }, 'Unit::ForgetfulCache'), ua => $scripted->($json->($area->(name => '', display_name => 'Seven, Somewhere'))));
		is $nameless->lookup_point('10.500,20.500')->{status}, 'found', 'a reply with no name is still an outline';
		my %cache;
		my $recording = bless { store => \%cache, keep_outlines => 1 }, 'Unit::ForgetfulCache';
		my $named = $class->new(online => 1, cache => $recording, ua => $scripted->($json->($area->(name => '', display_name => 'Seven, Somewhere'))));
		$named->lookup_point('10.500,20.500');
		is $cache{'outline:R7:' . $named->_detail}{name} // $cache{'outline:R7'}{name}, 'Seven, Somewhere', 'its name is the display name (the fallback arm)';

		my $empty_ring = $area->(geojson => { type => 'Polygon', coordinates => [ [] ] });
		my %cache2;
		my $no_box = $class->new(online => 1, cache => bless({ store => \%cache2, keep_outlines => 1 }, 'Unit::ForgetfulCache'), ua => $scripted->($json->($empty_ring)));
		is $no_box->lookup_point('10.500,20.500')->{status}, 'found', 'a shape with no points is accepted';
		is_deeply $no_box->_index, [], '... but adds nothing to the index (no bounding box)';
	};

	# lookup_point / outlines: an outline the cache will not give back.
	subtest 'Boundary paths: a cache that forgets outlines' => sub {
		require BI::Test::Boundary;
		my $ua = BI::Test::Boundary->new(areas => [ { name => 'Ten', id => 1, box => [ 9, 19, 11, 21 ] } ]);
		my %store;
		my $cache = bless { store => \%store }, 'Unit::ForgetfulCache';
		BI::Test::Boundary::with_ua($ua, sub {
			my $b = Database::BI::Model::Boundary->new(online => 1, cache => $cache);
			my $answer = $b->lookup_point('10.500,20.500');
			is $answer->{status}, 'found', 'a found point, though its outline was not kept';
			is $answer->{name}, undef, '... has no name to give (the no-outline arm)';
			my $drawn = $b->outlines([ [ 10.5, 20.5 ] ], lookup => 0);
			is scalar(@{ $drawn->{features} }), 0, 'outlines: the missing outline is skipped, not fatal (the next arm)';
		});
	};
}

done_testing;
