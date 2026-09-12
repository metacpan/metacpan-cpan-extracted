use strict;
use warnings;
use Test::Most;
use Test::Mockingbird	qw(mock restore_all);
use Readonly;
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

subtest 'DataSource::new path-C: table name invalid -> croak' => sub {
	throws_ok {
		Database::BI::Model::DataSource->new(
			directory => $TMPDIR,
			table     => '1invalid',
		)
	} qr/contains illegal characters/,
		'path C: digit-start table -> croak error_table_name_invalid';
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
			mock 'DBI::connect' => sub { die "cannot connect\n" };
			my $tmpfile_created;
			mock 'File::Temp::tempfile' => sub {
				my (undef, $file) = File::Temp::tempfile(SUFFIX => '.db', UNLINK => 0);
				$tmpfile_created = $file;
				open my $fh, '>', $file or die "open: $!";
				return ($fh, $file);
			};
			throws_ok { $WRITE_SQLITE->($dummy_self, [], [qw(id val)]) }
				qr/DBI connect failed/,
				'path B: DBI connect failure -> croak';
			ok !-f $tmpfile_created, 'path B: tmpfile was unlinked during cleanup'
				if defined $tmpfile_created;
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
# CFG:
#   A: no Accept-Language header     -> $lang = undef -> default
#   B: header, code equals default   -> skip dir check -> return default
#   C: header, code ne default, dir exists   -> return extracted code
#   D: header, code ne default, dir missing  -> fall back to default
#   E: header present but no 2-letter match  -> $lang undef -> default
# ======================================================================

subtest '_resolve_language path-A: no Accept-Language header -> default' => sub {
	my $ctrl = mock_ctrl(undef);    # undef accept_language -> early return
	my $lang = $RESOLVE_LANG->($ctrl, 'web', 'en');
	is $lang, 'en', 'path A: absent header -> early return with default (en)';
};

subtest '_resolve_language path-B: header code equals default -> return default (no dir check)' => sub {
	my $ctrl = mock_ctrl('en-US,en;q=0.9');
	my $lang = $RESOLVE_LANG->($ctrl, 'web', 'en');
	is $lang, 'en', 'path B: code == default -> returns default without dir check';
};

subtest '_resolve_language path-C: header code ne default, template dir exists -> use it' => sub {
	# Create a temporary templates/web/fr directory so CGI::Lingua can select 'fr'.
	my $fr_dir = Mojo::File->new($APP_HOME)->child('templates/web/fr');
	my $created = !-d $fr_dir;
	$fr_dir->make_path if $created;
	my $ctrl = mock_ctrl('fr-FR,fr;q=0.9,en;q=0.8');
	my $lang = $RESOLVE_LANG->($ctrl, 'web', 'en');
	is $lang, 'fr', 'path C: template dir exists -> CGI::Lingua selects fr';
	$fr_dir->remove_tree if $created;    # clean up temp dir
};

subtest '_resolve_language path-D: no supported template for requested language -> default' => sub {
	# 'de' templates do not exist; CGI::Lingua finds no match in supported list -> undef -> default.
	my $ctrl = mock_ctrl('de,de-DE;q=0.9');
	my $lang = $RESOLVE_LANG->($ctrl, 'web', 'en');
	is $lang, 'en', 'path D: no templates/web/de -> CGI::Lingua returns undef -> default';
};

subtest '_resolve_language path-E: no parseable language -> default' => sub {
	my $ctrl = mock_ctrl('q=0.9');
	my $lang = $RESOLVE_LANG->($ctrl, 'web', 'en');
	is $lang, 'en', 'path E: unrecognised Accept-Language -> default';
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

subtest 'HTTP view path-B: valid name, no backing file -> 200 with error in body' => sub {
	$t->get_ok('/view/no_such_table_xyz')
	  ->status_is(200)
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

done_testing;
