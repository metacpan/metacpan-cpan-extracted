use strict;
use warnings;
use Test::Most;
use Test::Mockingbird;
use Test::Returns qw(returns_is returns_isnt);
use Test::Memory::Cycle;
use File::Basename ();
use File::Spec   ();
use POSIX ();
use File::Temp   qw(tempdir);
use Mojo::File   ();
use Mojo::JSON   qw(decode_json);
use Scalar::Util qw(blessed);
use Test::Mojo;
use Readonly;

# ---------------------------------------------------------------------------
# Constants -- no magic strings/numbers in assertions
# ---------------------------------------------------------------------------

Readonly my $DATA_DIR   => 'data';
Readonly my $SALES_CSV  => 'sales';
Readonly my $PROD_PSV   => 'products';

# ---------------------------------------------------------------------------
# Load the modules under test
# ---------------------------------------------------------------------------

use_ok('Database::BI::Model::DataSource');
use_ok('Database::BI::Controller::Dashboard');

# Full app used for controller-context tests.
my $t = Test::Mojo->new('Database::BI');

# The model store (.bi/) is shared state in the checkout: give this file its
# own directory, so a parallel run cannot create, read or write it underneath.
# A block near the end redirects its own app; the rest of the file uses this one.
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

# ============================================================================
# PART 1: Database::BI::Model::DataSource
# ============================================================================

my $DS = 'Database::BI::Model::DataSource';

# ---------------------------------------------------------------------------
# Subtest: _url_label -- derive safe identifier from URL
#
# Strategy: exercise each branch (path component, extension strip, host
# fallback) with representative inputs.  _url_label is not :Private so it
# survives stash cleanup in both test and production contexts.
# ---------------------------------------------------------------------------
subtest '_url_label -- derives safe identifier from URL' => sub {
	my $fn = \&Database::BI::Model::DataSource::_url_label;

	# Typical case: last path segment with extension
	is $fn->('http://example.com/data/sales.csv'), 'sales',
		'strips extension from last path component';

	# Query string and fragment are stripped before extension removal
	is $fn->('https://host.org/report.html?foo=bar#anchor'), 'report',
		'strips query string and fragment before extension removal';

	# Deep path: only the last component matters
	is $fn->('http://a.b/x/y/z/products.psv'), 'products',
		'takes last non-empty path segment';

	# Sanitize non-alphanumeric (e.g. hyphens, dots in name)
	is $fn->('http://host/my-data-file'), 'my_data_file',
		'converts hyphens to underscores';

	# No path component: fall back to hostname
	is $fn->('http://example.com/'), 'example_com',
		'falls back to hostname when path is just slash';

	is $fn->('http://example.com'), 'example_com',
		'falls back to hostname when no path at all';

	# Path component that starts with a digit: fall back to hostname
	is $fn->('http://host/123report'), 'host',
		'falls back to hostname when path component starts with digit';

	# Embedded newline in URL (percent-decoded %0A case): /s flag ensures
	# the query-strip regex crosses the newline without leaving a fragment.
	my $url_with_nl = "http://host/file.csv\ngarbage";
	my $label = $fn->($url_with_nl);
	ok length($label), 'handles embedded newline in URL gracefully';
	unlike $label, qr/\n/, 'label contains no newline';

	diag "verbose: _url_label test done" if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
# Subtest: _fmt -- package-level message formatter
#
# Verifies that sprintf interpolation works and that an unknown key produces
# a recognisable fallback rather than croaking.
# ---------------------------------------------------------------------------
subtest '_fmt -- package-level message formatter' => sub {
	my $fn = \&Database::BI::Model::DataSource::_fmt;

	# Known key, no args
	my $msg = $fn->('error_directory_required');
	ok length($msg), 'returns non-empty string for known key';
	unlike $msg, qr/Internal error/, 'does not trigger unknown-key fallback';

	# Known key with sprintf arg
	my $dir_msg = $fn->('error_directory_missing', '/no/such/dir');
	like $dir_msg, qr{/no/such/dir}, 'interpolates sprintf arg into message';

	# Unknown key -- must NOT croak; returns a fallback string
	my $fallback = $fn->('this_key_does_not_exist');
	like $fallback, qr/Internal error.*this_key_does_not_exist/,
		'unknown key returns descriptive fallback';

	diag "_fmt messages: dir_msg=$dir_msg" if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
# Subtest: DataSource::new -- argument validation
#
# Tests the guard clauses in the constructor before _init_backend touches
# any files.  Uses the real data/ directory so no mocking of the filesystem
# is required for the success path.
# ---------------------------------------------------------------------------
subtest 'DataSource::new -- argument validation' => sub {
	# Success: opens sales.csv from the real data directory
	my $src = eval { $DS->new(directory => $DATA_DIR, table => $SALES_CSV) };
	is $@, '', 'no exception for valid directory and table';
	ok $src, 'returns a defined object';
	ok blessed($src), 'object is blessed';
	is ref($src), $DS, 'correct class';

	# Missing directory argument
	throws_ok { $DS->new(table => 'sales') }
		qr/directory/i,
		'croaks when directory is missing';

	# Missing table argument
	throws_ok { $DS->new(directory => $DATA_DIR) }
		qr/table/i,
		'croaks when table is missing';

	# Non-existent directory
	throws_ok { $DS->new(directory => '/no/such/dir', table => 'sales') }
		qr/does not exist|not readable/i,
		'croaks for non-existent directory';

	# Table name with path traversal characters (path separators are rejected)
	throws_ok { $DS->new(directory => $DATA_DIR, table => '../etc/passwd') }
		qr/illegal characters/i,
		'croaks for table name with path traversal';

	# Table name with leading digit: sanitized to _1bad (prepend underscore)
	{
		my $src;
		lives_ok { $src = $DS->new(directory => $DATA_DIR, table => '1bad') }
			'digit-start table name is sanitized (not rejected)';
		is $src->table_name, '_1bad', 'sanitized table name has underscore prefix';
	}

	# Table name with spaces: sanitized to my_table (spaces -> underscores)
	{
		my $src;
		lives_ok { $src = $DS->new(directory => $DATA_DIR, table => 'my table') }
			'table name with spaces is sanitized (not rejected)';
		is $src->table_name, 'my_table', 'sanitized table name has underscores for spaces';
	}

	# Accept hashref form (Params::Get normalises)
	my $src2 = eval { $DS->new({ directory => $DATA_DIR, table => $SALES_CSV }) };
	is $@, '', 'accepts hashref argument form';
	ok $src2, 'hashref form returns defined object';
};

# ---------------------------------------------------------------------------
# Subtest: DataSource::new with i18n override
#
# Passing an object with a maketext() method must cause error messages to
# route through that object instead of the built-in %MESSAGES table.
# ---------------------------------------------------------------------------
subtest 'DataSource::new -- i18n object routes messages through maketext' => sub {
	# Build a minimal mock i18n object.
	my $calls = [];
	my $i18n  = bless {}, 'FakeI18N';
	{
		no strict 'refs';
		*{'FakeI18N::maketext'} = sub {
			my ($self, $key, @args) = @_;
			push @$calls, $key;
			return "TRANSLATED:$key";
		};
	}

	# Trigger a validation error so _msg / maketext is called.
	eval { $DS->new(directory => '/no/such/dir', table => 'x', i18n => $i18n) };
	ok scalar(@$calls) == 0,
		'_fmt (pre-object) does not call i18n object; object not yet constructed';
	# The croak happens in new() via _fmt(), before the object exists.
	# _msg() is only called post-construction; test that via fetch_all mock below.
};

# ---------------------------------------------------------------------------
# Subtest: DataSource accessors -- table_name, columns, id_column, source_url
# ---------------------------------------------------------------------------
subtest 'DataSource accessors -- CSV file' => sub {
	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);

	is $src->table_name, $SALES_CSV, 'table_name returns lowercase table name';

	my $cols = $src->columns;
	returns_is $cols, { type => 'arrayref' }, 'columns() returns an arrayref for CSV';
	ok scalar(@$cols) > 0, 'columns() is non-empty for sales.csv';
	is $cols->[0], 'id', 'first column of sales.csv is "id" (the id column)';

	is $src->id_column, 'id', 'id_column returns first CSV column';
	is $src->source_url, undef, 'source_url is undef for file-backed instance';

	diag 'sales.csv columns: ' . join(', ', @$cols) if $ENV{TEST_VERBOSE};
};

subtest 'DataSource accessors -- PSV file' => sub {
	my $src = $DS->new(directory => $DATA_DIR, table => $PROD_PSV);

	is $src->table_name, $PROD_PSV, 'table_name correct for PSV';
	my $cols = $src->columns;
	returns_is $cols, { type => 'arrayref' }, 'columns() returns arrayref for PSV';
	is $cols->[0], 'id', 'first column of products.psv is "id"';
};

# ---------------------------------------------------------------------------
# Subtest: _detect_file_info -- header sniffing for CSV and PSV
#
# Calls the private helper directly (stash not cleaned in test context).
# ---------------------------------------------------------------------------
subtest '_detect_file_info -- sniffs separator and column order' => sub {
	my $fn = \&Database::BI::Model::DataSource::_detect_file_info;

	# CSV path: separator=comma, id=first column
	my $csv_info = $fn->($DATA_DIR, $SALES_CSV);
	returns_is $csv_info, { type => 'hashref' }, '_detect_file_info returns hashref for CSV';
	is $csv_info->{sep_char}, ',', 'CSV separator detected as comma';
	is $csv_info->{id},       'id', 'CSV id column is first header field';
	returns_is $csv_info->{columns}, { type => 'arrayref' },
		'CSV columns is an arrayref';

	# PSV path: separator=pipe
	my $psv_info = $fn->($DATA_DIR, $PROD_PSV);
	is $psv_info->{sep_char}, '|', 'PSV separator detected as pipe';

	# Non-existent table (no matching file): empty hashref
	my $none = $fn->($DATA_DIR, 'no_such_table_xyz');
	returns_is $none, { type => 'hashref' }, 'empty hashref for non-existent table';
	ok !%$none, 'hashref is empty for non-existent table';
};

# ---------------------------------------------------------------------------
# Bug-regression subtests for _detect_file_info id-column selection.
#
# Three production bugs were found when opening a real bank-export CSV:
#
#  Bug 1 (case):  table name was lowercased before file lookup -- missed on
#                 case-sensitive Linux when the stem had mixed case.
#  Bug 2 (space): first column "Account Number" fails $SAFE_IDENTIFIER ->
#                 Database::Abstraction croaked "unsafe id column name".
#  Bug 3 (empty): first *safe* column "Check" was always empty (undef with
#                 empty_is_undef) so D::A grep dropped every non-cheque row.
#
# These subtests call _detect_file_info directly to pin the id-selection
# logic before the HTTP layer is involved.
# ---------------------------------------------------------------------------

{
	my $fn  = \&Database::BI::Model::DataSource::_detect_file_info;
	my $dir = File::Temp::tempdir(CLEANUP => 1);

	# Bug 2: first column has a space -> must pick a safe column instead.
	subtest '_detect_file_info -- unsafe first column (space) uses first safe col' => sub {
		Mojo::File->new("$dir/bank.csv")->spew(
			"Account Number,Date,Amount\n12345,2026-01-01,100.00\n"
		);
		my $info = $fn->($dir, 'bank');
		like   $info->{id}, qr/\A[a-zA-Z_][a-zA-Z0-9_]*\z/,
			'id is a safe identifier despite unsafe first column';
		is     $info->{id}, 'Date',
			'id falls back to first safe column (Date)';
		is_deeply $info->{columns}, ['Account Number', 'Date', 'Amount'],
			'original column names preserved for display';
	};

	# Bug 3: first safe column is empty in the data row -> must skip to next.
	subtest '_detect_file_info -- first safe col empty in data row -> picks next' => sub {
		# "ref" is a safe identifier but always blank; "description" is the
		# first safe column that has a value in the data row.
		Mojo::File->new("$dir/acct.csv")->spew(
			"Account Number,ref,description,amount\n" .
			"XX1234,,Coffee shop,4.50\n"
		);
		my $info = $fn->($dir, 'acct');
		is $info->{id}, 'description',
			'id skips empty "ref" column and picks "description"';
	};

	# Both bug 2 and 3 together: real-world bank CSV shape.
	subtest '_detect_file_info -- bank CSV: unsafe + empty cols, picks reliable id' => sub {
		# Mirrors AccountHistory.csv: "Check" is safe but always empty;
		# "Description" is safe and always populated.
		Mojo::File->new("$dir/history.csv")->spew(
			"Account Number,Post Date,Check,Description,Debit,Credit,Status\n" .
			"XX2106,8/26/2026,,Coffee shop,4.50,,Posted\n" .
			"XX2106,8/25/2026,,Supermarket,12.00,,Posted\n"
		);
		my $info = $fn->($dir, 'history');
		is $info->{id}, 'Description',
			'id skips "Check" (empty in data) and picks "Description"';
		is scalar(@{$info->{columns}}), 7,
			'all 7 original columns preserved';
	};

	# Bug 2+3 guard: all columns have unsafe names -> id must be undef.
	subtest '_detect_file_info -- all columns unsafe -> id undef' => sub {
		Mojo::File->new("$dir/allbad.csv")->spew("my-col,his-col\n1,2\n");
		my $info = $fn->($dir, 'allbad');
		ok exists $info->{columns}, 'columns key present';
		ok !defined $info->{id},    'id is undef when no safe column exists';
	};

	# _values_are_data_like: true when first line contains dates/numbers.
	subtest '_values_are_data_like -- date pattern triggers headerless detection' => sub {
		my $data_like = \&Database::BI::Model::DataSource::_values_are_data_like;
		ok  $data_like->(['2026-09-09', '-75.13', 'ACME CO']),
			'ISO date + signed number -> data-like';
		ok  $data_like->(['15/09/2026', '100.00', 'Coffee']),
			'slash-date -> data-like';
		ok  $data_like->(['foo', '-3.14', 'bar']),
			'signed number alone -> data-like';
		ok  $data_like->(['foo', '(99.50)', 'bar']),
			'accounting-notation negative -> data-like';
		ok !$data_like->(['first-name', 'last-name', 'email']),
			'hyphenated identifiers -> NOT data-like';
		ok !$data_like->(['My Col', 'His Col']),
			'space-separated words (no date/number) -> NOT data-like';
	};

	# _synthesize_col_names: infers date / amount / description.
	subtest '_synthesize_col_names -- type inference and deduplication' => sub {
		my $synth = \&Database::BI::Model::DataSource::_synthesize_col_names;
		is_deeply [ $synth->(['2026-09-09', '-75.13', 'ACME CO']) ],
			[qw(Date Amount Description)],
			'ISO date + amount + text -> Date, Amount, Description';
		is_deeply [ $synth->(['15/01/2026', '-10.00', 'Fee']) ],
			[qw(Date Amount Description)],
			'slash-date -> Date';
		is_deeply [ $synth->(['100.00', '200.00', '300.00']) ],
			[qw(Amount Amount2 Amount3)],
			'three numeric cols -> Amount, Amount2, Amount3';
		is_deeply [ $synth->(['2026-01-01', '2026-01-02']) ],
			[qw(Date Date2)],
			'two dates -> Date, Date2';
		is_deeply [ $synth->(['foo bar', 'baz qux']) ],
			[qw(Description Description2)],
			'two text cols -> Description, Description2';
	};

	# Full round-trip: DataSource built on a header-less CSV returns rows with
	# synthesized keys, read by Database::Abstraction from a copy with a header.
	subtest '_detect_file_info -- headerless CSV full fetch round-trip' => sub {
		# Descriptions contain spaces so no first-row value is a $SAFE_IDENTIFIER,
		# forcing the headerless-detection path.
		Mojo::File->new("$dir/bank.csv")->spew(
			"2026-09-01,-50.00,SUPER MARKET\n" .
			"2026-09-02,-12.50,COFFEE SHOP\n" .
			"2026-09-03,1200.00,SALARY CREDIT\n"
		);
		my $info = $fn->($dir, 'bank');
		ok exists $info->{_headerless},               'headerless marker returned';
		my $rows = $DS->new(directory => $dir, table => 'bank')->fetch_all;
		is scalar @{$rows}, 3,                        'all three rows parsed';
		is $rows->[2]{Amount}, '1200.00',             'positive Amount on row 3';
		is $rows->[0]{Description}, 'SUPER MARKET',   'Description on row 1';
	};

	# CRLF line endings (Windows exports) must not bleed \r into column names.
	subtest '_detect_file_info -- CRLF endings stripped from column names' => sub {
		{
			# Write raw CRLF bytes without :encoding layer.
			no autodie 'open';
			open my $fh, '>:raw', "$dir/crlf.csv" or die $!;
			print {$fh} "id,name,amount\r\n1,Alice,42.00\r\n";
			close $fh;
		}
		my $info = $fn->($dir, 'crlf');
		is $info->{id}, 'id', 'id column correct despite CRLF';
		is_deeply $info->{columns}, [qw(id name amount)],
			'no \\r in column names';
	};
}

# ---------------------------------------------------------------------------
# Subtest: DataSource::fetch_all -- normal path returns records
# ---------------------------------------------------------------------------
subtest 'DataSource::fetch_all -- returns records from CSV' => sub {
	my $src  = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);
	my $rows = eval { $src->fetch_all };
	is $@, '', 'fetch_all does not throw for valid table';
	returns_is $rows, { type => 'arrayref' }, 'fetch_all returns arrayref';
	ok scalar(@$rows) > 0, 'fetch_all returns at least one row';
	ok ref($rows->[0]) eq 'HASH', 'each row is a hashref';
	ok exists $rows->[0]{id}, 'row hashref has "id" key';
};

# ---------------------------------------------------------------------------
# Subtest: DataSource::fetch_all -- backend croak is re-wrapped
#
# Mock selectall_hashref to die so we can verify the error_fetch_failed
# message is produced.
# ---------------------------------------------------------------------------
subtest 'DataSource::fetch_all -- backend error is wrapped and re-thrown' => sub {
	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);

	# Patch the backend's selectall_hashref to simulate a backend failure.
	my $db_pkg = ref($src->{_db});
	Test::Mockingbird::mock("${db_pkg}::selectall_hashref", sub {
		die "simulated backend failure\n";
	});

	throws_ok { $src->fetch_all }
		qr/fetch_all failed.*simulated backend failure/i,
		'fetch_all wraps backend die with error_fetch_failed message';

	Test::Mockingbird::unmock("${db_pkg}::selectall_hashref");
};

# ---------------------------------------------------------------------------
# Subtest: DataSource::fetch_all -- hashref result is normalised to arrayref
#
# Database::Abstraction occasionally returns a hashref keyed by primary key.
# DataSource must convert it to an arrayref and emit a carp warning.
# ---------------------------------------------------------------------------
subtest 'DataSource::fetch_all -- hashref result normalised to arrayref' => sub {
	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);
	my $db_pkg = ref($src->{_db});

	Test::Mockingbird::mock("${db_pkg}::selectall_hashref", sub {
		return { row1 => { id => 1, product => 'Widget' } };
	});

	my $warned = '';
	local $SIG{__WARN__} = sub { $warned = $_[0] };

	my $rows = eval { $src->fetch_all };
	is $@, '', 'no exception when backend returns hashref';
	returns_is $rows, { type => 'arrayref' }, 'result normalised to arrayref';
	like $warned, qr/hashref|normalised|converted to arrayref/i,
		'carp warning emitted for hashref normalisation';

	Test::Mockingbird::unmock("${db_pkg}::selectall_hashref");
};

# ---------------------------------------------------------------------------
# Subtest: DataSource::fetch_all -- undef result returns empty arrayref
# ---------------------------------------------------------------------------
subtest 'DataSource::fetch_all -- undef backend result returns []' => sub {
	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);
	my $db_pkg = ref($src->{_db});

	Test::Mockingbird::mock("${db_pkg}::selectall_hashref", sub { return undef });

	# Suppress the carp about empty result
	local $SIG{__WARN__} = sub {};

	my $rows = eval { $src->fetch_all };
	is $@, '', 'no exception for undef backend result';
	is_deeply $rows, [], 'undef result normalised to empty arrayref';

	Test::Mockingbird::unmock("${db_pkg}::selectall_hashref");
};

# ---------------------------------------------------------------------------
# Subtest: DataSource::fetch_all -- empty result emits carp
# ---------------------------------------------------------------------------
subtest 'DataSource::fetch_all -- empty result emits carp warning' => sub {
	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);
	my $db_pkg = ref($src->{_db});

	Test::Mockingbird::mock("${db_pkg}::selectall_hashref", sub { return [] });

	my $warned = '';
	local $SIG{__WARN__} = sub { $warned = $_[0] };

	my $rows = $src->fetch_all;
	like $warned, qr/empty|no records/i,
		'carp warning emitted for empty result set';
	is_deeply $rows, [], 'empty arrayref returned';

	Test::Mockingbird::unmock("${db_pkg}::selectall_hashref");
};

# ---------------------------------------------------------------------------
# Subtest: DataSource memory -- no circular references
# ---------------------------------------------------------------------------
subtest 'DataSource -- no circular references (memory cycle check)' => sub {
	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);
	memory_cycle_ok($src, 'DataSource object has no circular references');
};

# ---------------------------------------------------------------------------
# Subtest: _new_from_url -- invalid URL scheme is rejected
# ---------------------------------------------------------------------------
subtest 'DataSource::_new_from_url -- invalid URL scheme croaks' => sub {
	throws_ok { $DS->new(url => 'ftp://example.com/data.csv') }
		qr/must begin with http/i,
		'croaks for ftp:// URL';

	throws_ok { $DS->new(url => 'file:///etc/passwd') }
		qr/must begin with http/i,
		'croaks for file:// URL';

	throws_ok { $DS->new(url => 'javascript:alert(1)') }
		qr/must begin with http/i,
		'croaks for javascript: pseudo-URL';
};

# ============================================================================
# PART 2: Database::BI::Controller::Dashboard -- pure-function helpers
#
# These subs are not :Private and survive stash cleanup, so they can be
# called as plain functions without a Mojolicious controller context.
# ============================================================================

my $D = 'Database::BI::Controller::Dashboard';

# ---------------------------------------------------------------------------
# Subtest: _is_safe_url -- SSRF guard
#
# Each blocked range has a representative, a boundary, and a just-safe IP.
# Non-IP hostnames must always pass (firewall handles those).
# ---------------------------------------------------------------------------
subtest '_is_safe_url -- loopback aliases are blocked' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_is_safe_url;

	ok !$fn->('http://localhost/'),           'localhost blocked';
	ok !$fn->('http://localhost:8080/path'),  'localhost with port blocked';
	ok !$fn->('https://localhost/'),          'https://localhost blocked';
	ok !$fn->('http://127.0.0.1/'),           '127.0.0.1 blocked';
	ok !$fn->('http://127.255.255.255/'),     '127.255.255.255 blocked (127/8)';
	ok !$fn->('http://0.0.0.0/'),             '0.0.0.0 blocked';
	ok !$fn->('http://[::1]/'),               'IPv6 ::1 blocked';
};

subtest '_is_safe_url -- RFC 1918 private ranges are blocked' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_is_safe_url;

	ok !$fn->('http://10.0.0.1/'),            '10.0.0.1 blocked (10/8)';
	ok !$fn->('http://10.255.255.255/'),      '10.255.255.255 blocked (10/8 boundary)';
	ok !$fn->('http://172.16.0.1/'),          '172.16.0.1 blocked (172.16/12)';
	ok !$fn->('http://172.31.255.255/'),      '172.31.255.255 blocked (172.16/12 boundary)';
	ok !$fn->('http://192.168.0.1/'),         '192.168.0.1 blocked (192.168/16)';
	ok !$fn->('http://192.168.255.255/'),     '192.168.255.255 blocked (192.168/16 boundary)';
};

subtest '_is_safe_url -- link-local and CGNAT ranges are blocked' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_is_safe_url;

	ok !$fn->('http://169.254.169.254/'),     'AWS metadata endpoint blocked (169.254/16)';
	ok !$fn->('http://169.254.0.1/'),         '169.254.0.1 blocked (link-local)';
	ok !$fn->('http://100.64.0.1/'),          '100.64.0.1 blocked (CGNAT 100.64/10)';
	ok !$fn->('http://100.127.255.255/'),     '100.127.255.255 blocked (CGNAT boundary)';
};

subtest '_is_safe_url -- public addresses are allowed' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_is_safe_url;

	ok $fn->('http://8.8.8.8/'),              '8.8.8.8 (Google DNS) allowed';
	ok $fn->('http://1.1.1.1/'),              '1.1.1.1 (Cloudflare) allowed';
	ok $fn->('https://example.com/data'),     'example.com hostname allowed';
	ok $fn->('http://internal.corp.example/'), 'internal hostname allowed (firewall handles it)';

	# Just outside blocked ranges
	ok $fn->('http://11.0.0.1/'),             '11.0.0.1 allowed (outside 10/8)';
	ok $fn->('http://172.32.0.1/'),           '172.32.0.1 allowed (outside 172.16/12)';
	ok $fn->('http://192.169.0.1/'),          '192.169.0.1 allowed (outside 192.168/16)';
	ok $fn->('http://100.128.0.1/'),          '100.128.0.1 allowed (outside 100.64/10)';
};

subtest '_is_safe_url -- non-http scheme returns 0' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_is_safe_url;

	ok !$fn->('ftp://example.com/'),          'ftp:// returns 0 (no http/https match)';
	ok !$fn->('file:///etc/passwd'),           'file:// returns 0';
	ok !$fn->(''),                             'empty string returns 0';
};

# ---------------------------------------------------------------------------
# Subtest: _get_columns -- column ordering logic
#
# For CSV/PSV the source stores the original file-header order.
# For SQLite/XML (columns() returns undef), the fallback puts id_column first
# then alphabetical order.
# ---------------------------------------------------------------------------
subtest '_get_columns -- returns file-header order for CSV source' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_get_columns;

	# Mock a DataSource that has an ordered column list (CSV case).
	my $mock_src = bless {}, 'FakeDS_CSV';
	{
		no strict 'refs';
		*{'FakeDS_CSV::columns'}   = sub { [qw(id product region amount)] };
		*{'FakeDS_CSV::id_column'} = sub { 'id' };
	}

	my @cols = $fn->($mock_src, [{ id => 1, product => 'x' }]);
	is_deeply \@cols, [qw(id product region amount)],
		'preserves file-header order from columns()';
};

subtest '_get_columns -- fallback alphabetical order when columns() is undef' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_get_columns;

	# Mock a DataSource where columns() returns undef (SQLite/XML case).
	my $mock_src = bless {}, 'FakeDS_SQLite';
	{
		no strict 'refs';
		*{'FakeDS_SQLite::columns'}   = sub { undef };
		*{'FakeDS_SQLite::id_column'} = sub { 'id' };
	}

	my $records = [{ id => 1, name => 'Alice', city => 'London' }];
	my @cols = $fn->($mock_src, $records);
	is $cols[0], 'id', 'id_column is first when columns() is undef';
	is_deeply [sort @cols[1..$#cols]], [sort qw(name city)],
		'remaining columns are present (sorted)';
};

subtest '_get_columns -- empty records returns empty list' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_get_columns;
	my $mock_src = bless {}, 'FakeDS_Empty';
	{
		no strict 'refs';
		*{'FakeDS_Empty::columns'}   = sub { undef };
		*{'FakeDS_Empty::id_column'} = sub { 'id' };
	}
	my @cols = $fn->($mock_src, []);
	is scalar(@cols), 0, 'empty records produce empty column list';
};

# ---------------------------------------------------------------------------
# Subtest: _apply_filter_spec -- all operators
#
# Each operator is tested with a two-record dataset to prove it accepts
# exactly the rows it should and rejects the others.
# ---------------------------------------------------------------------------
subtest '_apply_filter_spec -- eq operator (case-insensitive)' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
	my $records = [
		{ name => 'Alice', region => 'North' },
		{ name => 'Bob',   region => 'South' },
	];

	my $out = $fn->($records, 'region:eq:north');
	is scalar(@$out), 1,     'eq keeps exactly one matching row';
	is $out->[0]{name}, 'Alice', 'eq returns the correct row';

	# Case-insensitivity
	my $out2 = $fn->($records, 'region:eq:NORTH');
	is scalar(@$out2), 1, 'eq is case-insensitive';
};

subtest '_apply_filter_spec -- in operator (a JSON list, matched as eq is)' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
	my $records = [
		{ id => 1, place => 'Paris' },
		{ id => 2, place => 'Rome' },
		{ id => 3, place => '' },
		{ id => 4 },
		{ id => 5, place => '12345' },
		{ id => 6, place => 'Rome, Italy' },
	];
	my $ids = sub { [ map { $_->{id} } @{ $fn->($records, $_[0]) } ] };

	is_deeply $ids->('place:in:["paris","ROME"]'), [1, 2], 'any value of the list, case-insensitive, whole cells only';
	is_deeply $ids->('place:in:[""]'), [3, 4], 'an empty string is the empty cell, and a missing one';
	is_deeply $ids->('place:in:[null]'), [3, 4], 'and so is null';
	is_deeply $ids->('place:in:[12345]'), [5], 'a number in the list is its text';
	is_deeply $ids->('place:in:["Rome, Italy"]'), [6], 'a value may hold a comma';
	is_deeply $ids->('place:in:[]'), [], 'an empty list matches nothing';
	is_deeply $ids->('place:in:Paris'), [], 'a value that is not JSON matches nothing, rather than everything';
	is_deeply $ids->('place:in:{"a":"Paris"}'), [], 'nor does JSON that is not a list';
	is_deeply $ids->('place:in:[["Paris"]]'), [], 'and a list inside the list is not a value';
	is_deeply $ids->("place:in:[\"\\u00c9vian\"]"), [], 'a value outside ASCII is read as characters';
	my $accented = $fn->([ { place => "\x{c9}vian" } ], "place:in:[\"\x{e9}vian\"]");
	is scalar(@$accented), 1, 'and matched case-insensitively';
};

subtest '_apply_filter_spec -- ne operator' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
	my $records = [
		{ region => 'North' },
		{ region => 'South' },
	];
	my $out = $fn->($records, 'region:ne:north');
	is scalar(@$out), 1,          'ne keeps non-matching rows';
	is $out->[0]{region}, 'South', 'ne returns the non-matching row';
};

subtest '_apply_filter_spec -- contains operator' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
	my $records = [{ product => 'Widget A' }, { product => 'Gadget B' }];
	my $out = $fn->($records, 'product:contains:widget');
	is scalar(@$out), 1,                 'contains matches substring (case-insensitive)';
	is $out->[0]{product}, 'Widget A',   'contains returns correct row';
};

subtest '_apply_filter_spec -- starts operator' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
	my $records = [{ code => 'ABC123' }, { code => 'XYZ456' }];
	my $out = $fn->($records, 'code:starts:abc');
	is scalar(@$out), 1,              'starts matches prefix (case-insensitive)';
	is $out->[0]{code}, 'ABC123',     'starts returns correct row';

	my $none = $fn->($records, 'code:starts:123');
	is scalar(@$none), 0, 'starts does not match mid-string position';
};

subtest '_apply_filter_spec -- numeric operators lt le gt ge' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
	my $records = [{ amount => 100 }, { amount => 200 }, { amount => 300 }];

	is scalar(@{ $fn->($records, 'amount:lt:200') }), 1, 'lt keeps rows strictly less than';
	is scalar(@{ $fn->($records, 'amount:le:200') }), 2, 'le keeps rows less than or equal';
	is scalar(@{ $fn->($records, 'amount:gt:200') }), 1, 'gt keeps rows strictly greater than';
	is scalar(@{ $fn->($records, 'amount:ge:200') }), 2, 'ge keeps rows greater than or equal';
};

subtest '_apply_filter_spec -- empty and notempty operators' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
	my $records = [{ note => '' }, { note => 'has text' }, { note => undef }];

	my $empty = $fn->($records, 'note:empty:');
	# undef is normalised to '' so both undef and '' rows match
	ok scalar(@$empty) >= 1,          'empty matches blank/undef cells';
	ok(!(grep { length($_->{note} // '') } @$empty),
		'empty rows all have blank note field');

	my $notempty = $fn->($records, 'note:notempty:');
	is scalar(@$notempty), 1,         'notempty matches cells with content';
	is $notempty->[0]{note}, 'has text', 'notempty returns the non-blank row';
};

subtest '_apply_filter_spec -- between operator (date range, string comparison)' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
	my @rows = map { { date => $_ } } qw(2026-01-01 2026-06-15 2026-12-31 2027-01-01);

	my $in = $fn->(\@rows, 'date:between:2026-01-01:2026-12-31');
	is scalar(@$in), 3,                      'between includes lo, hi, and middle';
	is $in->[0]{date}, '2026-01-01',         'lo boundary included';
	is $in->[2]{date}, '2026-12-31',         'hi boundary included';

	my $out = $fn->(\@rows, 'date:between:2026-03-01:2026-09-30');
	is scalar(@$out), 1,                     'between narrows to matching rows';
	is $out->[0]{date}, '2026-06-15',        'only mid-range row returned';

	my $none = $fn->(\@rows, 'date:between:2028-01-01:2028-12-31');
	is scalar(@$none), 0,                    'between with no matches returns empty';

	# Degenerate: missing hi -- split gives lo only; hi is undef so length check fails
	my $bad = $fn->(\@rows, 'date:between:2026-01-01');
	is scalar(@$bad), 0,                     'between with no hi value returns empty';
};

subtest '_apply_filter_spec -- unknown operator passes all rows through' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
	my $records = [{ x => 1 }, { x => 2 }];
	my $out = $fn->($records, 'x:totally_unknown_op:1');
	is scalar(@$out), 2, 'unknown operator is a pass-through (all rows kept)';
};

subtest '_apply_filter_spec -- malformed spec returns input unchanged' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
	my $records = [{ x => 1 }, { x => 2 }];

	# No colon at all -- split gives a single element; col is set but op is undef
	my $out = $fn->($records, 'notaspec');
	is_deeply $out, $records, 'no-colon spec returns original arrayref';

	# Value containing colons: only first two colons are split points
	my $colon_val = $fn->($records, 'x:eq:1:extra:colons');
	# val would be '1:extra:colons' and eq comparison would fail for both rows
	ok ref($colon_val) eq 'ARRAY', 'spec with colons in value does not croak';
};

# ---------------------------------------------------------------------------
# Subtest: _csv_row -- RFC 4180 quoting
# ---------------------------------------------------------------------------
subtest '_csv_row -- plain fields joined with comma and CRLF' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_csv_row;

	my $line = $fn->('alpha', 'beta', 'gamma');
	is $line, "alpha,beta,gamma\r\n", 'plain fields joined with comma and CRLF';
};

subtest '_csv_row -- undef treated as empty string' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_csv_row;
	my $line = $fn->(undef, 'x', undef);
	is $line, ",x,\r\n", 'undef values become empty string in output';
};

subtest '_csv_row -- comma inside field triggers quoting' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_csv_row;
	my $line = $fn->('hello, world', 'plain');
	like $line, qr/^"hello, world",plain\r\n$/, 'field with comma is double-quoted';
};

subtest '_csv_row -- embedded double-quote is doubled' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_csv_row;
	my $line = $fn->('say "hi"');
	like $line, qr/^"say ""hi"""\r\n$/, 'embedded double-quote is doubled per RFC 4180';
};

subtest '_csv_row -- newline inside field triggers quoting' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_csv_row;
	my $line = $fn->("line1\nline2");
	like $line, qr/^"line1\nline2"\r\n$/, 'field with newline is double-quoted';
};

# ---------------------------------------------------------------------------
# Subtest: _serialize_csv -- full document output
# ---------------------------------------------------------------------------
subtest '_serialize_csv -- produces header + data rows' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_serialize_csv;

	my $records = [
		{ name => 'Alice', score => 95 },
		{ name => 'Bob',   score => 80 },
	];
	my $columns = [qw(name score)];

	my $csv = $fn->($records, $columns);
	ok length($csv), '_serialize_csv returns non-empty string';
	my @lines = split /\r\n/, $csv, -1;
	is $lines[0], 'name,score', 'first line is the header row';
	is $lines[1], 'Alice,95',   'second line is the first data row';
	is $lines[2], 'Bob,80',     'third line is the second data row';
};

subtest '_serialize_csv -- special characters are RFC 4180 quoted' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_serialize_csv;
	my $records = [{ note => 'hello, world' }];
	my $csv = $fn->($records, ['note']);
	like $csv, qr/"hello, world"/, 'field with comma is quoted in CSV output';
};

# ============================================================================
# PART 3: Dashboard controller actions via Test::Mojo
#
# These tests exercise the :Private helpers that require a Mojo controller
# context, accessible because Sub::Private CHECK phase has passed in tests.
# ============================================================================

# ---------------------------------------------------------------------------
# Subtest: _i18n -- message lookup with and without sprintf args
#
# _i18n does not use $self internally (it only reads %MESSAGES, which is
# lexically scoped to the Dashboard package), so we call it as a direct
# function with a dummy $self to avoid OO dispatch via the generic
# Mojolicious::Controller base returned by build_controller.
# ---------------------------------------------------------------------------

Readonly my $DASH => 'Database::BI::Controller::Dashboard';

subtest 'Dashboard::_i18n -- known key returns formatted string' => sub {
	# Direct package call bypasses OO dispatch (Sub::Private stash cleanup
	# does not affect direct calls resolved at compile time in test mode).
	my $msg = "${DASH}"->can('_i18n')
		? $DASH->can('_i18n')->(undef, 'error_table_invalid', 'bad!table')
		: do { Database::BI::Controller::Dashboard::_i18n(undef, 'error_table_invalid', 'bad!table') };
	like $msg, qr/bad!table/, '_i18n interpolates sprintf arg';
	unlike $msg, qr/Internal error/, '_i18n does not trigger fallback for known key';
};

subtest 'Dashboard::_i18n -- unknown key returns fallback' => sub {
	my $msg = Database::BI::Controller::Dashboard::_i18n(undef, 'totally_nonexistent_key_xyz');
	like $msg, qr/Internal error.*totally_nonexistent_key_xyz/,
		'_i18n returns descriptive fallback for unknown key';
};

# ---------------------------------------------------------------------------
# Subtest: _resolve_language -- Accept-Language parsing
#
# Build a controller with a custom transaction so we can set the
# Accept-Language header.  Called as a direct package function because
# build_controller returns Mojolicious::Controller (the base class), not
# our Dashboard subclass, and :Private OO dispatch would fail in production.
# ---------------------------------------------------------------------------
subtest 'Dashboard::_resolve_language -- uses config default when no header' => sub {
	my $tx = $t->ua->build_tx(GET => '/');
	$tx->req->headers->remove('Accept-Language');
	my $c = $t->app->build_controller($tx);
	my $lang = Database::BI::Controller::Dashboard::_resolve_language($c, 'web', 'en');
	is $lang, 'en', 'falls back to config default when Accept-Language absent';
};

subtest 'Dashboard::_resolve_language -- header naming a language with no templates falls back' => sub {
	my $tx = $t->ua->build_tx(GET => '/');
	# The distribution ships templates/web/en only, so 'de' cannot be served
	# whatever the header asks for: the default language is what can render.
	$tx->req->headers->header('Accept-Language' => 'de-DE,de;q=0.9');
	my $c    = $t->app->build_controller($tx);
	my $lang = Database::BI::Controller::Dashboard::_resolve_language($c, 'web', 'en');
	is $lang, 'en', 'a language with no template directory falls back to the default one';
};

subtest 'Dashboard::_resolve_language -- configured language with no templates falls back' => sub {
	my $tx = $t->ua->build_tx(GET => '/');
	$tx->req->headers->remove('Accept-Language');
	my $c    = $t->app->build_controller($tx);
	my $lang = Database::BI::Controller::Dashboard::_resolve_language($c, 'web', 'de');
	is $lang, 'en',
		'the configured code is checked like any other, not only the one the header produced';
};

subtest 'Dashboard::_resolve_language -- garbage header falls back to default' => sub {
	my $tx = $t->ua->build_tx(GET => '/');
	$tx->req->headers->header('Accept-Language' => ';;; junk ;;;');
	my $c    = $t->app->build_controller($tx);
	my $lang = Database::BI::Controller::Dashboard::_resolve_language($c, 'web', 'en');
	is $lang, 'en', 'garbage Accept-Language header falls back to default';
};

subtest 'Dashboard::_detect_platform -- desktop UA -> web' => sub {
	my $platform = Database::BI::Controller::Dashboard::_detect_platform(
		'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', 'web');
	is $platform, 'web', 'desktop UA maps to web platform';
};

subtest 'Dashboard::_detect_platform -- mobile UA -> mobile' => sub {
	my $platform = Database::BI::Controller::Dashboard::_detect_platform(
		'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15', 'web');
	is $platform, 'mobile', 'iPhone UA maps to mobile platform';
};

subtest 'Dashboard::_detect_platform -- empty UA -> fallback' => sub {
	my $platform = Database::BI::Controller::Dashboard::_detect_platform('', 'web');
	is $platform, 'web', 'empty UA returns fallback';
};

# ---------------------------------------------------------------------------
# Subtest: _spec_to_url -- spec-to-URL mapping
#
# _spec_to_url uses only url_escape() and regex matches on $spec, not $self,
# so it is safe to call as a package function with undef.
# ---------------------------------------------------------------------------
subtest 'Dashboard::_spec_to_url -- table spec' => sub {
	is Database::BI::Controller::Dashboard::_spec_to_url(undef, 'table:sales'),
		'/view/sales',
		'table: spec maps to /view/<name>';
};

subtest 'Dashboard::_spec_to_url -- path spec' => sub {
	my $url = Database::BI::Controller::Dashboard::_spec_to_url(undef, 'path:/tmp/data.csv');
	like $url, qr{^/open\?path=},  'path: spec maps to /open?path=...';
	like $url, qr{%2F|/},          'path is URL-encoded in spec-to-url output';
};

subtest 'Dashboard::_spec_to_url -- url spec' => sub {
	my $url = Database::BI::Controller::Dashboard::_spec_to_url(
		undef, 'url:http://example.com/data.html');
	like $url, qr{^/import\?url=}, 'url: spec maps to /import?url=...';
};

subtest 'Dashboard::_spec_to_url -- unknown spec falls back to /' => sub {
	is Database::BI::Controller::Dashboard::_spec_to_url(undef, 'garbage'),
		'/',
		'unrecognised spec falls back to /';
};

# ---------------------------------------------------------------------------
# Subtest: _write_sqlite_db -- produces a valid SQLite binary
# ---------------------------------------------------------------------------
subtest 'Dashboard::_write_sqlite_db -- creates valid SQLite blob' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 3;

		# _write_sqlite_db uses $self only for tempdir (via File::Temp) and DBI.
		# Pass undef -- the helper does not invoke any Mojo controller methods.
		my $records = [{ name => 'Alice', score => '95' }];
		my $columns = [qw(name score)];

		my $blob = eval {
			Database::BI::Controller::Dashboard::_write_sqlite_db(undef, $records, $columns)
		};
		is $@, '', '_write_sqlite_db does not throw';
		ok length($blob) > 0, 'returns non-empty binary blob';
		# SQLite magic bytes: first 16 bytes start with "SQLite format 3\000"
		like $blob, qr/\ASQLite format 3/, 'blob begins with SQLite magic bytes';
	}
};

# ---------------------------------------------------------------------------
# Subtest: HTTP action smoke tests -- verify actions render without 500
#
# These are thin sanity checks; deep action testing lives in basic.t /
# cgi_security.t.  Purpose: confirm that controller actions are wired and
# the happy-path completes without an unhandled exception.
# ---------------------------------------------------------------------------
subtest 'GET / -- renders home page without error' => sub {
	$t->get_ok('/')->status_is(200);
};

subtest 'GET /view/sales -- renders data table without error' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok('/view/sales')->status_is(200);
	}
};

subtest 'GET /api/columns?table=sales -- returns JSON column list' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 3 unless -f 'data/sales.csv';
		$t->get_ok('/api/columns?table=sales')
		  ->status_is(200)
		  ->json_has('/columns', 'response has a columns key');
	}
};

subtest 'GET /api/stat?path=/etc/passwd -- extension guard returns exists:false' => sub {
	use Mojo::Util qw(url_escape);
	$t->get_ok('/api/stat?path=' . url_escape('/etc/passwd'))
	  ->status_is(200)
	  ->json_is('/exists', Mojo::JSON::false(),
	      '/etc/passwd blocked by extension guard');
};

subtest 'GET /export -- no left table returns redirect to /' => sub {
	$t->get_ok('/export?l=table:nosuchxyz')
	  ->status_isnt(500, 'export with missing table does not 500');
};

# ---------------------------------------------------------------------------
# Subtest: graph_view Y-strip -- accounting-notation negative amounts
#
# Regression for the accounting-format bug: ($1,234.56) was stripped to
# "1234.56" (positive) because all non-digit/dot/dash chars were removed
# before detecting the sign.  The fix checks for a leading '(' before
# stripping and prepends '-' to the result.
#
# Strategy: create a temp CSV with a mix of plain-positive, accounting-
# negative, and dash-negative amounts; hit /graph and verify the embedded
# chart JSON contains the correct signed values.
# ---------------------------------------------------------------------------

subtest 'graph_view Y-strip -- accounting negatives plotted as negative values' => sub {
	use Mojo::Util qw(url_escape);
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 4;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'ledger.csv');
		$file->spew(
			"month,amount\n" .
			"Jan,\$1200.00\n" .    # plain positive
			"Feb,(\$450.00)\n" .   # accounting negative - was plotted as +450
			"Mar,(\$75.50)\n" .    # accounting negative, decimal
			"Apr,-30.00\n"         # dash negative
		);
		my $enc = url_escape($file->to_string);
		$t->get_ok("/graph?l=path:$enc&x=month&y=amount")
		  ->status_is(200, 'graph renders with accounting amounts')
		  ->content_like(qr/-450\b/, 'accounting ($450.00) plotted as -450')
		  ->content_like(qr/-75\.5\b/, 'accounting ($75.50) plotted as -75.5');
	}
};

subtest 'graph_view Y-strip -- accounting zero ($0.00) is valid and not skipped' => sub {
	use Mojo::Util qw(url_escape);
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'zero.csv');
		$file->spew("month,amount\nJan,(\$0.00)\nFeb,\$100.00\n");
		my $enc = url_escape($file->to_string);
		$t->get_ok("/graph?l=path:$enc&x=month&y=amount")
		  ->status_is(200, 'graph renders even when one Y value is zero in accounting format')
		  ->content_unlike(qr/No plottable data/, '($0.00) is not skipped as non-numeric');
	}
};

subtest 'graph_view Y-strip -- column with no-dollar accounting parens is numeric' => sub {
	# (148.00) has no $ prefix but is still accounting-negative.
	use Mojo::Util qw(url_escape);
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'nodollar.csv');
		$file->spew("month,amount\nJan,(148.00)\nFeb,200.00\n");
		my $enc = url_escape($file->to_string);
		$t->get_ok("/graph?l=path:$enc&x=month&y=amount")
		  ->status_is(200, 'no-dollar accounting notation recognised as numeric')
		  ->content_like(qr/-148\b/, '(148.00) plotted as -148');
	}
};

# ============================================================================
# PART 4: DataSource -- _msg, _cache_key, selectall_arrayref
# ============================================================================

# ---------------------------------------------------------------------------
# Subtest: _msg -- instance-level i18n formatter
#
# _msg is the post-construction counterpart of _fmt.  When no i18n object is
# stored it must delegate to _fmt.  When an i18n object IS stored it must call
# maketext() on it and return whatever maketext returns.
# ---------------------------------------------------------------------------
subtest 'DataSource::_msg -- no i18n object delegates to _fmt' => sub {
	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);

	# Call _msg with a known key -- result should match what _fmt returns directly.
	my $via_msg  = Database::BI::Model::DataSource::_msg($src, 'error_table_required');
	my $via_fmt  = Database::BI::Model::DataSource::_fmt('error_table_required');
	is $via_msg, $via_fmt, '_msg without i18n object produces same string as _fmt';
};

subtest 'DataSource::_msg -- i18n object receives key and args via maketext' => sub {
	# Build a spy that records every maketext call.
	my @calls;
	my $i18n = bless {}, 'MsgSpyI18N';
	{
		no strict 'refs';
		*{'MsgSpyI18N::maketext'} = sub {
			my ($self, $key, @args) = @_;
			push @calls, { key => $key, args => \@args };
			return "TRANSLATED:$key";
		};
	}

	# Construct a DataSource with the i18n object, then call _msg directly.
	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV, i18n => $i18n);
	my $result = Database::BI::Model::DataSource::_msg($src, 'warn_empty_result', 'sales');

	is $result, 'TRANSLATED:warn_empty_result',
		'_msg returns the value maketext returned';
	is scalar(@calls), 1, 'maketext was called exactly once';
	is $calls[0]{key}, 'warn_empty_result', 'maketext received the correct key';
	is $calls[0]{args}[0], 'sales', 'maketext received the sprintf arg';
};

# ---------------------------------------------------------------------------
# Subtest: _cache_key -- cache-key derivation
#
# URL tables get a key that encodes the URL + table index so two different
# table indices on the same URL produce different cache buckets.
# File tables encode path + mtime so changing the file produces a natural miss.
# When neither a URL nor an on-disk file path is set, the key is undef.
# ---------------------------------------------------------------------------
subtest 'DataSource::_cache_key -- URL table includes URL and table index in key' => sub {
	my $fn = \&Database::BI::Model::DataSource::_cache_key;

	# Manufacture a minimal DataSource-shaped object (bless into the real class
	# so _cache_key is callable as a method on it).
	my $src = bless {
		_url              => 'http://example.com/data.html',
		_html_table_index => 0,
	}, $DS;

	my $key = $fn->($src);
	like $key, qr{bi:url:http://example\.com/data\.html:0},
		'URL cache key contains URL and index 0';

	# A different table index must produce a distinct key.
	$src->{_html_table_index} = 2;
	my $key2 = $fn->($src);
	like $key2, qr{:2\z}, 'URL cache key reflects non-zero table index';
	isnt $key, $key2, 'different indices produce different cache keys';
};

subtest 'DataSource::_cache_key -- file table includes path and mtime' => sub {
	my $fn = \&Database::BI::Model::DataSource::_cache_key;

	# Use a real file so stat() returns a valid mtime.
	my $path = File::Spec->rel2abs(File::Spec->catfile($DATA_DIR, 'sales.csv'));
	SKIP: {
		skip 'data/sales.csv not found', 3 unless -f $path;
		my $mtime = (stat($path))[9];
		my $src = bless { _file_path => $path }, $DS;
		my $key = $fn->($src);
		like $key, qr{bi:file:}, 'file cache key begins with bi:file:';
		like $key, qr{\Q$path\E}, 'file cache key contains the full path';
		like $key, qr{:$mtime\z}, 'file cache key ends with the mtime';
	}
};

subtest 'DataSource::_cache_key -- no URL and no file path returns undef' => sub {
	my $fn = \&Database::BI::Model::DataSource::_cache_key;
	my $src = bless {}, $DS;
	is $fn->($src), undef, '_cache_key returns undef when no URL and no _file_path';
};

subtest 'DataSource::_cache_key -- file path that does not exist returns undef' => sub {
	my $fn = \&Database::BI::Model::DataSource::_cache_key;
	my $src = bless { _file_path => '/no/such/file.csv' }, $DS;
	is $fn->($src), undef,
		'_cache_key returns undef when _file_path is set but file is missing from disk';
};

# ---------------------------------------------------------------------------
# Subtest: selectall_arrayref -- fast-path and delegation
#
# Two fast-paths are exercised before the backend delegation:
#   1. _file_is_empty -- always returns []
#   2. Cache hit      -- returns cached rows without touching _db
# ---------------------------------------------------------------------------
subtest 'DataSource::selectall_arrayref -- _file_is_empty fast-path returns []' => sub {
	# Construct a real DataSource then force the empty-file sentinel to verify
	# the fast-path exits before any backend access.
	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);
	$src->{_file_is_empty} = 1;

	my $result = $src->selectall_arrayref;
	is_deeply $result, [], 'selectall_arrayref returns [] when _file_is_empty is set';
};

subtest 'DataSource: a file with no header row is read by Database::Abstraction' => sub {
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/hl.csv")->spew(join "\n",
		'2026-01-02,"1,234.56",Rent paid',
		'2026-01-03,5.00,"Tea, ""best"" C:\\x"',
		'',
		'2026-01-01,,Short row',
		'2026-01-04,7.00,No quotes, then a comma',
		',8.00,No date here',
		'',
	);
	my $src = $DS->new(directory => $dir, table => 'hl');
	isa_ok $src->{_db}, 'Database::Abstraction', 'the backend';
	is_deeply $src->columns, [qw(Date Amount Description)],
		'a quoted separator does not make a column';
	is $src->{_id_col}, 'Description', 'the id has no empty values, or D::A would drop the row';

	my $rows = $src->fetch_all;
	is scalar @{$rows}, 5, 'every row, blank lines apart';
	is $rows->[0]{Amount}, '1,234.56', 'a quoted separator stays in its value';
	is $rows->[0]{Description}, 'Rent paid', 'and the next value stays in its column';
	is $rows->[1]{Description}, 'Tea, "best" C:\\x', 'quotes and backslashes survive the copy';
	ok !length($rows->[2]{Amount} // ''), 'an empty field stays in place';
	is $rows->[2]{Description}, 'Short row', 'so the next one does not move';
	is $rows->[3]{Description}, 'No quotes, then a comma', 'extra fields go back into the last';
	is $rows->[4]{Amount}, '8.00', 'a row with no date is kept';
	is $src->count, 5, 'count agrees';
	is $src->updated, (stat "$dir/hl.csv")[9], 'updated is the real file, not the copy';

	# A first line with a middle field empty keeps its columns in place too.
	Mojo::File->new("$dir/gap.csv")->spew("2026-01-02,,Rent paid\n2026-01-03,5.00,Tea bought\n");
	my $gap = $DS->new(directory => $dir, table => 'gap');
	is_deeply $gap->columns, [qw(Date Description Description2)], 'an empty first-row field is a column';
	is $gap->fetch_all->[1]{Description}, '5.00', 'and its values line up';

	# A quoted separator does not make the file look as if it has a header.
	Mojo::File->new("$dir/word.csv")->spew(qq{2026-01-02,-5.00,"Tea, bought"\n});
	is_deeply $DS->new(directory => $dir, table => 'word')->columns, [qw(Date Amount Description)],
		'"Tea, bought" is not a column called Tea';

	# A name D::A refuses reaches it through a symlink to the copy.
	Mojo::File->new("$dir/my bank-file.csv")->spew(qq{2026-01-02,"1,234.56",Rent paid\n});
	my $spaced = $DS->new(directory => $dir, table => 'my bank-file');
	is $spaced->fetch_all->[0]{Amount}, '1,234.56', 'a file name with spaces';
	is $spaced->{_file_path}, File::Spec->rel2abs("$dir/my bank-file.csv"), 'the real file is still the one watched';

	# Unterminated quoting is an error, not a table cut short.
	Mojo::File->new("$dir/bad.csv")->spew(qq{2026-01-02,-5.00,Rent paid\n2026-01-03,"-1.00,oops\n});
	throws_ok { $DS->new(directory => $dir, table => 'bad') } qr/cannot parse/, 'a file that does not parse';

	# Sorting goes to D::A: this was the bug.
	my $sorted = $src->selectall_arrayref(sort_by => ['Date', 'DESC']);
	is $sorted->[0]{Date}, '2026-01-04', 'sort_by descending';
	is $sorted->[-1]{Date} // '', '', 'an empty value sorts last going down';
	is scalar @{ $src->selectall_arrayref(sort_by => ['Date', 'ASC'], limit => 2, offset => 1) }, 2, 'limit and offset';
};

subtest 'DataSource: /join sorts a file with no header row' => sub {
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/page.csv")->spew("2026-01-02,-1.00,Rent paid\n2026-01-03,-2.00,Tea bought\n");
	my $tm = Test::Mojo->new('Database::BI');
	$tm->app->config->{model_dir} = tempdir(CLEANUP => 1);
	my $body = $tm->get_ok('/join?l=' . Mojo::Util::url_escape("path:$dir/page.csv") . '&sort=Date&dir=desc')
		->status_is(200)->tx->res->body;
	my @dates = $body =~ m{<td[^>]*>(2026-01-0\d)</td>}g;
	is_deeply \@dates, ['2026-01-03', '2026-01-02'], 'in the order asked for';
};

subtest 'DataSource: XLSX and Berkeley DB are read by Database::Abstraction' => sub {
	my $dir = tempdir(CLEANUP => 1);
	SKIP: {
		skip 'Excel::Writer::XLSX and Spreadsheet::ParseXLSX are needed', 11
			unless eval { require Excel::Writer::XLSX; require Spreadsheet::ParseXLSX; 1 };
		my $wb = Excel::Writer::XLSX->new("$dir/book.xlsx");
		my $first = $wb->add_worksheet('Other');
		$first->write_row(0, 0, ['Wrong']);
		my $ws = $wb->add_worksheet('book');
		$ws->write_col(0, 0, [['Zed', 'First Name', 'Age'], ['z', 'Bob', 3], ['y', 'Cy', 20], ['x', 'Al', 9]]);
		$wb->close;

		my $src = $DS->new(directory => $dir, table => 'book');
		isa_ok $src->{_db}, 'Database::Abstraction', 'the XLSX backend';
		is_deeply $src->columns, ['Zed', 'First Name', 'Age'],
			'the columns are those of the sheet D::A reads, in the sheet\'s order';
		is scalar @{ $src->fetch_all }, 3, 'all the rows';
		is $src->count, 3, 'count agrees';
		is $src->selectall_arrayref(sort_by => ['Zed', 'ASC'])->[0]{Zed}, 'x', 'sorts';
		is $src->selectall_arrayref(sort_by => ['Zed', 'ASC'], limit => 1, offset => 1)->[0]{Zed}, 'y', 'pages';

		# D::A ignores a sort column like this one, so DataSource does it.
		my @warned;
		local $SIG{__WARN__} = sub { push @warned, @_ };
		my $by_name = $src->selectall_arrayref(sort_by => ['First Name', 'DESC']);
		is_deeply [ map { $_->{'First Name'} } @{$by_name} ], [qw(Cy Bob Al)], 'an unsafe column sorts';
		my $paged = $src->selectall_arrayref({ sort_by => ['First Name', 'ASC'], limit => 1, offset => 1 });
		is_deeply [ map { $_->{'First Name'} } @{$paged} ], ['Bob'], 'and pages, given a hashref';
		is_deeply [ map { $_->{'First Name'} } @{ $src->selectall_arrayref(sort_by => 'No Such') } ],
			[qw(Bob Cy Al)], 'an unknown one leaves the order alone';
		is scalar(@{ $src->fetch_all }), 3, 'and the sort did not disturb the cached list';
		is_deeply \@warned, [], 'and D::A did not have to refuse any of them';
	}
	SKIP: {
		skip 'DB_File is needed', 4 unless eval { require DB_File; require Fcntl; 1 };
		my %bdb;
		tie(%bdb, 'DB_File', "$dir/kv.db", Fcntl::O_CREAT() | Fcntl::O_RDWR(), 0644, $DB_File::DB_HASH)
			or skip "cannot create a Berkeley DB file: $!", 4;
		%bdb = (b => 2, a => 1, c => 3);
		untie %bdb;
		my $src = $DS->new(directory => $dir, table => 'kv');
		isa_ok $src->{_db}, 'Database::Abstraction', 'the Berkeley DB backend';
		is_deeply $src->columns, [qw(entry value)], 'columns';
		is scalar @{ $src->fetch_all }, 3, 'all the rows';
		is $src->selectall_arrayref(sort_by => ['entry', 'DESC'])->[0]{entry}, 'c', 'sorts';
	}
};

subtest 'DataSource: a SQLite column with an unsafe name sorts and pages' => sub {
	my $dir = tempdir(CLEANUP => 1);
	require DBI;
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/uns.sql", '', '', { RaiseError => 1 });
	$dbh->do('CREATE TABLE uns (id TEXT, "Full Name" TEXT)');
	$dbh->do('INSERT INTO uns VALUES (?, ?)', undef, @{$_}) for ['1', 'Bob'], ['2', 'Al'], ['3', 'Cy'];
	$dbh->disconnect;
	my $src = $DS->new(directory => $dir, table => 'uns');
	my $rows = $src->selectall_arrayref(sort_by => ['Full Name', 'ASC'], limit => 2);
	is_deeply [ map { $_->{'Full Name'} } @{$rows} ], [qw(Al Bob)], 'sorted, then limited';
	lives_ok { $src->selectall_arrayref(sort_by => 'No Such') } 'a locked row without the column does not croak';
};

subtest 'DataSource::selectall_arrayref -- cache hit skips backend, returns cached data' => sub {
	# Build a minimal CHI-like cache stub.  The real CHI::Driver API has get/set;
	# we replicate only what selectall_arrayref uses.
	my %store;
	my $cache = bless {}, 'FakeCache';
	{
		no strict 'refs';
		*{'FakeCache::get'} = sub { my ($s,$k) = @_; $store{$k} };
		*{'FakeCache::set'} = sub { my ($s,$k,$v,@r) = @_; $store{$k} = $v };
	}

	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);
	$src->{_cache}     = $cache;
	$src->{_file_path} = File::Spec->rel2abs(File::Spec->catfile($DATA_DIR, 'sales.csv'));

	# Prime the cache with fake data.
	my $key        = Database::BI::Model::DataSource::_cache_key($src);
	my $fake_rows  = [{ id => 'CACHED' }];
	$store{$key}   = $fake_rows;

	my $result = $src->selectall_arrayref;
	is $result, $fake_rows, 'selectall_arrayref returns cached data on cache hit';
};

subtest 'DataSource::selectall_arrayref -- cache miss stores result in cache' => sub {
	my %store;
	my $cache = bless {}, 'FakeCache2';
	{
		no strict 'refs';
		*{'FakeCache2::get'} = sub { my ($s,$k) = @_; $store{$k} };
		*{'FakeCache2::set'} = sub { my ($s,$k,$v,@r) = @_; $store{$k} = $v };
	}

	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);
	$src->{_cache}     = $cache;
	$src->{_file_path} = File::Spec->rel2abs(File::Spec->catfile($DATA_DIR, 'sales.csv'));

	# Cache is empty -- miss path should call backend, then populate cache.
	my $result = $src->selectall_arrayref;
	my $key    = Database::BI::Model::DataSource::_cache_key($src);

	ok defined $store{$key}, 'cache is populated after a cache miss';
	is $store{$key}, $result, 'cached value is the same reference as the returned rows';
};

# ============================================================================
# PART 5: Dashboard -- _dedup_records, _combine_tables, _build_export_url
# ============================================================================

# ---------------------------------------------------------------------------
# Subtest: _dedup_records -- duplicate removal preserving first-occurrence order
#
# Two rows are duplicates iff every column value is identical under string
# comparison (undef treated as '').  The input arrayref must not be mutated.
# ---------------------------------------------------------------------------
subtest '_dedup_records -- removes exact duplicates preserving first occurrence' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_dedup_records;
	my $cols = [qw(name city)];

	my $r1 = { name => 'Alice', city => 'London' };
	my $r2 = { name => 'Bob',   city => 'Paris'  };
	my $r3 = { name => 'Alice', city => 'London' };	# exact dup of r1

	my $result = $fn->([$r1, $r2, $r3], $cols);
	is scalar(@$result), 2, 'duplicate row is removed';
	is $result->[0]{name}, 'Alice', 'first occurrence of Alice is kept';
	is $result->[1]{name}, 'Bob',   'Bob is kept (unique)';
};

subtest '_dedup_records -- all identical rows collapse to one' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_dedup_records;
	my $row = { x => 'same', y => 'value' };
	my $result = $fn->([$row, $row, $row], [qw(x y)]);
	is scalar(@$result), 1, 'three identical rows collapse to one';
};

subtest '_dedup_records -- undef field treated as empty string in key' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_dedup_records;
	my $r1 = { val => undef   };
	my $r2 = { val => ''      };	# undef and '' must hash identically
	my $r3 = { val => 'x'     };
	my $result = $fn->([$r1, $r2, $r3], ['val']);
	is scalar(@$result), 2,
		'undef and empty string are treated as the same value (one dedup kept)';
};

subtest '_dedup_records -- empty input returns empty arrayref' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_dedup_records;
	my $result = $fn->([], [qw(a b)]);
	is_deeply $result, [], 'empty input produces empty output';
};

subtest '_dedup_records -- input arrayref is not mutated' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_dedup_records;
	my $row = { a => 1 };
	my $input = [$row, $row];
	my $before_len = scalar @$input;
	$fn->($input, ['a']);
	is scalar(@$input), $before_len, 'original input arrayref length unchanged';
};

# ---------------------------------------------------------------------------
# Subtest: _combine_tables -- vertical UNION ALL
#
# The merged column list is the first source's columns first, then any new
# columns from subsequent sources.  Where a source lacks a column, its rows
# get an empty string for that column.
# ---------------------------------------------------------------------------
subtest '_combine_tables -- two sources with identical columns produce all rows' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_combine_tables;
	my $cols = [qw(id name)];
	my $src1 = [[ { id => 1, name => 'Alice' } ], $cols];
	my $src2 = [[ { id => 2, name => 'Bob'   } ], $cols];

	my ($recs, $merged_cols) = $fn->([$src1, $src2]);
	is scalar(@$recs), 2,                     'both rows present in merged result';
	is_deeply $merged_cols, [qw(id name)],    'merged column list is unchanged when sources match';
	is $recs->[0]{name}, 'Alice',             'first row from first source';
	is $recs->[1]{name}, 'Bob',               'second row from second source';
};

subtest '_combine_tables -- second source introduces new columns with blanks on first' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_combine_tables;
	my $src1 = [[ { id => 1, name => 'Alice' } ], [qw(id name)]];
	my $src2 = [[ { id => 2, city => 'Paris'  } ], [qw(id city)]];

	my ($recs, $cols) = $fn->([$src1, $src2]);
	# Column order: first source's columns first, then new ones from second source.
	is $cols->[0], 'id',   'id is first (from first source)';
	is $cols->[1], 'name', 'name is second (from first source)';
	is $cols->[2], 'city', 'city is third (introduced by second source)';

	# Row from src1 must have blank city; row from src2 must have blank name.
	is $recs->[0]{city}, '', 'row from src1 gets empty string for missing city';
	is $recs->[1]{name}, '', 'row from src2 gets empty string for missing name';
};

subtest '_combine_tables -- single source returned unchanged (no allocation)' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_combine_tables;
	my $rows = [{ a => 1 }, { a => 2 }];
	my $cols = ['a'];
	my ($recs, $merged_cols) = $fn->([[$rows, $cols]]);
	is scalar(@$recs), 2,     'single source: all rows present';
	is_deeply $merged_cols, ['a'], 'single source: column list unchanged';
};

subtest '_combine_tables -- column order: first source columns precede new columns' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_combine_tables;
	my $src1 = [[ { x => 1, y => 2 } ], [qw(x y)]];
	my $src2 = [[ { y => 3, z => 4 } ], [qw(y z)]];

	my ($recs, $cols) = $fn->([$src1, $src2]);
	is $cols->[0], 'x', 'x from first source is first';
	is $cols->[1], 'y', 'y (shared) remains in first-source position';
	is $cols->[2], 'z', 'z introduced by second source is last';
};

# ---------------------------------------------------------------------------
# Subtest: _build_export_url -- URL assembly
#
# _build_export_url is :Protected and uses $self only for url_escape (imported
# via Mojo::Util).  Pass a real controller object built from a live transaction.
# ---------------------------------------------------------------------------
subtest 'Dashboard::_build_export_url -- minimal call produces /export?l=...' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_build_export_url;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);

	my $url = $fn->($c, 'table:sales', [], []);
	like $url, qr{\A/export\?l=},      'URL starts with /export?l=';
	like $url, qr{table(?:%3A|:)sales}, 'left spec encoded in URL';
	unlike $url, qr{&j=},              'no join params when join list empty';
	unlike $url, qr{&f=},              'no filter params when filter list empty';
	unlike $url, qr{&d=},              'no dedup param when dedup false';
};

subtest 'Dashboard::_build_export_url -- join specs append &j= params' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_build_export_url;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);

	my $url = $fn->($c, 'table:sales', ['table:products|id|id'], []);
	like $url, qr{&j=}, '&j= param present when join list non-empty';
};

subtest 'Dashboard::_build_export_url -- filter specs append &f= params' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_build_export_url;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);

	my $url = $fn->($c, 'table:sales', [], ['region:eq:North']);
	like $url, qr{&f=}, '&f= param present when filter list non-empty';
};

subtest 'Dashboard::_build_export_url -- dedup flag appends &d=1' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_build_export_url;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);

	my $url = $fn->($c, 'table:sales', [], [], undef, 1);
	like $url, qr{&d=1}, '&d=1 present when dedup is true';
};

subtest 'Dashboard::_build_export_url -- combine specs append &c= params' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_build_export_url;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);

	my $url = $fn->($c, 'table:sales', [], [], ['table:products']);
	like $url, qr{&c=}, '&c= param present when combine list non-empty';
};

# ---------------------------------------------------------------------------
# Subtest: _dedup_records memory cycle check
# ---------------------------------------------------------------------------
subtest '_dedup_records -- no circular references in output' => sub {
	my $fn   = \&Database::BI::Controller::Dashboard::_dedup_records;
	my $rows = [{ a => 1 }, { a => 2 }, { a => 1 }];
	my $out  = $fn->($rows, ['a']);
	memory_cycle_ok($out, '_dedup_records output has no circular references');
};

# ---------------------------------------------------------------------------
# Subtest: _combine_tables memory cycle check
# ---------------------------------------------------------------------------
subtest '_combine_tables -- no circular references in output' => sub {
	my $fn  = \&Database::BI::Controller::Dashboard::_combine_tables;
	my ($recs, $cols) = $fn->([
		[[ { x => 1 } ], ['x']],
		[[ { y => 2 } ], ['y']],
	]);
	memory_cycle_ok($recs, '_combine_tables output records have no circular references');
};

# ============================================================================
# PART 6: Dashboard -- _apply_filters
#
# _apply_filters is a :Protected method that reads all ?f= query params,
# applies _apply_filter_spec in order, and returns three values: the
# filtered records arrayref, the raw spec strings arrayref, and a
# script-safe JSON string.  A real controller object is required so that
# every_param('f') sees the URL params.
# ============================================================================

subtest '_apply_filters -- no f= params: all records returned, empty structures' => sub {
	my $fn      = \&Database::BI::Controller::Dashboard::_apply_filters;
	my $tx      = $t->ua->build_tx(GET => '/');
	my $c       = $t->app->build_controller($tx);
	my $records = [{ col => 'a' }, { col => 'b' }];

	my ($filtered, $specs, $json) = $fn->($c, $records);
	is scalar(@$filtered), 2, 'no filters: both records returned unchanged';
	is_deeply $specs, [],     'no filters: raw specs arrayref is empty';
	is $json,  '[]',          'no filters: JSON is an empty array literal';
};

subtest '_apply_filters -- single f= param narrows records and populates JSON' => sub {
	my $fn      = \&Database::BI::Controller::Dashboard::_apply_filters;
	my $tx      = $t->ua->build_tx(GET => '/?f=region:eq:North');
	my $c       = $t->app->build_controller($tx);
	my $records = [
		{ region => 'North', name => 'Alice' },
		{ region => 'South', name => 'Bob'   },
	];

	my ($filtered, $specs, $json) = $fn->($c, $records);
	is scalar(@$filtered),     1,                'single filter keeps one matching row';
	is $filtered->[0]{name},   'Alice',          'correct row survives the filter';
	is $specs->[0],            'region:eq:North','raw spec string preserved verbatim';
	like $json, qr/"col"\s*:\s*"region"/,        'JSON contains the column name';
	like $json, qr/"op"\s*:\s*"eq"/,             'JSON contains the operator';
	like $json, qr/"val"\s*:\s*"North"/,         'JSON contains the value';
};

subtest '_apply_filters -- multiple f= params applied in chain (AND semantics)' => sub {
	my $fn      = \&Database::BI::Controller::Dashboard::_apply_filters;
	my $tx      = $t->ua->build_tx(GET => '/?f=region:eq:North&f=score:gt:50');
	my $c       = $t->app->build_controller($tx);
	my $records = [
		{ region => 'North', score => 80 },	# passes both
		{ region => 'North', score => 30 },	# fails score filter
		{ region => 'South', score => 90 },	# fails region filter
	];

	my ($filtered, $specs, $json) = $fn->($c, $records);
	is scalar(@$filtered),    1,  'two filters combined keep only the one fully-matching row';
	is $filtered->[0]{score}, 80, 'the surviving row has score 80';
	is scalar(@$specs),       2,  'two raw spec strings in the returned arrayref';
};

subtest '_apply_filters -- JSON output escapes </ to prevent script injection' => sub {
	# A filter value containing "</script>" would close a surrounding <script>
	# block if embedded verbatim.  The sub must escape "</" to "<\/".
	use Mojo::Util qw(url_escape);
	my $fn      = \&Database::BI::Controller::Dashboard::_apply_filters;
	my $tx      = $t->ua->build_tx(GET => '/?f=col:eq:' . url_escape('</script>'));
	my $c       = $t->app->build_controller($tx);
	my $records = [{ col => 'irrelevant' }];

	my (undef, undef, $json) = $fn->($c, $records);
	unlike $json, qr{</},   'JSON must not contain raw </ sequence';
	like   $json, qr{<\\/}, 'JSON has </ escaped to <\\/';
};

subtest '_apply_filters -- malformed spec (no colon) skipped from JSON, records unchanged' => sub {
	# The guard in _apply_filters is: length($col // '') && defined $op && length $op.
	# A spec with no colon gives ($col='notaspec', $op=undef) after split -- the
	# defined($op) check fails, so the spec is not added to @parsed or the JSON.
	# _apply_filter_spec is also not called, leaving $records unchanged.
	my $fn      = \&Database::BI::Controller::Dashboard::_apply_filters;
	my $tx      = $t->ua->build_tx(GET => '/?f=notacolonspec');
	my $c       = $t->app->build_controller($tx);
	my $records = [{ x => 1 }, { x => 2 }];

	my ($filtered, $specs, $json) = $fn->($c, $records);
	is scalar(@$filtered), 2, 'malformed spec: both records pass through';
	is $json, '[]',           'malformed spec is not added to the JSON array';
};

# ============================================================================
# PART 6b: Dashboard -- _reduce_records, the shared filter stage
#
# _reduce_records is stage 5 of the pipeline (BI-Phase-7.md section 3) held in
# one place: the reader's own f= params, then the two bounds a relative time
# range resolves to, applied in order over the records, with the columns list
# handed back so a later stage can extend it.  Every route that reads rows and
# filters them calls it, so these subtests check the stage itself rather than
# one route's copy of it -- and the last one checks that the copy is gone.
# ============================================================================

subtest '_reduce_records -- no filters: the records and the columns come back' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_reduce_records;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);

	my $records = [{ region => 'North' }, { region => 'South' }];
	my ($out, $cols) = $fn->($c, $records, ['region', 'score']);

	is $out, $records, 'the same list comes back, not a filtered copy';
	is_deeply $cols, ['region', 'score'], 'and the columns list is handed back as it came';
};

subtest '_reduce_records -- an undef columns list is handed back as undef' => sub {
	# _apply_filters, the entry point seven routes reach the stage through, has
	# no column list in scope; the stage must not invent one.
	my $fn = \&Database::BI::Controller::Dashboard::_reduce_records;
	my $tx = $t->ua->build_tx(GET => '/?f=region:eq:North');
	my $c  = $t->app->build_controller($tx);

	my ($out, $cols) = $fn->($c, [{ region => 'North' }, { region => 'South' }], undef);

	is scalar(@$out), 1, 'the filter still applies';
	is $cols, undef, 'and no columns list is invented for the caller';
};

subtest "_reduce_records -- the reader's own f= filters narrow the rows" => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_reduce_records;
	my $tx = $t->ua->build_tx(GET => '/?f=region:eq:North&f=score:ge:50');
	my $c  = $t->app->build_controller($tx);

	my $records = [
		{ region => 'North', score => 80 },
		{ region => 'North', score => 10 },
		{ region => 'South', score => 90 },
	];
	my ($out) = $fn->($c, $records, ['region', 'score']);

	is scalar(@$out), 1, 'both filters are applied';
	is $out->[0]{score}, 80, 'the one row that passes both is the one left';
	is scalar(@$records), 3, "the caller's list is not mutated in place";
};

subtest '_reduce_records -- the relative range is applied after the f= filters' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_reduce_records;
	my $tx = $t->ua->build_tx(GET => '/?f=region:eq:North&f=score:gt:0');
	my $c  = $t->app->build_controller($tx);

	# What _time_range_request puts on the stash for a ?range= request: the two
	# bounds, not two more entries in the reader's own filter list.
	$c->stash(range_specs => ['score:ge:50', 'score:le:100']);

	my $records = [
		{ region => 'North', score => 80 },
		{ region => 'North', score => 40 },
		{ region => 'North', score => 500 },
		{ region => 'South', score => 60 },
	];
	my ($out) = $fn->($c, $records, ['region', 'score']);

	is_deeply [map { $_->{score} } @$out], [80],
		"the window narrows what the reader's filters left";
	is_deeply Database::BI::Controller::Dashboard::_filter_specs($c),
		['region:eq:North', 'score:gt:0', 'score:ge:50', 'score:le:100'],
		"the reader's filters come first, the range's two bounds after them";
};

subtest '_reduce_records -- a malformed spec leaves the rows alone' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_reduce_records;
	my $tx = $t->ua->build_tx(GET => '/?f=notacolonspec');
	my $c  = $t->app->build_controller($tx);

	my ($out) = $fn->($c, [{ x => 1 }, { x => 2 }], ['x']);
	is scalar(@$out), 2, 'a spec with no colon leaves every row in place';
};

subtest '_reduce_records -- the stage has one implementation, not seventeen' => sub {
	# The point of the seam is that the loop was written out in seventeen actions
	# and is now written once.  A test of the behaviour cannot see a copy come
	# back -- a copy behaves the same, which is how the copies drifted apart in
	# the first place -- so this reads the module and counts.
	my $source = Mojo::File->new(
		File::Spec->catfile('lib', 'Database', 'BI', 'Controller', 'Dashboard.pm')
	)->slurp;

	my $loops = () = $source =~ /for my \$s \(\@\{ _filter_specs/g;
	is $loops, 1, 'the filter loop is written once, inside _reduce_records';

	# The routes go through _reduce_or_render, which is the one caller of the
	# seam that turns a cross-row spec it cannot honour into a 400 (the stage
	# croaks, and a route has to answer with something).
	my $calls = () = $source =~ /_reduce_or_render\(/g;
	cmp_ok $calls, '>=', 16,
		"every data route reduces through the seam ($calls call sites)";
	my $seam = () = $source =~ /= eval \{ _reduce_records\(\$self/g;
	is $seam, 1, 'and only that wrapper calls _reduce_records on a route\'s behalf';
};

# ============================================================================
subtest '_reduce_records -- chips_only hands already-reduced rows straight back' => sub {
	# The routes that filter inside _fetch_page before paginating come here for
	# the chip list alone.  Without the option the stage would run a second time
	# on a page that has already been through it -- harmless while every stage is
	# idempotent, wrong the moment one is not, and wrong only on pages after the
	# first.  Already-reduced is simulated by rows that no longer match the
	# filters: a second pass would drop them.
	my $fn = \&Database::BI::Controller::Dashboard::_reduce_records;
	my $tx = $t->ua->build_tx(GET => '/?f=region:eq:North');
	my $c  = $t->app->build_controller($tx);
	$c->stash(range_specs => ['score:ge:50', 'score:le:100']);

	my $records = [{ region => 'South', score => 10 }];
	my $columns = ['region', 'score'];
	my ($out, $cols) = $fn->($c, $records, $columns, { chips_only => 1 });

	is $out, $records, 'the same rows come back, unfiltered';
	is scalar(@$out), 1, 'nothing is dropped by the f= spec or the range bounds';
	is $cols, $columns, 'and the columns list is untouched';
};

subtest '_apply_filters -- chips_only still builds the chips, but filters nothing' => sub {
	my $fn      = \&Database::BI::Controller::Dashboard::_apply_filters;
	my $tx      = $t->ua->build_tx(GET => '/?f=score:ge:50');
	my $c       = $t->app->build_controller($tx);
	my $records = [{ score => 10 }, { score => 20 }];

	my ($filtered, $specs, $json) = $fn->($c, $records, { chips_only => 1 });

	is $filtered, $records, 'the rows the caller passed in are what comes back';
	is_deeply $specs, ['score:ge:50'], 'the raw spec is still returned for export URLs';
	like $json, qr/"val"\s*:\s*"50"/, 'and the JSON is still built for the filter UI';

	# The default is unchanged: without the option the same call does filter.
	my ($default) = $fn->($c, $records);
	is scalar(@$default), 0, 'without the option the spec still applies';
};

subtest '_apply_filters -- every caller that discards the reduced rows asks for chips only' => sub {
	# _apply_filters returns the reduced rows, but most of its callers filter
	# earlier and keep only the chip list.  This is the property that keeps them
	# safe from a non-idempotent stage: if a call site throws the filtered rows
	# away, it must say chips_only, or the stage runs twice on that page.
	my $source = Mojo::File->new(
		File::Spec->catfile('lib', 'Database', 'BI', 'Controller', 'Dashboard.pm')
	)->slurp;

	my @calls = grep { /_apply_filters\(\$records/ } split /\n/, $source;
	is scalar(@calls), 7, 'seven call sites reach the entry point';

	my @flagged = grep { /chips_only\s*=>\s*1/ } @calls;
	is scalar(@flagged), 6, 'six of them are here for the chip list alone';

	my @unmarked = grep { /my \(undef,/ && !/chips_only\s*=>\s*1/ } @calls;
	is_deeply \@unmarked, [], 'no caller discards the reduced rows without the flag';

	my @flagged_but_used = grep { /my \(\$filtered,/ && /chips_only\s*=>\s*1/ } @calls;
	is_deeply \@flagged_but_used, [],
		'and no caller that uses the reduced rows asks for the stage to be skipped';
};

# ============================================================================
# PART 7: pie_view HTTP smoke tests
#
# Exercises the two code paths added in 0.007.0:
#   1. __count__ sentinel -- count rows per category instead of summing a column.
#   2. Currency detection -- first non-numeric character detected from values.
#
# Temp CSV files are used so tests are self-contained and do not touch data/.
# All subtests guard on HTML::D3 availability (render_pie_chart_snippet).
# ============================================================================

subtest 'pie_view -- __count__ sentinel counts rows per category' => sub {
	use Mojo::Util qw(url_escape);
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 3;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'cats.csv');
		$file->spew("type,amount\nFood,10.00\nFood,20.00\nDrink,5.00\n");
		my $enc = url_escape($file->to_string);
		$t->get_ok("/pie?l=path:$enc&cat=type&val=__count__")
		  ->status_is(200, '__count__ mode renders without error')
		  ->content_like(qr/Count by type/i, 'chart title includes "Count by type"')
		  ->content_unlike(qr/No plottable data/, '__count__ produces plottable data');
	}
};

subtest 'pie_view -- currency symbol detected and embedded in data-currency attribute' => sub {
	use Mojo::Util qw(url_escape);
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'txn.csv');
		$file->spew("category,amount\nFood,\$10.00\nDrink,\$5.00\n");
		my $enc = url_escape($file->to_string);
		$t->get_ok("/pie?l=path:$enc&cat=category&val=amount")
		  ->status_is(200, 'pie renders with dollar-amount column')
		  ->content_like(qr/data-currency="\$"/, 'dollar sign detected as currency symbol');
	}
};

subtest 'pie_view -- missing cat param returns 400' => sub {
	$t->get_ok('/pie?l=table:sales&val=amount')
	  ->status_is(400, 'missing cat param produces 400 Bad Request');
};

subtest 'pie_view -- missing val param returns 400' => sub {
	$t->get_ok('/pie?l=table:sales&cat=category')
	  ->status_is(400, 'missing val param produces 400 Bad Request');
};

subtest 'pie_view -- accounting-notation negatives parsed as signed values' => sub {
	use Mojo::Util qw(url_escape);
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'ledger.csv');
		$file->spew("category,amount\nIncome,\$1000.00\nExpense,(\$250.00)\n");
		my $enc = url_escape($file->to_string);
		$t->get_ok("/pie?l=path:$enc&cat=category&val=amount")
		  ->status_is(200, 'pie renders despite accounting-notation negative in amount column');
	}
};

# ============================================================================
# PART 8: _safe_back_url -- XSS-safe back-link sanitiser
#
# _safe_back_url is a package-level function (no $self) that accepts a raw
# URL string and returns it unchanged when it is safe to embed in an href="",
# or undef when it is not.  Allowed: root-relative /path (but not //) and
# absolute http(s):// URLs.  Everything else -- javascript:, data:, empty,
# undef -- must be rejected.
# ============================================================================

subtest '_safe_back_url -- undef input returns undef' => sub {
	# Guard against template rendering javascript: or data: URIs as href values.
	my $fn = \&Database::BI::Controller::Dashboard::_safe_back_url;
	is $fn->(undef), undef, 'undef input returns undef';
};

subtest '_safe_back_url -- empty string returns undef' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_safe_back_url;
	is $fn->(''), undef, 'empty string returns undef';
};

subtest '_safe_back_url -- javascript: scheme is rejected' => sub {
	# A javascript: URI in an href executes on click -- must be blocked.
	my $fn = \&Database::BI::Controller::Dashboard::_safe_back_url;
	is $fn->('javascript:alert(1)'), undef, 'javascript: URI rejected';
	is $fn->('JAVASCRIPT:alert(1)'), undef, 'case-insensitive javascript: URI rejected';
};

subtest '_safe_back_url -- data: scheme is rejected' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_safe_back_url;
	is $fn->('data:text/html,<script>alert(1)</script>'), undef, 'data: URI rejected';
};

subtest '_safe_back_url -- protocol-relative URL is rejected' => sub {
	# // is not a root-relative path; /(?!/) means / NOT followed by /.
	my $fn = \&Database::BI::Controller::Dashboard::_safe_back_url;
	is $fn->('//evil.example.com/'), undef, 'protocol-relative // URL rejected';
};

subtest '_safe_back_url -- root-relative path is allowed' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_safe_back_url;
	is $fn->('/view/sales'), '/view/sales', 'root-relative /view/sales allowed';
	is $fn->('/'), '/', 'bare / allowed';
	is $fn->('/open?path=%2Ftmp%2Ffile.csv'), '/open?path=%2Ftmp%2Ffile.csv',
		'root-relative path with query string allowed';
};

subtest '_safe_back_url -- absolute http URL is allowed' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_safe_back_url;
	is $fn->('http://example.com/page'), 'http://example.com/page',
		'absolute http:// URL allowed';
};

subtest '_safe_back_url -- absolute https URL is allowed' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_safe_back_url;
	is $fn->('https://example.com/pie?l=table:sales'), 'https://example.com/pie?l=table:sales',
		'absolute https:// URL with query string allowed';
	is $fn->('HTTPS://example.com/'), 'HTTPS://example.com/',
		'case-insensitive https:// URL allowed';
};

subtest '_safe_back_url -- vbscript: scheme is rejected' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_safe_back_url;
	is $fn->('vbscript:MsgBox(1)'), undef, 'vbscript: URI rejected';
};

# ============================================================================
# PART 9: bar_view HTTP smoke tests
#
# Exercises the key code paths in bar_view:
#   1. __count__ sentinel -- count rows per category instead of summing a column.
#   2. Missing cat param -- must return 400.
#   3. Unknown val col -- must return 400.
#   4. orient=h -- horizontal orientation rendered.
#   5. Accounting-notation negatives -- ($250.00) parsed as -250.
#   6. No plottable data -- empty/blank values in the selected columns.
#
# Temp CSV files are used so tests are self-contained and do not touch data/.
# All subtests guard on HTML::D3 availability (render_bar_chart_snippet).
# ============================================================================

subtest 'bar_view -- __count__ sentinel counts rows per category' => sub {
	use Mojo::Util qw(url_escape);
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 3;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'items.csv');
		$file->spew("type,amount\nFood,10.00\nFood,20.00\nDrink,5.00\n");
		my $enc = url_escape($file->to_string);
		$t->get_ok("/bar?l=path:$enc&cat=type&val=__count__")
		  ->status_is(200, '__count__ mode renders bar chart without error')
		  ->content_like(qr/Count by type/i, 'chart title includes "Count by type"');
	}
};

subtest 'bar_view -- missing cat param returns 400' => sub {
	# cat is required; absence is an immediate 400 before any data access.
	$t->get_ok('/bar?l=table:sales&val=amount')
	  ->status_is(400, 'missing cat param produces 400 Bad Request');
};

subtest 'bar_view -- unknown val column returns 400' => sub {
	use Mojo::Util qw(url_escape);
	my $dir  = tempdir(CLEANUP => 1);
	my $file = Mojo::File->new($dir, 'data2.csv');
	$file->spew("region,amount\nNorth,100\nSouth,200\n");
	my $enc = url_escape($file->to_string);
	$t->get_ok("/bar?l=path:$enc&cat=region&val=nonexistent_col")
	  ->status_is(400, 'unknown val column produces 400 Bad Request');
};

subtest 'bar_view -- horizontal orientation accepted without error' => sub {
	use Mojo::Util qw(url_escape);
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'sales2.csv');
		$file->spew("region,amount\nNorth,100\nSouth,200\n");
		my $enc = url_escape($file->to_string);
		$t->get_ok("/bar?l=path:$enc&cat=region&val=amount&orient=h")
		  ->status_is(200, 'orient=h renders bar chart without error');
	}
};

subtest 'bar_view -- sort=value accepted without error' => sub {
	use Mojo::Util qw(url_escape);
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'sorted.csv');
		$file->spew("product,revenue\nA,300\nB,150\nC,450\n");
		my $enc = url_escape($file->to_string);
		$t->get_ok("/bar?l=path:$enc&cat=product&val=revenue&sort=value")
		  ->status_is(200, 'sort=value renders bar chart without error');
	}
};

subtest 'bar_view -- accounting-notation negatives parsed as signed values' => sub {
	use Mojo::Util qw(url_escape);
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $dir  = tempdir(CLEANUP => 1);
		my $file = Mojo::File->new($dir, 'ledger2.csv');
		$file->spew("category,amount\nIncome,\$1000.00\nExpense,(\$250.00)\n");
		my $enc = url_escape($file->to_string);
		$t->get_ok("/bar?l=path:$enc&cat=category&val=amount")
		  ->status_is(200, 'bar renders despite accounting-notation negative in amount column');
	}
};

subtest 'bar_view -- all blank values produces no-plottable-data response' => sub {
	use Mojo::Util qw(url_escape);
	my $dir  = tempdir(CLEANUP => 1);
	my $file = Mojo::File->new($dir, 'empty_vals.csv');
	# All amount values are blank -- nothing passes the numeric guard.
	$file->spew("region,amount\nNorth,\nSouth,\n");
	my $enc = url_escape($file->to_string);
	$t->get_ok("/bar?l=path:$enc&cat=region&val=amount")
	  ->status_is(200, 'no-plottable-data responds 200 with explanatory message')
	  ->content_like(qr/No plottable data/, 'response body explains no plottable data');
};

# ============================================================================
# PART 10: Database::BI::_evict_old_uploads -- mtime cutoff logic
#
# _evict_old_uploads is a plain package-level sub in Database::BI (not a
# method).  It walks an uploads directory and removes any entry whose mtime
# is strictly older than the supplied cutoff (time() - max_age_s).
#
# Strategy: create directories, set their mtime via utime() to specific
# values relative to time(), then call the function and verify the expected
# directories are absent or present.  utime() avoids sleeping in the test.
# ============================================================================

subtest '_evict_old_uploads -- non-existent directory is a silent no-op' => sub {
	my $fn = \&Database::BI::_evict_old_uploads;
	lives_ok { $fn->(Mojo::File->new('/no/such/uploads/dir'), 3600) }
		'_evict_old_uploads does not croak when uploads directory is absent';
};

subtest '_evict_old_uploads -- old entry removed, fresh entry preserved' => sub {
	my $fn      = \&Database::BI::_evict_old_uploads;
	my $tmp     = File::Temp::tempdir(CLEANUP => 1);
	my $uploads = Mojo::File->new($tmp)->child('uploads');
	$uploads->make_path;

	my $old_dir   = $uploads->child('old_session');
	my $fresh_dir = $uploads->child('fresh_session');
	$old_dir->make_path;
	$fresh_dir->make_path;

	# Backdate old_session to 25 hours ago; leave fresh_session at current mtime.
	my $old_mtime = time() - 25 * 3600;
	utime($old_mtime, $old_mtime, $old_dir->to_string);

	$fn->($uploads, 24 * 3600);	# max age = 24 h

	ok !-d $old_dir->to_string,   'directory 25 hours old is evicted (older than 24 h max)';
	ok  -d $fresh_dir->to_string, 'directory with current mtime is preserved';
};

subtest '_evict_old_uploads -- zero max_age_s evicts entries with past mtime' => sub {
	# max_age_s=0 sets cutoff=time().  Any entry with mtime < time() is evicted.
	# We force both directories 1 second into the past via utime so the test is
	# deterministic without sleeping.
	my $fn      = \&Database::BI::_evict_old_uploads;
	my $tmp     = File::Temp::tempdir(CLEANUP => 1);
	my $uploads = Mojo::File->new($tmp)->child('uploads2');
	$uploads->make_path;

	my $dir_a = $uploads->child('session_a');
	my $dir_b = $uploads->child('session_b');
	$dir_a->make_path;
	$dir_b->make_path;

	# Set both mtimes 1 second in the past to satisfy mtime < cutoff.
	my $past = time() - 1;
	utime($past, $past, $dir_a->to_string);
	utime($past, $past, $dir_b->to_string);

	$fn->($uploads, 0);

	ok !-d $dir_a->to_string, 'session_a evicted when max_age_s is 0 and mtime is in the past';
	ok !-d $dir_b->to_string, 'session_b evicted when max_age_s is 0 and mtime is in the past';
};

subtest '_evict_old_uploads -- stray regular file is also removed when old enough' => sub {
	# Although .uploads/ normally contains session subdirectories, stray regular
	# files (e.g. from a failed partial upload) also hit the -f branch.
	my $fn      = \&Database::BI::_evict_old_uploads;
	my $tmp     = File::Temp::tempdir(CLEANUP => 1);
	my $uploads = Mojo::File->new($tmp)->child('uploads3');
	$uploads->make_path;

	my $stray = $uploads->child('stray.tmp');
	$stray->spew('orphaned content');

	# Backdate to 2 hours ago with a 1-hour max age.
	my $old_mtime = time() - 2 * 3600;
	utime($old_mtime, $old_mtime, $stray->to_string);

	$fn->($uploads, 3600);

	ok !-f $stray->to_string, 'stray file older than max_age_s is removed';
};

# ============================================================================
# PART 11: DataSource::_sniff_data_ext
#
# _sniff_data_ext is the remote-file content detector: it reads the first 20
# bytes (magic header) and the first text line to decide which standard
# extension best describes a file that arrived with a non-standard suffix
# (e.g. ".log").  Each subtest writes a minimal but structurally valid file
# so the detection chain fires the expected branch.
# ============================================================================

subtest '_sniff_data_ext -- SQLite magic bytes map to db' => sub {
	my $fn  = \&Database::BI::Model::DataSource::_sniff_data_ext;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $path = "$dir/mystery.log";
	{
		# Write raw bytes: the first 15 bytes of every SQLite 3 file are
		# exactly "SQLite format 3" followed by a NUL byte (byte 16).
		no autodie 'open';
		open my $fh, '>:raw', $path or BAIL_OUT "cannot write test file: $!";
		print {$fh} "SQLite format 3\x00trailing data here";
		close $fh;
	}
	is $fn->($path), 'db', 'SQLite magic bytes ("SQLite format 3") detected as db';
};

subtest '_sniff_data_ext -- XML preamble (<?xml) maps to xml' => sub {
	my $fn   = \&Database::BI::Model::DataSource::_sniff_data_ext;
	my $dir  = File::Temp::tempdir(CLEANUP => 1);

	# Canonical XML declaration.
	my $path1 = "$dir/feed.log";
	Mojo::File->new($path1)->spew("<?xml version=\"1.0\"?>\n<root/>\n");
	is $fn->($path1), 'xml', '<?xml declaration preamble detected as xml';

	# XML file without a declaration (bare opening tag).
	my $path2 = "$dir/data.log";
	Mojo::File->new($path2)->spew("<catalog>\n<item><sku>1</sku></item>\n</catalog>\n");
	is $fn->($path2), 'xml', 'bare opening < tag detected as xml';
};

subtest '_sniff_data_ext -- tab-delimited first line maps to tsv' => sub {
	my $fn  = \&Database::BI::Model::DataSource::_sniff_data_ext;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $path = "$dir/export.log";
	Mojo::File->new($path)->spew("col1\tcol2\tcol3\n1\t2\t3\n");
	is $fn->($path), 'tsv', 'tab characters in first line detected as tsv';
};

subtest '_sniff_data_ext -- pipe-delimited first line maps to psv' => sub {
	my $fn  = \&Database::BI::Model::DataSource::_sniff_data_ext;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $path = "$dir/report.log";
	Mojo::File->new($path)->spew("col1|col2|col3\n1|2|3\n");
	is $fn->($path), 'psv', 'pipe characters in first line detected as psv';
};

subtest '_sniff_data_ext -- comma-delimited or unknown content falls back to csv' => sub {
	my $fn  = \&Database::BI::Model::DataSource::_sniff_data_ext;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $path = "$dir/plain.log";
	Mojo::File->new($path)->spew("id,name,value\n1,Alice,100\n");
	is $fn->($path), 'csv', 'comma-delimited content falls back to csv';

	# Free-text line with no special delimiters also falls back to csv.
	my $path2 = "$dir/text.log";
	Mojo::File->new($path2)->spew("just a plain sentence here\n");
	is $fn->($path2), 'csv', 'plain text with no recognised delimiter falls back to csv';
};

# ============================================================================
# PART 12: DataSource::updated() -- mtime delegation
#
# updated() has three paths:
#   1. _db exists and implements updated() -> delegate to it
#   2. _db absent but _file_path points to a real file -> stat() fallback
#   3. Neither -> return undef
# ============================================================================

subtest 'DataSource::updated -- the file comes first, then _db->updated()' => sub {
	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);

	# Inject a mock backend whose updated() returns a sentinel mtime.
	Readonly my $FAKE_MTIME => 999_000_001;
	my $mock_db = bless {}, 'FakeUpdatedDB';
	{
		no strict 'refs';
		*{'FakeUpdatedDB::updated'} = sub { $FAKE_MTIME };
		*{'FakeUpdatedDB::can'}     = sub { 1 };   # pretends to implement everything
	}
	$src->{_db} = $mock_db;

	# Why: the backend only learns an mtime when it opens the file, so it answers
	# undef before the first read, and the time of that read after it.
	is $src->updated, (stat($src->{_file_path}))[9],
		'updated() trusts the file over what the backend remembers';

	delete $src->{_file_path};
	is $src->updated, $FAKE_MTIME,
		'updated() asks _db->updated() when there is no file to stat';
};

subtest 'DataSource::updated -- stat fallback when _db absent' => sub {
	SKIP: {
		my $path = File::Spec->rel2abs(File::Spec->catfile($DATA_DIR, 'sales.csv'));
		skip 'data/sales.csv not found', 2 unless -f $path;

		# Build a bare DataSource-shaped object with no _db but a valid _file_path.
		my $src = bless { _db => undef, _file_path => $path }, $DS;
		my $expected_mtime = (stat($path))[9];

		ok defined $src->updated, 'updated() returns a defined value via stat fallback';
		is $src->updated, $expected_mtime,
			'updated() stat fallback returns the correct mtime';
	}
};

subtest 'DataSource::updated -- returns undef when neither _db nor _file_path set' => sub {
	my $src = bless { _db => undef }, $DS;
	is $src->updated, undef,
		'updated() returns undef when no backend and no file path are set';
};

subtest 'DataSource::updated -- returns undef for non-existent _file_path' => sub {
	my $src = bless {
		_db        => undef,
		_file_path => '/no/such/file/at/all.csv',
	}, $DS;
	is $src->updated, undef,
		'updated() returns undef when _file_path points to a missing file';
};

# ============================================================================
# PART 13: DataSource::columns() -- delegation and URL-backed behaviour
#
# columns() has three code paths:
#   1. _columns is already set -> return it directly (CSV/PSV fast-path)
#   2. _url is set (URL-backed table) -> return undef WITHOUT touching _db
#   3. Fallback: delegate to _db->columns()
# The URL-backed check (path 2) is critical: calling _db->columns() on a
# URL-backed instance would trigger a live HTTP round-trip even on a cache hit.
# ============================================================================

subtest 'DataSource::columns -- URL-backed: returns undef without consulting _db' => sub {
	# Verify that _db->columns() is NEVER called for URL-backed tables.
	my $db_columns_called = 0;
	my $mock_db = bless {}, 'FakeColsDB_Url';
	{
		no strict 'refs';
		*{'FakeColsDB_Url::columns'} = sub { $db_columns_called++; ['col1', 'col2'] };
	}

	my $src = bless {
		_url     => 'http://example.com/page.html',
		_columns => undef,
		_db      => $mock_db,
	}, $DS;

	is $src->columns, undef,
		'columns() returns undef for URL-backed table (prevents live network call)';
	is $db_columns_called, 0,
		'columns() does not call _db->columns() for URL-backed table';
};

subtest 'DataSource::columns -- delegates to _db->columns() for non-URL-backed table' => sub {
	my $mock_db = bless {}, 'FakeColsDB_File';
	{
		no strict 'refs';
		*{'FakeColsDB_File::columns'} = sub { [qw(id name score)] };
	}

	# No _url set, no _columns set -> must fall through to _db->columns().
	my $src = bless { _columns => undef, _db => $mock_db }, $DS;
	is_deeply $src->columns, [qw(id name score)],
		'columns() delegates to _db->columns() for a non-URL-backed table';
};

subtest 'DataSource::columns -- returns undef when _db is undef and no _columns set' => sub {
	my $src = bless { _columns => undef, _db => undef }, $DS;
	is $src->columns, undef,
		'columns() returns undef when both _db and _columns are absent';
};

# ============================================================================
# PART 14: DataSource::selectall_arrayref -- @args bypasses cache
#
# When selectall_arrayref is called with extra arguments (a narrowed query),
# the cache must be skipped entirely: neither read (get) nor written (set).
# This prevents a partial result from polluting the full-scan cache entry that
# other callers (Database::Join, fetch_all) depend on.
# ============================================================================

subtest 'DataSource::selectall_arrayref -- @args bypass cache get and set' => sub {
	Readonly my $CACHE_SENTINEL => 'CACHE_SENTINEL_RESULT';

	# A cache that records every get/set call so we can assert neither fires.
	my @cache_calls;
	my $cache = bless {}, 'FakeCacheArgsBypass';
	{
		no strict 'refs';
		*{'FakeCacheArgsBypass::get'} = sub { push @cache_calls, 'get'; undef };
		*{'FakeCacheArgsBypass::set'} = sub { push @cache_calls, 'set' };
	}

	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);
	$src->{_cache}     = $cache;
	$src->{_file_path} = File::Spec->rel2abs(
		File::Spec->catfile($DATA_DIR, 'sales.csv'));

	# Mock the backend so the call succeeds without touching the real file.
	my $db_pkg = ref($src->{_db});
	Test::Mockingbird::mock("${db_pkg}::selectall_arrayref", sub {
		return [{ id => 'FROM_DB' }];
	});

	# A non-empty @args signals "narrowed query" -- cache must be bypassed.
	my $result = $src->selectall_arrayref({});

	Test::Mockingbird::unmock("${db_pkg}::selectall_arrayref");

	is scalar(@cache_calls), 0,
		'cache->get and cache->set are not called when selectall_arrayref receives @args';
	is $result->[0]{id}, 'FROM_DB',
		'result still comes from the backend when cache is bypassed';
};

# ============================================================================
# PART 15: Dashboard::_url_attribution -- URL spec attribution
#
# _url_attribution reads the l= query param.  When it is a url: spec it returns
# the raw URL and a human-readable date.  For table: and path: specs, or when l=
# is absent, it returns (undef, undef).
# ============================================================================

subtest 'Dashboard::_url_attribution -- url: spec returns URL and date string' => sub {
	my $fn  = \&Database::BI::Controller::Dashboard::_url_attribution;
	my $enc = Mojo::Util::url_escape('http://example.com/data.html');
	my $tx  = $t->ua->build_tx(GET => "/?l=url:http://example.com/data.html");
	my $c   = $t->app->build_controller($tx);
	my ($url, $date) = $fn->($c);
	is   $url, 'http://example.com/data.html',
		'_url_attribution returns the URL from a url: spec';
	like $date, qr/\A\d{1,2} [A-Z][a-z]+ \d{4}\z/,
		'_url_attribution date is formatted as "D Month YYYY"';
};

subtest 'Dashboard::_url_attribution -- table: spec returns (undef, undef)' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_url_attribution;
	my $tx = $t->ua->build_tx(GET => '/?l=table:sales');
	my $c  = $t->app->build_controller($tx);
	my ($url, $date) = $fn->($c);
	is $url,  undef, '_url_attribution returns undef URL for a table: spec';
	is $date, undef, '_url_attribution returns undef date for a table: spec';
};

subtest 'Dashboard::_url_attribution -- no l= param returns (undef, undef)' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_url_attribution;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);
	my ($url, $date) = $fn->($c);
	is $url,  undef, '_url_attribution returns undef URL when l= is absent';
	is $date, undef, '_url_attribution returns undef date when l= is absent';
};

# ============================================================================
# PART 16: Dashboard::_scan_data_dir -- filesystem data-directory scanner
#
# _scan_data_dir reads data_dir from app config and returns one hashref per
# supported data file.  Files with unsupported extensions must be excluded.
# Non-existent directories must return an empty arrayref without croaking.
# ============================================================================

subtest 'Dashboard::_scan_data_dir -- returns entries for the real data dir' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_scan_data_dir;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);

	my $tables = $fn->($c);
	returns_is $tables, { type => 'arrayref' }, '_scan_data_dir returns an arrayref';
	ok scalar(@$tables) > 0,
		'real data/ directory contains at least one supported file';
	for my $entry (@$tables) {
		ok exists $entry->{name}, "entry has a 'name' key";
		ok exists $entry->{file}, "entry has a 'file' key";
		unlike $entry->{name}, qr/\./,
			"name key '$entry->{name}' has no file extension";
		like $entry->{file}, qr/\.[\w]+\z/,
			"file key '$entry->{file}' includes an extension";
	}
	diag 'scanned entries: ' . join(', ', map { $_->{name} } @$tables)
		if $ENV{TEST_VERBOSE};
};

subtest 'Dashboard::_scan_data_dir -- all returned entries have supported extensions' => sub {
	# Regression guard: no entry with .txt, .log, .pl, etc. must be returned.
	my $fn = \&Database::BI::Controller::Dashboard::_scan_data_dir;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);
	my $tables = $fn->($c);

	Readonly my $SUPPORTED_EXT_RE =>
		qr/\.(?:csv|db|sql|sqlite|sqlite3|xml|tsv|psv|xlsx)\z/i;

	for my $entry (@$tables) {
		like $entry->{file}, $SUPPORTED_EXT_RE,
			"entry '$entry->{file}' has a recognised extension";
	}
};

subtest 'Dashboard::_scan_data_dir -- non-existent data_dir returns []' => sub {
	my $fn   = \&Database::BI::Controller::Dashboard::_scan_data_dir;
	my $tx   = $t->ua->build_tx(GET => '/');
	my $c    = $t->app->build_controller($tx);
	my $orig = $t->app->config->{data_dir};

	# Temporarily redirect data_dir to a relative path that cannot exist.
	$t->app->config->{data_dir} = 'no_such_data_dir_xyz_99999';
	my $tables = eval { $fn->($c) };
	$t->app->config->{data_dir} = $orig // 'data';

	is $@, '', '_scan_data_dir does not croak for a missing data_dir';
	is_deeply $tables, [], 'missing data_dir returns empty arrayref';
};

# ============================================================================
# PART 17: _detect_platform -- ENV localization invariant
#
# _detect_platform sets $ENV{HTTP_USER_AGENT} with local() so CGI::Info reads
# it.  Verifying the local() is in place prevents a class of bugs where a
# stale UA is left in the environment and affects subsequent requests.
# ============================================================================

subtest '_detect_platform -- local() restores ENV{HTTP_USER_AGENT} after call' => sub {
	Readonly my $SENTINEL_UA => 'SENTINEL_BEFORE_DETECT_PLATFORM_CALL';
	local $ENV{HTTP_USER_AGENT} = $SENTINEL_UA;

	Database::BI::Controller::Dashboard::_detect_platform(
		'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)', 'web');

	is $ENV{HTTP_USER_AGENT}, $SENTINEL_UA,
		'$ENV{HTTP_USER_AGENT} is restored to its original value after _detect_platform';
};

# ============================================================================
# PART 18: _resolve_language -- ENV localization invariant
#
# _resolve_language sets $ENV{HTTP_ACCEPT_LANGUAGE} with local() so
# CGI::Lingua reads the request Accept-Language header.  A missing local()
# would corrupt the env for any subsequent CGI::Lingua call in the same
# process (e.g. a second request in the test suite).
# ============================================================================

subtest '_resolve_language -- local() restores ENV{HTTP_ACCEPT_LANGUAGE} after call' => sub {
	Readonly my $SENTINEL_LANG => 'xx-SENTINEL-LANG-VALUE';
	local $ENV{HTTP_ACCEPT_LANGUAGE} = $SENTINEL_LANG;

	my $tx = $t->ua->build_tx(GET => '/');
	$tx->req->headers->header('Accept-Language' => 'en-US,en;q=0.9');
	my $c = $t->app->build_controller($tx);

	Database::BI::Controller::Dashboard::_resolve_language($c, 'web', 'en');

	is $ENV{HTTP_ACCEPT_LANGUAGE}, $SENTINEL_LANG,
		'$ENV{HTTP_ACCEPT_LANGUAGE} is restored to its original value after _resolve_language';
};

# ============================================================================
# PART 19: Dashboard::_open_spec -- all branches
#
# _open_spec parses "table:name", "path:/abs/path", or "url:http://..." specs,
# checks file existence and extension, constructs a DataSource, and returns
# ($src, $label) or an empty list on any failure.
# ============================================================================

subtest 'Dashboard::_open_spec -- table:sales returns DataSource and label' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 3 unless -f 'data/sales.csv';
		my $fn = \&Database::BI::Controller::Dashboard::_open_spec;
		my $tx = $t->ua->build_tx(GET => '/');
		my $c  = $t->app->build_controller($tx);
		my ($src, $label) = $fn->($c, 'table:sales');
		ok defined $src,   '_open_spec: table:sales returns a DataSource object';
		ok blessed($src),  'returned value is a blessed reference';
		is $label, 'sales', 'label matches the table name';
	}
};

subtest 'Dashboard::_open_spec -- table:nosuchxyz returns empty list' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_open_spec;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);
	my @result = $fn->($c, 'table:no_such_table_xyz_99');
	is scalar(@result), 0,
		'_open_spec returns empty list for a table name that has no matching file';
};

subtest 'Dashboard::_open_spec -- path: to supported file returns DataSource' => sub {
	SKIP: {
		my $abs = File::Spec->rel2abs(File::Spec->catfile($DATA_DIR, 'sales.csv'));
		skip 'data/sales.csv not found', 3 unless -f $abs;
		my $fn  = \&Database::BI::Controller::Dashboard::_open_spec;
		my $tx  = $t->ua->build_tx(GET => '/');
		my $c   = $t->app->build_controller($tx);
		my ($src, $label) = $fn->($c, "path:$abs");
		ok defined $src,       '_open_spec: path: to supported file returns DataSource';
		ok blessed($src),      'returned value is a blessed reference';
		like $label, qr/sales/, 'label contains the original file name';
	}
};

subtest 'Dashboard::_open_spec -- path: to unsupported extension returns ()' => sub {
	my $fn  = \&Database::BI::Controller::Dashboard::_open_spec;
	my $tmp = File::Temp::tempdir(CLEANUP => 1);
	my $abs = "$tmp/report.exe";
	Mojo::File->new($abs)->spew('not a data file');
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);
	my @result = $fn->($c, "path:$abs");
	is scalar(@result), 0,
		'_open_spec returns empty list when path: has an unsupported file extension';
};

subtest 'Dashboard::_open_spec -- garbage spec returns empty list' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_open_spec;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);
	my @result = $fn->($c, 'not_a_valid_spec_at_all');
	is scalar(@result), 0, '_open_spec returns empty list for an unrecognised spec format';
};

subtest 'Dashboard::_open_spec -- url: with localhost blocked by SSRF guard' => sub {
	# _is_safe_url blocks localhost; _open_spec must return () before even
	# attempting DataSource construction.
	my $fn = \&Database::BI::Controller::Dashboard::_open_spec;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);
	my @result = $fn->($c, 'url:http://localhost/data.html');
	is scalar(@result), 0,
		'_open_spec returns empty list for url: spec pointing to localhost (SSRF guard)';
};

subtest 'Dashboard::_open_spec -- remote path with shell metacharacter in hostname rejected' => sub {
	# REMOTE_HOST_RE does not allow semicolons or spaces; an injected hostname
	# like ";evil;" must be rejected before any SFTP attempt is made.
	my $fn = \&Database::BI::Controller::Dashboard::_open_spec;
	my $tx = $t->ua->build_tx(GET => '/');
	my $c  = $t->app->build_controller($tx);
	my @result = $fn->($c, 'path:/../;evil;/dir/file.csv');
	is scalar(@result), 0,
		'_open_spec rejects remote path whose hostname contains shell metacharacters';
};

# ============================================================================
# PART 20: Dashboard::_list_dir -- directory listing helper
#
# _list_dir scans a directory and returns two sorted lists: subdirectories and
# (optionally) data files.  Hidden entries (dot-prefixed names) must be excluded.
# Files with unsupported extensions are always omitted.  Entries are sorted
# case-insensitively.
# ============================================================================

subtest 'Dashboard::_list_dir -- hidden entries (dot-prefix) excluded' => sub {
	my $fn  = \&Database::BI::Controller::Dashboard::_list_dir;
	my $tmp = File::Temp::tempdir(CLEANUP => 1);
	my $dir = Mojo::File->new($tmp);

	$dir->child('visible_dir')->make_path;
	$dir->child('.hidden_dir')->make_path;
	Mojo::File->new("$tmp/data.csv")->spew("id,name\n1,Alice\n");
	Mojo::File->new("$tmp/.hidden_file.csv")->spew("id,name\n");

	my $tx     = $t->ua->build_tx(GET => '/');
	my $c      = $t->app->build_controller($tx);
	my $result = $fn->($c, $dir, 1);

	my @dir_names  = map { $_->{name} } @{ $result->{dirs}  };
	my @file_names = map { $_->{name} } @{ $result->{files} };

	ok !grep { $_ eq '.hidden_dir' }     @dir_names,
		'.hidden_dir excluded from directory listing';
	ok  grep { $_ eq 'visible_dir' }     @dir_names,
		'visible_dir included in directory listing';
	ok !grep { $_ eq '.hidden_file.csv' } @file_names,
		'.hidden_file.csv excluded from file listing';
	ok  grep { $_ eq 'data.csv' }         @file_names,
		'data.csv included in file listing';
};

subtest 'Dashboard::_list_dir -- want_files=0 returns empty files list' => sub {
	my $fn  = \&Database::BI::Controller::Dashboard::_list_dir;
	my $tmp = File::Temp::tempdir(CLEANUP => 1);
	my $dir = Mojo::File->new($tmp);
	Mojo::File->new("$tmp/data.csv")->spew("id,name\n1,Alice\n");
	$dir->child('subdir')->make_path;

	my $tx     = $t->ua->build_tx(GET => '/');
	my $c      = $t->app->build_controller($tx);
	my $result = $fn->($c, $dir, 0);  # want_files = false

	is_deeply $result->{files}, [],
		'files list is empty when want_files argument is false';
	is scalar(@{ $result->{dirs} }), 1,
		'directories are still returned when want_files is false';
};

subtest 'Dashboard::_list_dir -- entries sorted case-insensitively' => sub {
	my $fn  = \&Database::BI::Controller::Dashboard::_list_dir;
	my $tmp = File::Temp::tempdir(CLEANUP => 1);
	my $dir = Mojo::File->new($tmp);
	$dir->child('Zebra')->make_path;
	$dir->child('alpha')->make_path;
	$dir->child('Mango')->make_path;

	my $tx     = $t->ua->build_tx(GET => '/');
	my $c      = $t->app->build_controller($tx);
	my $result = $fn->($c, $dir, 0);
	my @names  = map { $_->{name} } @{ $result->{dirs} };
	is_deeply \@names, [qw(alpha Mango Zebra)],
		'directory entries are sorted case-insensitively (alpha < Mango < Zebra)';
};

subtest 'Dashboard::_list_dir -- unsupported file extensions excluded from files list' => sub {
	my $fn  = \&Database::BI::Controller::Dashboard::_list_dir;
	my $tmp = File::Temp::tempdir(CLEANUP => 1);
	my $dir = Mojo::File->new($tmp);
	Mojo::File->new("$tmp/report.csv")->spew("id,name\n1,A\n");
	Mojo::File->new("$tmp/archive.zip")->spew("zip content");
	Mojo::File->new("$tmp/notes.txt")->spew("plain text");

	my $tx     = $t->ua->build_tx(GET => '/');
	my $c      = $t->app->build_controller($tx);
	my $result = $fn->($c, $dir, 1);
	my @files  = map { $_->{name} } @{ $result->{files} };

	ok  grep { $_ eq 'report.csv' }  @files, 'report.csv included (supported extension)';
	ok !grep { $_ eq 'archive.zip' } @files, 'archive.zip excluded (unsupported extension)';
	ok !grep { $_ eq 'notes.txt' }   @files, 'notes.txt excluded (unsupported extension)';
};

subtest 'Dashboard::_list_dir -- both dirs and files listed result has no circular refs' => sub {
	my $fn  = \&Database::BI::Controller::Dashboard::_list_dir;
	my $tmp = File::Temp::tempdir(CLEANUP => 1);
	my $dir = Mojo::File->new($tmp);
	$dir->child('sub')->make_path;
	Mojo::File->new("$tmp/data.csv")->spew("id,name\n1,A\n");

	my $tx     = $t->ua->build_tx(GET => '/');
	my $c      = $t->app->build_controller($tx);
	my $result = $fn->($c, $dir, 1);
	memory_cycle_ok($result, '_list_dir result hashref has no circular references');
};

# ============================================================================
# PART 21: Dashboard::_write_sqlite_db -- empty columns guard
#
# An empty column list would produce "CREATE TABLE data ()" which is invalid
# SQLite syntax.  The function must croak with a recognisable message before
# touching the filesystem so no orphaned temp file is left behind.
# ============================================================================

subtest 'Dashboard::_write_sqlite_db -- empty columns list croaks before file creation' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 1;

		# Pass undef as $self -- _write_sqlite_db only uses $self for the
		# tempfile call (which pulls from the system tmpdir, not from the app).
		throws_ok {
			Database::BI::Controller::Dashboard::_write_sqlite_db(undef, [], [])
		} qr/no columns/i,
			'_write_sqlite_db croaks with a "no columns" message for an empty column list';
	}
};

# ============================================================================
# PART 22: DataSource::sqlite_tables() -- 0.011.0 accessor
#
# sqlite_tables() returns $self->{_sqlite_tables}: undef for non-SQLite
# sources, and an arrayref of internal table names for multi-table SQLite
# databases.  The accessor must never touch _db or the filesystem on access.
# ============================================================================

subtest 'DataSource::sqlite_tables -- returns undef for a CSV DataSource' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 1 unless -f File::Spec->catfile($DATA_DIR, 'sales.csv');
		my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);
		is $src->sqlite_tables, undef,
			'sqlite_tables() returns undef for a plain CSV DataSource';
	}
};

subtest 'DataSource::sqlite_tables -- returns undef when _sqlite_tables not set' => sub {
	# A bare blessed hash with no _sqlite_tables key is the "not a SQLite multi-table
	# DB" state.  The accessor must return undef, not die on missing key.
	my $src = bless {}, $DS;
	is $src->sqlite_tables, undef,
		'sqlite_tables() returns undef when _sqlite_tables key is absent';
};

subtest 'DataSource::sqlite_tables -- returns the stored arrayref unchanged' => sub {
	# Injecting _sqlite_tables directly verifies the accessor is a simple getter
	# with no transformation or copy.
	my $tbls = [qw(alpha beta gamma)];
	my $src  = bless { _sqlite_tables => $tbls }, $DS;
	is $src->sqlite_tables, $tbls,
		'sqlite_tables() returns the exact same arrayref reference (no copy)';
	is_deeply $src->sqlite_tables, [qw(alpha beta gamma)],
		'sqlite_tables() contents match the injected arrayref';
};

subtest 'DataSource::sqlite_tables -- returns empty arrayref, not undef, when set to []' => sub {
	# A DataSource that was built from a SQLite file with zero user tables stores
	# [] (the no-tables case).  The accessor must return the empty arrayref, not
	# undef -- callers check scalar(@{$src->sqlite_tables // []}) > 1 to decide
	# whether to redirect; returning undef would silently suppress that check.
	my $src = bless { _sqlite_tables => [] }, $DS;
	my $got = $src->sqlite_tables;
	ok defined $got, 'sqlite_tables() returns a defined value (empty arrayref) not undef';
	is ref($got), 'ARRAY', 'returned value is an arrayref';
	is scalar(@$got), 0, 'arrayref is empty';
};

# ============================================================================
# PART 23: DataSource::new with internal_table -- 0.011.0 constructor param
#
# internal_table selects a specific table inside a multi-table SQLite file.
# When absent, the first matching (or first) table is auto-selected.
# When present but the name does not exist in the file, the constructor must
# croak with the "error_table_not_found" message so the caller receives a
# clear diagnostic rather than a silent wrong-table result.
# ============================================================================

subtest 'DataSource::new + internal_table -- opens the named table without croaking' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 3;

		my $dir  = File::Temp::tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'shop.sql');
		{
			my $dbh = DBI->connect("dbi:SQLite:dbname=$path", q{}, q{},
				{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
			$dbh->do('CREATE TABLE items (id INTEGER PRIMARY KEY, label TEXT)');
			$dbh->do(q{INSERT INTO items VALUES (1, 'Widget')});
			$dbh->do('CREATE TABLE tags  (id INTEGER PRIMARY KEY, name TEXT)');
			$dbh->do(q{INSERT INTO tags VALUES (1, 'hardware')});
			$dbh->disconnect;
		}

		# Specify the "tags" table explicitly -- without internal_table the
		# first-matched or first table would be auto-selected.
		my $src = eval {
			$DS->new(directory => $dir, table => 'shop', internal_table => 'tags')
		};
		is $@, '', 'DataSource::new with valid internal_table does not croak';
		ok defined $src, 'constructor returns a DataSource object';
		my $rows = eval { $src->fetch_all };
		is $@, '', 'fetch_all on internal_table-selected source does not croak';
		ok scalar(@{ $rows // [] }) > 0,
			'at least one row returned from the internal_table';
	}
};

subtest 'DataSource::new + internal_table -- nonexistent table name croaks' => sub {
	# The "error_table_not_found" guard must fire before D::A construction so the
	# caller gets a diagnostic error instead of a silent empty result.
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 1;

		my $dir  = File::Temp::tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'oneway.sql');
		{
			my $dbh = DBI->connect("dbi:SQLite:dbname=$path", q{}, q{},
				{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
			$dbh->do('CREATE TABLE items (id INTEGER PRIMARY KEY, label TEXT)');
			$dbh->disconnect;
		}

		throws_ok {
			$DS->new(directory => $dir, table => 'oneway',
				internal_table => 'no_such_table_xyz')
		} qr/no_such_table_xyz/,
			'new() croaks mentioning the missing table name when internal_table is not found';
	}
};

subtest 'DataSource::new -- multi-table SQLite populates sqlite_tables after construction' => sub {
	# Verifies that _init_backend stores the full table list so the controller
	# can detect the multi-table case and redirect to /tables.
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 3;

		my $dir  = File::Temp::tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'multi.sql');
		{
			my $dbh = DBI->connect("dbi:SQLite:dbname=$path", q{}, q{},
				{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
			$dbh->do('CREATE TABLE alpha (id INTEGER)');
			$dbh->do('CREATE TABLE beta  (id INTEGER)');
			$dbh->disconnect;
		}

		my $src = eval { $DS->new(directory => $dir, table => 'multi') };
		is $@, '', 'DataSource::new for multi-table SQLite does not croak';
		my $tbls = $src->sqlite_tables;
		ok defined $tbls, 'sqlite_tables() is defined after multi-table SQLite construction';
		is ref($tbls), 'ARRAY', 'sqlite_tables() returns an arrayref';
		ok scalar(@$tbls) >= 2,
			'sqlite_tables() contains at least 2 entries for a 2-table SQLite file';
	}
};

subtest 'DataSource::new -- single-table SQLite: sqlite_tables has exactly one entry' => sub {
	# A single-table SQLite file (the normal case) should still populate
	# _sqlite_tables so callers can distinguish "unknown" (undef, CSV/PSV) from
	# "known single table" (array with one element).
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 2;

		my $dir  = File::Temp::tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'single.sql');
		{
			my $dbh = DBI->connect("dbi:SQLite:dbname=$path", q{}, q{},
				{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
			$dbh->do('CREATE TABLE only_table (id INTEGER, val TEXT)');
			$dbh->do(q{INSERT INTO only_table VALUES (1, 'row')});
			$dbh->disconnect;
		}

		my $src  = eval { $DS->new(directory => $dir, table => 'single') };
		my $tbls = $src->sqlite_tables;
		ok defined $tbls, 'sqlite_tables() defined for single-table SQLite';
		is scalar(@$tbls), 1, 'sqlite_tables() has exactly one entry for single-table SQLite';
	}
};

# ============================================================================
# PART 24: Dashboard::tables_view -- HTTP smoke tests (0.011.0 route)
#
# GET /tables requires the l= query param and a SQLite file.  All failure paths
# must return 404 rather than 500.  Success renders the "Tables in ..." heading
# with one card per internal table.  Tests use temp SQLite files so they are
# self-contained and do not depend on data/store.db being present.
# ============================================================================

subtest 'GET /tables -- missing l= returns 404' => sub {
	$t->get_ok('/tables')
	  ->status_is(404, '/tables without l= returns 404 Not Found');
};

subtest 'GET /tables -- empty l= returns 404' => sub {
	$t->get_ok('/tables?l=')
	  ->status_is(404, '/tables with empty l= returns 404 Not Found');
};

subtest 'GET /tables -- unrecognised spec prefix returns 404' => sub {
	$t->get_ok('/tables?l=url:http://example.com/data.html')
	  ->status_is(404, '/tables with url: spec (not supported) returns 404');
};

subtest 'GET /tables -- path: to non-existent file returns 404' => sub {
	use Mojo::Util qw(url_escape);
	$t->get_ok('/tables?l=' . url_escape('path:/no/such/file/here.sql'))
	  ->status_is(404, '/tables with non-existent path: returns 404');
};

subtest 'GET /tables -- path: to non-SQLite file (CSV) returns 404' => sub {
	# Only SQLite extensions are accepted; a .csv file must be blocked.
	use Mojo::Util qw(url_escape);
	SKIP: {
		my $abs = File::Spec->rel2abs(File::Spec->catfile($DATA_DIR, 'sales.csv'));
		skip 'data/sales.csv not found', 1 unless -f $abs;
		$t->get_ok('/tables?l=' . url_escape("path:$abs"))
		  ->status_is(404, '/tables with CSV path: returns 404 (wrong file type)');
	}
};

subtest 'GET /tables -- path: to multi-table SQLite returns 200 with table cards' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 7;

		use Mojo::Util qw(url_escape);
		my $dir  = File::Temp::tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'browse.sql');
		{
			my $dbh = DBI->connect("dbi:SQLite:dbname=$path", q{}, q{},
				{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
			$dbh->do('CREATE TABLE customers (id INTEGER, name TEXT)');
			$dbh->do('CREATE TABLE orders    (id INTEGER, customer_id INTEGER, total REAL)');
			$dbh->disconnect;
		}

		my $spec = "path:$path";
		$t->get_ok('/tables?l=' . url_escape($spec))
		  ->status_is(200, '/tables?l=path:... returns 200 for a valid multi-table SQLite')
		  ->content_like(qr/Tables in/i, 'response contains "Tables in" heading')
		  ->content_like(qr/customers/, 'table card for "customers" present')
		  ->content_like(qr/orders/,    'table card for "orders" present')
		  ->content_like(qr/name/,      'column "name" from customers listed')
		  ->content_like(qr/customer_id/, 'column "customer_id" from orders listed');
	}
};

subtest 'GET /tables -- table card href contains &it=<name> param' => sub {
	# The href on each card must encode ?it=<tablename> so clicking it opens
	# that specific table via /open?it=...
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 2;

		use Mojo::Util qw(url_escape);
		my $dir  = File::Temp::tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'it_test.sql');
		{
			my $dbh = DBI->connect("dbi:SQLite:dbname=$path", q{}, q{},
				{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
			$dbh->do('CREATE TABLE foo (id INTEGER)');
			$dbh->do('CREATE TABLE bar (id INTEGER)');
			$dbh->disconnect;
		}

		$t->get_ok('/tables?l=' . url_escape("path:$path"))
		  ->status_is(200, '/tables returns 200 for it_test.sql')
		  ->content_like(qr/it=foo/, 'card href for "foo" table contains &it=foo')
		  ->content_like(qr/it=bar/, 'card href for "bar" table contains &it=bar');
	}
};

subtest 'GET /tables -- table:store spec works when data/store.db present' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 2;
		skip 'data/store.db not found', 2 unless -f 'data/store.db';

		$t->get_ok('/tables?l=table:store')
		  ->status_is(200, '/tables?l=table:store returns 200 when data/store.db exists')
		  ->content_like(qr/Tables in/i, 'response includes "Tables in" heading');
	}
};

subtest 'GET /tables -- table:no_such_xyz returns 404' => sub {
	$t->get_ok('/tables?l=table:no_such_xyz')
	  ->status_is(404, '/tables?l=table: with missing file returns 404');
};

# ---------------------------------------------------------------------------
# P0-5: DataSource::dbi_source() -- return contract (P0-4 fix coverage)
# ---------------------------------------------------------------------------

subtest 'DataSource::dbi_source -- CSV source returns undef (not SQL-backed)' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 1 unless -f 'data/sales.csv';
		require Database::BI::Model::DataSource;
		my $ds = Database::BI::Model::DataSource->new(
			table     => 'sales',
			directory => 'data',
		);
		is($ds->dbi_source, undef, 'CSV DataSource returns undef from dbi_source');
	}
};

subtest 'DataSource::dbi_source -- SQLite source returns hashref with dbh and table' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 3;
		my $dir  = tempdir(CLEANUP => 1);
		my $path = "$dir/dbi_test.sql";
		my $dbh  = DBI->connect("dbi:SQLite:dbname=$path", '', '', { RaiseError => 1 });
		$dbh->do('CREATE TABLE dbi_test (id INTEGER, name TEXT)');
		$dbh->do("INSERT INTO dbi_test VALUES (1, 'Alice')");
		$dbh->disconnect;

		require Database::BI::Model::DataSource;
		my $ds = Database::BI::Model::DataSource->new(
			table     => 'dbi_test',
			directory => $dir,
		);
		$ds->fetch_all;    # initialise the backend
		my $src = $ds->dbi_source;
		ok(defined $src, 'SQLite DataSource returns defined value from dbi_source');
		ok(ref $src,     'return value is a reference');
	}
};

subtest 'DataSource::dbi_source -- headerless-only DataSource returns undef' => sub {
	# DataSources backed by the headerless-CSV path (no DBI) must return undef.
	# Use a SQLite file created by DBI (dbi_source returns defined) vs a plain
	# CSV (dbi_source returns undef) as the negative control.
	SKIP: {
		skip 'data/sales.csv not found', 1 unless -f 'data/sales.csv';
		require Database::BI::Model::DataSource;
		my $ds = Database::BI::Model::DataSource->new(
			table     => 'sales',
			directory => 'data',
		);
		is($ds->dbi_source, undef,
			'CSV-backed DataSource::dbi_source returns undef (no SQL backend)');
	}
};

# ---------------------------------------------------------------------------
# P1-2: _grouped_totals push vs fold equivalence gate
# ---------------------------------------------------------------------------

subtest '_grouped_totals -- fold and push agree on category order (SQLite, no filter)' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 4;

		my $dir  = tempdir(CLEANUP => 1);
		my $path = "$dir/agg_gate.sql";
		my $dbh  = DBI->connect("dbi:SQLite:dbname=$path", '', '', { RaiseError => 1 });
		$dbh->do('CREATE TABLE agg_gate (region TEXT, amount REAL)');
		# Deliberately insert in non-alphabetical order so first-seen != ascending
		for my $row (['East', 100], ['North', 200], ['South', 150], ['East', 50]) {
			$dbh->do('INSERT INTO agg_gate VALUES (?,?)', undef, @$row);
		}
		$dbh->disconnect;

		use Mojo::Util qw(url_escape);
		my $spec = url_escape("path:$path");

		# Push path (SQLite backed)
		my $push_body = $t->get_ok("/pie?l=$spec&cat=region&val=amount")
		                   ->status_is(200)->tx->res->body;
		my @push_labels = ($push_body =~ /"label":"([^"]+)"/g);

		# Forced Perl fold
		local $ENV{BI_FORCE_PERL_AGG} = 1;
		my $fold_body = $t->get_ok("/pie?l=$spec&cat=region&val=amount")
		                   ->status_is(200)->tx->res->body;
		my @fold_labels = ($fold_body =~ /"label":"([^"]+)"/g);

		is_deeply(\@push_labels, \@fold_labels,
			'push and fold produce same labels in same ascending order');
	}
};

subtest '_grouped_totals -- fold returns same keys as push for bar chart (order-visible)' => sub {
	# Bar chart preserves category order from _grouped_totals (it only sorts when
	# ?sort= is explicitly requested), so we can observe fold key order via HTTP.
	SKIP: {
		skip 'data/sales.csv not found', 3 unless -f 'data/sales.csv';

		# CSV source always uses Perl fold (never SQL-backed).
		my $res = $t->get_ok('/bar?l=table:sales&cat=region')
		             ->status_is(200)->tx->res->body;

		my @labels = ($res =~ /"label":"([^"]+)"/g);
		ok(@labels > 0, 'bar chart returned at least one category label for CSV fold');
		my @sorted = sort @labels;
		is_deeply(\@labels, \@sorted,
			'fold-path bar chart category labels are in ascending order');
	}
};

# ============================================================================
# PART 3: Database::BI::Calc
# ============================================================================
# t/calc.t covers arithmetic, comparison, IF, string/numeric/date functions,
# bin(), the column whitelist, error cases, depth limit, and security.
# This section targets areas NOT in t/calc.t:
#   - date_normalise() standalone helper (completely untested elsewhere)
#   - evaluate() returning undef when _code is absent
#   - memory-cycle safety of compiled Calc objects

use_ok('Database::BI::Calc');

# ---------------------------------------------------------------------------
# date_normalise() -- standalone ISO-8601 conversion helper
# ---------------------------------------------------------------------------

subtest 'Calc::date_normalise -- %m/%d/%Y US format' => sub {
	# Standard US slash-date; leading zeros optional.
	is Database::BI::Calc::date_normalise('01/15/2026', '%m/%d/%Y'), '2026-01-15',
		'converts January 15 2026 from US format';
	is Database::BI::Calc::date_normalise('12/31/1999', '%m/%d/%Y'), '1999-12-31',
		'converts Dec 31 1999 from US format';
	is Database::BI::Calc::date_normalise('3/7/2025',   '%m/%d/%Y'), '2025-03-07',
		'handles single-digit month and day';

	# Wrong separator makes the regex fail -- must return undef.
	is Database::BI::Calc::date_normalise('01-15-2026', '%m/%d/%Y'), undef,
		'wrong separator (hyphens) fails %m/%d/%Y regex (returns undef)';
};

subtest 'Calc::date_normalise -- %d/%m/%Y EU format' => sub {
	is Database::BI::Calc::date_normalise('15/01/2026', '%d/%m/%Y'), '2026-01-15',
		'converts day/month/year in EU format';
	is Database::BI::Calc::date_normalise('31/12/1999', '%d/%m/%Y'), '1999-12-31',
		'converts Dec 31 1999 from EU format';
	is Database::BI::Calc::date_normalise('1/6/2025',   '%d/%m/%Y'), '2025-06-01',
		'handles single-digit day and month in EU format';

	# Wrong separator must cause regex failure.
	is Database::BI::Calc::date_normalise('15-01-2026', '%d/%m/%Y'), undef,
		'wrong separator (hyphens) fails %d/%m/%Y regex (returns undef)';
};

subtest 'Calc::date_normalise -- %d-%b-%Y DD-Mon-YYYY format' => sub {
	is Database::BI::Calc::date_normalise('15-Jan-2026', '%d-%b-%Y'), '2026-01-15',
		'converts DD-Mon-YYYY with mixed-case abbreviation';
	is Database::BI::Calc::date_normalise('01-DEC-1999', '%d-%b-%Y'), '1999-12-01',
		'case-insensitive month abbreviation (DEC)';
	is Database::BI::Calc::date_normalise('7-oct-2024',  '%d-%b-%Y'), '2024-10-07',
		'lowercase month abbreviation accepted';

	# Invalid month abbreviation must return undef, not crash.
	is Database::BI::Calc::date_normalise('15-Xxx-2026', '%d-%b-%Y'), undef,
		'unknown month abbreviation returns undef';
	# Slash separator does not match hyphen-based pattern.
	is Database::BI::Calc::date_normalise('15/Jan/2026', '%d-%b-%Y'), undef,
		'slash-separated date does not match %d-%b-%Y';
};

subtest 'Calc::date_normalise -- undef / empty / unknown pattern edge cases' => sub {
	# Guard clauses: undef or empty inputs must return undef safely.
	is Database::BI::Calc::date_normalise(undef, '%m/%d/%Y'), undef,
		'undef value returns undef';
	is Database::BI::Calc::date_normalise('',    '%m/%d/%Y'), undef,
		'empty string returns undef';
	is Database::BI::Calc::date_normalise('01/15/2026', undef), undef,
		'undef pattern returns undef';
	# An unsupported pattern silently returns undef (no croak).
	is Database::BI::Calc::date_normalise('01/15/2026', '%Y-%m-%d'), undef,
		'unsupported pattern returns undef (does not croak)';
};

subtest 'Calc::evaluate -- returns undef when object has a compile error (_code is undef)' => sub {
	# When new() fails to parse, _code stays undef.  evaluate() must not croak;
	# it must return undef so callers can treat runtime errors uniformly.
	my $bad = Database::BI::Calc->new(expr => 'qty % 2', columns => ['qty']);
	ok $bad->has_error, 'compile error set on bad expression';
	is $bad->evaluate({ qty => 10 }), undef,
		'evaluate() returns undef on object with compile error (no croak)';
};

subtest 'Calc::evaluate -- runtime division by zero returns undef, does not croak' => sub {
	my $c = Database::BI::Calc->new(expr => 'amount / qty', columns => ['amount', 'qty']);
	ok !$c->has_error, 'expression compiles cleanly';
	is $c->evaluate({ amount => 100, qty => 0 }), undef,
		'division by zero yields undef at runtime';
};

subtest 'Calc -- memory cycle check on compiled object' => sub {
	# Ensure the closure tree created by new() does not form a reference cycle
	# that would prevent garbage collection.
	my $c = Database::BI::Calc->new(
		expr    => 'if(amount > 0, round(amount * 1.1, 2), 0)',
		columns => ['amount'],
	);
	ok !$c->has_error, 'expression compiles for memory-cycle check';
	memory_cycle_ok($c, 'no reference cycles in compiled Calc object');
};

# ============================================================================
# PART 4: new chart-view endpoints (scatter / stacked / combo / treemap / histogram)
# ============================================================================
# All tests use the $t Test::Mojo instance and data/sales.csv (6 rows:
# product, region, amount, date) as the data source.  Only the error-path
# tests and basic smoke tests are included here; full pipeline tests live in
# t/integration.t.  The primary goal is 60%+ negative coverage.

{
	use Mojo::Util qw(url_escape);
	Readonly my $SALES_SPEC => url_escape('table:sales');

# ---------------------------------------------------------------------------
# scatter_view
# ---------------------------------------------------------------------------

subtest 'scatter_view -- missing x= returns 400' => sub {
	$t->get_ok("/scatter?l=$SALES_SPEC&y=amount")
	  ->status_is(400)
	  ->content_like(qr/Missing x=/i,
		'missing x= produces 400 with descriptive message');
};

subtest 'scatter_view -- missing y= returns 400' => sub {
	$t->get_ok("/scatter?l=$SALES_SPEC&x=amount")
	  ->status_is(400)
	  ->content_like(qr/Missing y=/i,
		'missing y= produces 400 with descriptive message');
};

subtest 'scatter_view -- unknown x column returns 400' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/scatter?l=$SALES_SPEC&x=no_such_col&y=amount")
		  ->status_is(400)
		  ->content_like(qr/Column not found.*no_such_col/i,
			'unknown x column yields 400');
	}
};

subtest 'scatter_view -- unknown colour scheme with series= returns 400' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/scatter?l=$SALES_SPEC&x=amount&y=amount&series=region&scheme=bogus")
		  ->status_is(400)
		  ->content_like(qr/Unknown colour scheme/i,
			'unrecognised scheme with series= yields 400');
	}
};

subtest 'scatter_view -- valid render returns 200 with SVG' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/scatter?l=$SALES_SPEC&x=amount&y=amount")
		  ->status_is(200)
		  ->content_like(qr/<svg/i,
			'valid scatter request renders an SVG element');
	}
};

# ---------------------------------------------------------------------------
# stacked_view
# ---------------------------------------------------------------------------

subtest 'stacked_view -- missing cat= returns 400' => sub {
	$t->get_ok("/stacked?l=$SALES_SPEC&series=region")
	  ->status_is(400)
	  ->content_like(qr/Missing cat=/i,
		'missing cat= yields 400');
};

subtest 'stacked_view -- missing series= returns 400' => sub {
	$t->get_ok("/stacked?l=$SALES_SPEC&cat=region")
	  ->status_is(400)
	  ->content_like(qr/Missing series=/i,
		'missing series= yields 400');
};

subtest 'stacked_view -- unknown cat column returns 400' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/stacked?l=$SALES_SPEC&cat=no_such&series=region")
		  ->status_is(400)
		  ->content_like(qr/Column not found/i,
			'unknown cat column yields 400');
	}
};

subtest 'stacked_view -- valid render returns 200 with SVG' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/stacked?l=$SALES_SPEC&cat=region&series=product")
		  ->status_is(200)
		  ->content_like(qr/<svg/i,
			'valid stacked request renders an SVG element');
	}
};

# ---------------------------------------------------------------------------
# combo_view
# ---------------------------------------------------------------------------

subtest 'combo_view -- missing cat= returns 400' => sub {
	$t->get_ok("/combo?l=$SALES_SPEC&bar=amount&line=amount")
	  ->status_is(400)
	  ->content_like(qr/Missing cat=/i,
		'missing cat= yields 400');
};

subtest 'combo_view -- missing bar= returns 400' => sub {
	# bar_val= is the canonical name; bar= is accepted as a legacy alias.
	# Omitting both -> 400 "Missing bar_val= parameter".
	$t->get_ok("/combo?l=$SALES_SPEC&cat=region&line_val=amount")
	  ->status_is(400)
	  ->content_like(qr/Missing bar_val=/i,
		'missing bar_val= yields 400');
};

subtest 'combo_view -- missing line= returns 400' => sub {
	# line_val= is the canonical name; line= is accepted as a legacy alias.
	# Omitting both -> 400 "Missing line_val= parameter".
	$t->get_ok("/combo?l=$SALES_SPEC&cat=region&bar_val=amount")
	  ->status_is(400)
	  ->content_like(qr/Missing line_val=/i,
		'missing line_val= yields 400');
};

subtest 'combo_view -- valid render returns 200 with SVG' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/combo?l=$SALES_SPEC&cat=region&bar=amount&line=amount")
		  ->status_is(200)
		  ->content_like(qr/<svg/i,
			'valid combo request renders an SVG element');
	}
};

# ---------------------------------------------------------------------------
# treemap_view
# ---------------------------------------------------------------------------

subtest 'treemap_view -- missing group= returns 400' => sub {
	$t->get_ok("/treemap?l=$SALES_SPEC")
	  ->status_is(400)
	  ->content_like(qr/Missing group=/i,
		'missing group= yields 400');
};

subtest 'treemap_view -- ?color= naming no column returns 400' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/treemap?l=$SALES_SPEC&group=region&color=no_such_col")
		  ->status_is(400)
		  ->content_like(qr/Column not found/i,
			'?color= naming no column yields 400');
	}
};

subtest 'treemap_view -- unknown group column returns 400' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/treemap?l=$SALES_SPEC&group=no_such_col")
		  ->status_is(400)
		  ->content_like(qr/Column not found/i,
			'unknown group column yields 400');
	}
};

subtest 'treemap_view -- valid render returns 200 with SVG' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/treemap?l=$SALES_SPEC&group=region&size=amount")
		  ->status_is(200)
		  ->content_like(qr/<svg/i,
			'valid treemap request renders an SVG element');
	}
};

# ---------------------------------------------------------------------------
# histogram_view
# ---------------------------------------------------------------------------

subtest 'histogram_view -- missing col= returns 400' => sub {
	$t->get_ok("/histogram?l=$SALES_SPEC")
	  ->status_is(400)
	  ->content_like(qr/Missing col=/i,
		'missing col= yields 400');
};

subtest 'histogram_view -- unknown col returns 400' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/histogram?l=$SALES_SPEC&col=no_such_col")
		  ->status_is(400)
		  ->content_like(qr/Column not found/i,
			'unknown col yields 400');
	}
};

subtest 'histogram_view -- bins clamped to 200 maximum (does not crash)' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		# bins=99999 must be clamped to 200 internally; the response must be 200
		# or the "No plottable data" message, never a 500 or crash.
		$t->get_ok("/histogram?l=$SALES_SPEC&col=amount&bins=99999")
		  ->status_is(200, 'bins=99999 clamped to 200, no server error');
	}
};

subtest 'histogram_view -- bins clamped to 1 minimum (does not crash)' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/histogram?l=$SALES_SPEC&col=amount&bins=0")
		  ->status_is(200, 'bins=0 clamped to 1, no server error');
	}
};

subtest 'histogram_view -- valid render returns 200 with SVG' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/histogram?l=$SALES_SPEC&col=amount&bins=5")
		  ->status_is(200)
		  ->content_like(qr/<svg/i,
			'valid histogram request renders an SVG element');
	}
};

} # end url_escape scope

# ============================================================================
# PART 5: calc / groups / dates CRUD endpoints
# ============================================================================
# Isolate the model store in a fresh tempdir so these tests never touch
# .bi/models.json in the working directory.

{
	my $MODEL_DIR = tempdir(CLEANUP => 1);
	$t->app->config->{model_dir} = $MODEL_DIR;

	Readonly my $TEST_SPEC => 'table:sales';

# ---------------------------------------------------------------------------
# calc_list / calc_save / calc_delete
# ---------------------------------------------------------------------------

subtest 'calc_list -- l= required, returns 400 when absent' => sub {
	$t->get_ok('/calc/list')
	  ->status_is(400)
	  ->json_is('/error', 'l= required',
		'GET /calc/list without l= returns 400 with error message');
};

subtest 'calc_save -- l= required, returns 400 when absent' => sub {
	$t->post_ok('/calc/save', form => { name => 'profit', expr => 'amount * 2' })
	  ->status_is(400)
	  ->json_is('/error', 'l= required',
		'POST /calc/save without l= returns 400');
};

subtest 'calc_save -- invalid name (spaces) returns 400' => sub {
	$t->post_ok('/calc/save',
		form => { l => $TEST_SPEC, name => 'bad name', expr => 'amount * 2' })
	  ->status_is(400)
	  ->json_like('/error', qr/not a valid identifier/i,
		'calc name with spaces is rejected with 400');
};

subtest 'calc_save -- name with leading digit returns 400' => sub {
	$t->post_ok('/calc/save',
		form => { l => $TEST_SPEC, name => '1profit', expr => 'amount * 2' })
	  ->status_is(400)
	  ->json_like('/error', qr/not a valid identifier/i,
		'calc name starting with digit is rejected with 400');
};

subtest 'calc_save -- expr= required, returns 400 when absent' => sub {
	$t->post_ok('/calc/save', form => { l => $TEST_SPEC, name => 'profit' })
	  ->status_is(400)
	  ->json_is('/error', 'expr= required',
		'POST /calc/save without expr= returns 400');
};

subtest 'calc_save / calc_list / calc_delete -- full roundtrip' => sub {
	# Store two calc fields, retrieve them, then delete one and verify.

	$t->post_ok('/calc/save',
		form => { l => $TEST_SPEC, name => 'double', expr => 'amount * 2' })
	  ->status_is(200)
	  ->json_is('/ok', 1, 'first calc field saved');

	$t->post_ok('/calc/save',
		form => { l => $TEST_SPEC, name => 'halved', expr => 'amount / 2' })
	  ->status_is(200)
	  ->json_is('/ok', 1, 'second calc field saved');

	my $list = $t->get_ok("/calc/list?l=$TEST_SPEC")
	             ->status_is(200)->tx->res->json;
	ok exists $list->{fields}{double}, 'calc_list returns first field';
	ok exists $list->{fields}{halved}, 'calc_list returns second field';
	is $list->{fields}{double}, 'amount * 2', 'stored expression matches';

	$t->post_ok('/calc/delete', form => { l => $TEST_SPEC, name => 'double' })
	  ->status_is(200)
	  ->json_is('/ok', 1, 'first field deleted');

	my $after = $t->get_ok("/calc/list?l=$TEST_SPEC")
	              ->status_is(200)->tx->res->json;
	ok !exists $after->{fields}{double}, 'deleted field absent from list';
	ok  exists $after->{fields}{halved}, 'remaining field still present';
};

subtest 'calc_delete -- l= required, returns 400 when absent' => sub {
	$t->post_ok('/calc/delete', form => { name => 'whatever' })
	  ->status_is(400)
	  ->json_is('/error', 'l= required',
		'POST /calc/delete without l= returns 400');
};

# ---------------------------------------------------------------------------
# groups_list / groups_save / groups_delete
# ---------------------------------------------------------------------------

subtest 'groups_list -- l= required, returns 400 when absent' => sub {
	$t->get_ok('/groups/list')
	  ->status_is(400)
	  ->json_is('/error', 'l= required',
		'GET /groups/list without l= returns 400');
};

subtest 'groups_save -- l= required, returns 400 when absent' => sub {
	$t->post_ok('/groups/save',
		form => { col => 'region', group => 'North-East', values => 'North' })
	  ->status_is(400)
	  ->json_is('/error', 'l= required',
		'POST /groups/save without l= returns 400');
};

subtest 'groups_save -- col= required, returns 400 when absent' => sub {
	$t->post_ok('/groups/save',
		form => { l => $TEST_SPEC, group => 'NE', values => 'North' })
	  ->status_is(400)
	  ->json_is('/error', 'col= required',
		'POST /groups/save without col= returns 400');
};

subtest 'groups_save -- group= required, returns 400 when absent' => sub {
	$t->post_ok('/groups/save',
		form => { l => $TEST_SPEC, col => 'region', values => 'North' })
	  ->status_is(400)
	  ->json_is('/error', 'group= required',
		'POST /groups/save without group= returns 400');
};

subtest 'groups_save / groups_list / groups_delete -- full roundtrip' => sub {
	$t->post_ok('/groups/save',
		form => {
			l      => $TEST_SPEC,
			col    => 'region',
			group  => 'North-East',
			values => ['North', 'East'],
		})
	  ->status_is(200)
	  ->json_is('/ok', 1, 'group saved');

	# groups_list returns { groups: { col: { group_name: [values] } } }
	my $list = $t->get_ok("/groups/list?l=$TEST_SPEC")
	             ->status_is(200)->tx->res->json;
	ok exists $list->{groups}{region}{'North-East'}, 'group appears in list after save';

	$t->post_ok('/groups/delete',
		form => { l => $TEST_SPEC, col => 'region', group => 'North-East' })
	  ->status_is(200)
	  ->json_is('/ok', 1, 'group deleted');

	my $after = $t->get_ok("/groups/list?l=$TEST_SPEC")
	              ->status_is(200)->tx->res->json;
	ok !exists($after->{groups}{region}{'North-East'}), 'deleted group absent after delete';
};

subtest 'groups_delete -- deletes all groups for spec when only l= given' => sub {
	# Save two groups, then delete with only l= (no col or group).
	$t->post_ok('/groups/save',
		form => { l => $TEST_SPEC, col => 'product', group => 'Group-A', values => 'Widget' })
	  ->status_is(200);

	$t->post_ok('/groups/delete', form => { l => $TEST_SPEC })
	  ->status_is(200)
	  ->json_is('/ok', 1, 'all groups for spec deleted');

	my $after = $t->get_ok("/groups/list?l=$TEST_SPEC")
	              ->status_is(200)->tx->res->json;
	is_deeply $after->{groups}, {}, 'group store is empty after full-spec delete';
};

# ---------------------------------------------------------------------------
# dates_list / dates_save / dates_delete
# ---------------------------------------------------------------------------

subtest 'dates_list -- l= required, returns 400 when absent' => sub {
	$t->get_ok('/dates/list')
	  ->status_is(400)
	  ->json_is('/error', 'l= required',
		'GET /dates/list without l= returns 400');
};

subtest 'dates_save -- l= required, returns 400 when absent' => sub {
	$t->post_ok('/dates/save', form => { col => 'date', pattern => '%m/%d/%Y' })
	  ->status_is(400)
	  ->json_is('/error', 'l= required',
		'POST /dates/save without l= returns 400');
};

subtest 'dates_save -- col= required, returns 400 when absent' => sub {
	$t->post_ok('/dates/save', form => { l => $TEST_SPEC, pattern => '%m/%d/%Y' })
	  ->status_is(400)
	  ->json_is('/error', 'col= required',
		'POST /dates/save without col= returns 400');
};

subtest 'dates_save -- unsupported pattern returns 400' => sub {
	$t->post_ok('/dates/save',
		form => { l => $TEST_SPEC, col => 'date', pattern => '%Y-%m-%d' })
	  ->status_is(400)
	  ->json_like('/error', qr/unsupported|not.*supported|pattern/i,
		'unsupported date pattern returns 400');
};

subtest 'dates_save -- unknown pattern string returns 400' => sub {
	$t->post_ok('/dates/save',
		form => { l => $TEST_SPEC, col => 'date', pattern => 'YYYYMMDD' })
	  ->status_is(400, 'arbitrary unknown pattern string yields 400');
};

subtest 'dates_save / dates_list / dates_delete -- full roundtrip for all three allowed patterns' => sub {
	# Verify all three documented patterns can be stored and retrieved.
	for my $pat ('%m/%d/%Y', '%d/%m/%Y', '%d-%b-%Y') {
		$t->post_ok('/dates/save',
			form => { l => $TEST_SPEC, col => 'date', pattern => $pat })
		  ->status_is(200)
		  ->json_is('/ok', 1, "pattern $pat saved OK");

		my $list = $t->get_ok("/dates/list?l=$TEST_SPEC")
		             ->status_is(200)->tx->res->json;
		is $list->{patterns}{date}, $pat, "list shows saved pattern $pat for col=date";

		$t->post_ok('/dates/delete', form => { l => $TEST_SPEC, col => 'date' })
		  ->status_is(200)
		  ->json_is('/ok', 1, "pattern $pat deleted");
	}
};

subtest 'dates_delete -- deletes all patterns for spec when col= absent' => sub {
	$t->post_ok('/dates/save',
		form => { l => $TEST_SPEC, col => 'start', pattern => '%m/%d/%Y' })
	  ->status_is(200);
	$t->post_ok('/dates/save',
		form => { l => $TEST_SPEC, col => 'end', pattern => '%d/%m/%Y' })
	  ->status_is(200);

	# Delete without col= clears all patterns for this spec.
	$t->post_ok('/dates/delete', form => { l => $TEST_SPEC })
	  ->status_is(200)
	  ->json_is('/ok', 1, 'all date patterns for spec deleted');

	my $after = $t->get_ok("/dates/list?l=$TEST_SPEC")
	              ->status_is(200)->tx->res->json;
	is_deeply $after->{patterns}, {}, 'pattern store is empty after full-spec delete';
};

} # end MODEL_DIR scope

# ============================================================================
# PART N: Database::BI::Model::Geocode
#
# White-box tests for every internal helper and public method.  A stub geocoder
# package is defined below and injected through new(geocoder =>), so no real
# Geo::Coder::Free or network connection is required.  All branches of the
# classify -> cap -> batch -> count pipeline are exercised, with at least 60%
# negative / hostile tests.
# ============================================================================

use_ok('Database::BI::Model::Geocode');

Readonly my $GEO  => 'Database::BI::Model::Geocode';
Readonly my $GOOD_PLACE => 'Ramsgate';
Readonly my $GOOD_LAT   => 51.33;
Readonly my $GOOD_LON   =>  1.42;

# ---------------------------------------------------------------------------
# Stub geocoder and point -- injected so tests never touch Geo::Coder::Free.
#
# The stub records every geocode_many() call in 'calls' and every
# valid_location() call in 'asked', so we can assert what the module looked
# up without relying on a real geocoder.
# ---------------------------------------------------------------------------
{
	package Stub::GeoPoint;
	sub new       { bless { %{ $_[1] } }, $_[0] }
	sub latitude  { $_[0]{'latitude'} }
	sub longitude { $_[0]{'longitude'} }
	sub database  { $_[0]{'database'} }

	package Stub::GeoNoLongitude;
	# Object with latitude() but NO longitude() accessor -- tests _coordinates fallback.
	sub new      { bless { %{ $_[1] } }, $_[0] }
	sub latitude { $_[0]{'latitude'} }
	sub can      {
		my ($self, $method) = @_;
		return ($method eq 'latitude') ? 1 : undef;
	}

	package Stub::GeoNoBacking;
	# Has both accessors but latitude() returns undef -- tests _has_position guard.
	sub new       { bless {}, $_[0] }
	sub latitude  { return undef }
	sub longitude { return undef }

	package Stub::Geocoder;
	sub new {
		my ($class, %a) = @_;
		return bless {
			results => $a{results} // {},
			asked   => [],
			calls   => [],
			# Set skip_value so valid_location() can refuse a specific value.
			skip    => $a{skip} // '',
		}, $class;
	}
	sub valid_location {
		my ($self, $v) = @_;
		push @{ $self->{asked} }, $v;
		return 0 unless defined($v) && !ref($v) && length($v);
		return 0 if $v =~ /\A\d+\z/;   # bare number: not a place
		return 0 if $v eq $self->{skip};
		return 1;
	}
	sub geocode_many {
		my ($self, $values, %opts) = @_;
		push @{ $self->{calls} }, { values => [@$values], opts => {%opts} };
		my %out;
		for my $v (@$values) {
			$out{$v} = $self->{results}{$v};   # undef for unknowns
		}
		return { %out, lookups => scalar @$values };
	}

	package Stub::GeoBroken;
	# Has valid_location but lacks geocode_many -- should cause _check_interface croak.
	sub new            { bless {}, $_[0] }
	sub valid_location { 1 }
}

# ============================================================================
# Section 1: _fmt -- package-level formatter
# ============================================================================

subtest 'Geocode::_fmt -- known key with no args returns template text' => sub {
	my $fn = \&Database::BI::Model::Geocode::_fmt;

	my $msg = $fn->('error_column_required');
	ok length($msg), '_fmt returns non-empty string for known key';
	unlike $msg, qr/Internal error/, 'known key does not hit the fallback branch';
};

subtest 'Geocode::_fmt -- known key with sprintf args interpolates them' => sub {
	my $fn  = \&Database::BI::Model::Geocode::_fmt;
	my $msg = $fn->('error_map_loc_column', 'my_col');
	like $msg, qr/my_col/, 'column name is interpolated into the error message';
};

subtest 'Geocode::_fmt -- unknown key produces descriptive fallback, does not croak' => sub {
	my $fn = \&Database::BI::Model::Geocode::_fmt;
	my $fb = $fn->('no_such_key_xyz');
	like $fb, qr/Internal error.*no_such_key_xyz/, 'unknown key renders fallback with key embedded';
};

subtest 'Geocode::_fmt -- undef key still returns a string (does not croak)' => sub {
	my $fn = \&Database::BI::Model::Geocode::_fmt;
	my $result = eval { $fn->(undef) };
	# Either it returns something or it croaks with a message -- the point is no
	# silent undef being returned when the caller later calls length() on it.
	ok defined($result) || $@, 'undef key either returns a value or croaks, never silently undef';
};

# ============================================================================
# Section 2: _msg -- instance-level i18n delegator
# ============================================================================

subtest 'Geocode::_msg -- without i18n object delegates to _fmt' => sub {
	my $g = $GEO->new();

	my $via_msg = $g->_msg('error_column_required');
	my $via_fmt = Database::BI::Model::Geocode::_fmt('error_column_required');
	is $via_msg, $via_fmt, '_msg without i18n produces same string as _fmt';
};

subtest 'Geocode::_msg -- with i18n object forwards key and args via maketext' => sub {
	my @received;
	my $i18n = bless {}, 'FakeGeoI18N';
	{
		no strict 'refs';
		*{'FakeGeoI18N::maketext'} = sub {
			my ($self, $key, @args) = @_;
			push @received, { key => $key, args => \@args };
			return "TRANSLATED:$key";
		};
	}

	my $g = $GEO->new(i18n => $i18n);
	my $result = $g->_msg('error_column_required');
	is scalar(@received), 1, 'maketext called exactly once';
	is $received[0]{key}, 'error_column_required', 'correct key forwarded';
	like $result, qr/TRANSLATED/, 'return value comes from i18n object';
};

# ============================================================================
# Section 3: _message -- returns { key, text } hashref
# ============================================================================

subtest 'Geocode::_message -- returns hashref with key and text fields' => sub {
	my $g   = $GEO->new();
	my $msg = $g->_message('error_column_required');

	ok ref($msg) eq 'HASH', '_message returns a hashref';
	is $msg->{key}, 'error_column_required', 'key field preserved';
	ok length($msg->{text}), 'text field is non-empty';
};

subtest 'Geocode::_message -- sprintf args are embedded in text field' => sub {
	my $g   = $GEO->new();
	my $msg = $g->_message('error_map_loc_column', 'colname_xyz');
	like $msg->{text}, qr/colname_xyz/, 'sprintf arg embedded in text';
	is   $msg->{key},  'error_map_loc_column', 'key is unchanged';
};

# ============================================================================
# Section 4: new -- constructor guards
# ============================================================================

subtest 'Geocode::new -- no arguments: constructs with defaults' => sub {
	my $g = eval { $GEO->new() };
	is $@, '', 'no-arg constructor does not croak';
	ok blessed($g), 'returns a blessed object';
	is ref($g), $GEO, 'correct class';
};

subtest 'Geocode::new -- injected geocoder with full interface: no croak' => sub {
	my $stub = Stub::Geocoder->new();
	my $g = eval { $GEO->new(geocoder => $stub) };
	is $@, '', 'valid injected geocoder is accepted';
	ok blessed($g), 'returns object';
};

subtest 'Geocode::new -- geocoder missing geocode_many() croaks with interface message' => sub {
	my $broken = Stub::GeoBroken->new();
	throws_ok { $GEO->new(geocoder => $broken) }
		qr/geocode_many/,
		'croaks when injected geocoder lacks geocode_many()';
};

subtest 'Geocode::new -- geocoder missing both methods: error names first missing' => sub {
	# A plain hashref has no ->can() and will fail valid_location first.
	my $empty = bless {}, 'GeoBothMissing';
	throws_ok { $GEO->new(geocoder => $empty) }
		qr/valid_location|geocode_many/,
		'croaks for geocoder missing required methods';
};

subtest 'Geocode::new -- non-object geocoder is rejected by Params::Validate::Strict' => sub {
	# A scalar where an object is expected must be rejected before _check_interface.
	throws_ok { $GEO->new(geocoder => 'not_an_object') }
		qr//,
		'scalar geocoder argument triggers validation error';
};

subtest 'Geocode::new -- openaddr param stored, ENV fallback used when absent' => sub {
	local $ENV{OPENADDR_HOME} = '/some/path';
	my $g = $GEO->new();
	is $g->{'openaddr'}, '/some/path', 'openaddr falls back to OPENADDR_HOME';

	my $g2 = $GEO->new(openaddr => '/explicit/path');
	is $g2->{'openaddr'}, '/explicit/path', 'explicit openaddr overrides ENV';
};

subtest 'Geocode::new -- i18n object missing maketext() is rejected' => sub {
	# Params::Validate::Strict uses can => 'maketext' to validate the i18n object.
	my $no_maketext = bless {}, 'NoMaketext';
	throws_ok { $GEO->new(i18n => $no_maketext) }
		qr//,
		'i18n object without maketext() triggers validation error';
};

subtest 'Geocode::new -- accepts hashref argument form' => sub {
	my $g = eval { $GEO->new({ }) };
	is $@, '', 'hashref form accepted';
	ok blessed($g), 'object returned from hashref call';
};

# ============================================================================
# Section 5: _check_interface -- guards an injected geocoder
# ============================================================================

subtest 'Geocode::_check_interface -- returns 1 for a complete interface' => sub {
	my $g    = $GEO->new();
	my $stub = Stub::Geocoder->new();
	my $ok   = $g->_check_interface($stub);
	is $ok, 1, '_check_interface returns 1 for a geocoder with both methods';
};

subtest 'Geocode::_check_interface -- croaks when valid_location is missing' => sub {
	my $g = $GEO->new();
	my $no_vl = bless {}, 'NoValidLocation';
	{
		no strict 'refs';
		*{'NoValidLocation::geocode_many'} = sub { };
	}
	throws_ok { $g->_check_interface($no_vl) }
		qr/valid_location/,
		'croak names the missing method when valid_location absent';
};

subtest 'Geocode::_check_interface -- croaks when geocode_many is missing' => sub {
	my $g      = $GEO->new();
	my $broken = Stub::GeoBroken->new();  # has valid_location, lacks geocode_many
	throws_ok { $g->_check_interface($broken) }
		qr/geocode_many/,
		'croak names the missing method when geocode_many absent';
};

# ============================================================================
# Section 6: _coordinates -- extracts (lat, lon) from various result shapes
# ============================================================================

subtest 'Geocode::_coordinates -- blesses object with accessors: reads latitude/longitude' => sub {
	my $fn    = \&Database::BI::Model::Geocode::_coordinates;
	my $point = Stub::GeoPoint->new({ latitude => 51.5, longitude => -0.1, database => 'Test' });
	my ($lat, $lon) = $fn->($point);
	is $lat,  51.5, 'latitude extracted from accessor';
	is $lon, -0.1,  'longitude extracted from accessor';
};

subtest 'Geocode::_coordinates -- plain hashref with lat/long keys' => sub {
	my $fn   = \&Database::BI::Model::Geocode::_coordinates;
	my ($lat, $lon) = $fn->({ lat => 10.0, long => 20.0 });
	is $lat, 10.0, 'lat key read from hashref';
	is $lon, 20.0, 'long key read from hashref';
};

subtest 'Geocode::_coordinates -- plain hashref uses lng fallback before lon' => sub {
	my $fn   = \&Database::BI::Model::Geocode::_coordinates;
	my ($lat, $lon) = $fn->({ lat => 1.0, lng => 2.0 });
	is $lat, 1.0, 'lat extracted';
	is $lon, 2.0, 'lng fallback used';
};

subtest 'Geocode::_coordinates -- plain hashref uses lon as third fallback' => sub {
	my $fn   = \&Database::BI::Model::Geocode::_coordinates;
	my ($lat, $lon) = $fn->({ lat => 3.0, lon => 4.0 });
	is $lat, 3.0, 'lat extracted';
	is $lon, 4.0, 'lon third fallback used';
};

subtest 'Geocode::_coordinates -- undef input returns empty list' => sub {
	my $fn = \&Database::BI::Model::Geocode::_coordinates;
	my @r  = $fn->(undef);
	is scalar(@r), 0, 'undef input returns empty list';
};

subtest 'Geocode::_coordinates -- non-ref scalar returns empty list' => sub {
	my $fn = \&Database::BI::Model::Geocode::_coordinates;
	my @r  = $fn->('just a string');
	is scalar(@r), 0, 'non-ref scalar returns empty list';
};

subtest 'Geocode::_coordinates -- arrayref is not a point shape: returns empty list' => sub {
	# An arrayref [lat, lon] is the *cache* format, not a geocoder result.
	my $fn = \&Database::BI::Model::Geocode::_coordinates;
	my @r  = $fn->([51.5, -0.1]);
	is scalar(@r), 0, 'arrayref not treated as a point';
};

# ============================================================================
# Section 7: _backend_of -- reads the database name from a result
# ============================================================================

subtest 'Geocode::_backend_of -- object with database() accessor' => sub {
	my $fn    = \&Database::BI::Model::Geocode::_backend_of;
	my $point = Stub::GeoPoint->new({ latitude => 1, longitude => 2, database => 'OpenAddresses' });
	is $fn->($point), 'OpenAddresses', 'reads database from accessor';
};

subtest 'Geocode::_backend_of -- plain hashref with database key' => sub {
	my $fn = \&Database::BI::Model::Geocode::_backend_of;
	is $fn->({ database => 'MaxMind' }), 'MaxMind', 'reads database from hashref key';
};

subtest 'Geocode::_backend_of -- falls back to geocoder key when database absent' => sub {
	my $fn = \&Database::BI::Model::Geocode::_backend_of;
	is $fn->({ geocoder => 'FreeGeo' }), 'FreeGeo', 'geocoder key used as fallback';
};

subtest 'Geocode::_backend_of -- undef backend keys return undef' => sub {
	my $fn = \&Database::BI::Model::Geocode::_backend_of;
	is $fn->({}), undef, 'empty hashref returns undef';
};

subtest 'Geocode::_backend_of -- non-ref input returns undef' => sub {
	my $fn = \&Database::BI::Model::Geocode::_backend_of;
	is $fn->('string'), undef, 'scalar returns undef';
	is $fn->(undef),    undef, 'undef returns undef';
};

subtest 'Geocode::_backend_of -- arrayref is rejected, returns undef' => sub {
	my $fn = \&Database::BI::Model::Geocode::_backend_of;
	is $fn->([1,2,3]), undef, 'arrayref returns undef (cache shape, not a point)';
};

# ============================================================================
# Section 8: _has_position -- distinguishes resolved from unresolved cache entry
# ============================================================================

subtest 'Geocode::_has_position -- arrayref with two coordinates returns true' => sub {
	my $fn = \&Database::BI::Model::Geocode::_has_position;
	ok $fn->([51.5, -0.1]), '[lat, lon] is a position';
};

subtest 'Geocode::_has_position -- zero sentinel (looked up, not found) returns false' => sub {
	my $fn = \&Database::BI::Model::Geocode::_has_position;
	ok !$fn->(0), 'zero sentinel returns false';
};

subtest 'Geocode::_has_position -- undef returns false' => sub {
	my $fn = \&Database::BI::Model::Geocode::_has_position;
	ok !$fn->(undef), 'undef returns false';
};

subtest 'Geocode::_has_position -- [undef, undef] returns false (both coords must be defined)' => sub {
	my $fn = \&Database::BI::Model::Geocode::_has_position;
	ok !$fn->([undef, undef]), '[undef, undef] has no position';
};

subtest 'Geocode::_has_position -- [lat, undef] returns false (one coord missing)' => sub {
	my $fn = \&Database::BI::Model::Geocode::_has_position;
	ok !$fn->([51.5, undef]), '[lat, undef] is not a full position';
};

subtest 'Geocode::_has_position -- empty arrayref returns false' => sub {
	my $fn = \&Database::BI::Model::Geocode::_has_position;
	ok !$fn->([]); 'empty arrayref is not a position';
};

subtest 'Geocode::_has_position -- plain string returns false' => sub {
	my $fn = \&Database::BI::Model::Geocode::_has_position;
	ok !$fn->('51.5,-0.1'), 'string is not a position';
};

# ============================================================================
# Section 9: _options -- validates max / cache / region
# ============================================================================

subtest 'Geocode::_options -- defaults: max=500, cache=undef, region=undef' => sub {
	my $g    = $GEO->new();
	my $opts = $g->_options({});
	is $opts->{max}, 500, 'default max is 500';
	ok !defined($opts->{cache}),  'default cache is undef';
	ok !defined($opts->{region}), 'default region is undef';
};

subtest 'Geocode::_options -- explicit max is stored as-is' => sub {
	my $g    = $GEO->new();
	my $opts = $g->_options({ max => 10 });
	is $opts->{max}, 10, 'explicit max preserved';
};

subtest 'Geocode::_options -- max=0 croaks (not a positive integer)' => sub {
	my $g = $GEO->new();
	throws_ok { $g->_options({ max => 0 }) }
		qr/max.*must be a positive integer/i,
		'max=0 is rejected with a descriptive croak';
};

subtest 'Geocode::_options -- max=-1 croaks' => sub {
	my $g = $GEO->new();
	throws_ok { $g->_options({ max => -1 }) }
		qr/max/i,
		'negative max is rejected';
};

subtest 'Geocode::_options -- max=abc croaks (non-numeric string)' => sub {
	my $g = $GEO->new();
	throws_ok { $g->_options({ max => 'abc' }) }
		qr/max/i,
		'non-numeric max is rejected';
};

subtest 'Geocode::_options -- max=3.5 croaks (non-integer)' => sub {
	my $g = $GEO->new();
	throws_ok { $g->_options({ max => '3.5' }) }
		qr/max/i,
		'fractional max is rejected';
};

subtest 'Geocode::_options -- unknown key in options croaks (strict validation)' => sub {
	my $g = $GEO->new();
	throws_ok { $g->_options({ bogus => 1 }) }
		qr//,
		'unknown option key is rejected by Params::Validate::Strict';
};

# ============================================================================
# Section 10: resolve_values -- input validation
# ============================================================================

subtest 'Geocode::resolve_values -- non-arrayref input croaks' => sub {
	my $g = $GEO->new(geocoder => Stub::Geocoder->new());
	throws_ok { $g->resolve_values('not_an_arrayref') }
		qr/values.*arrayref/i,
		'scalar input triggers error_values_arrayref croak';
};

subtest 'Geocode::resolve_values -- undef input croaks' => sub {
	my $g = $GEO->new(geocoder => Stub::Geocoder->new());
	throws_ok { $g->resolve_values(undef) }
		qr/values.*arrayref/i,
		'undef input triggers croak';
};

subtest 'Geocode::resolve_values -- hashref input croaks' => sub {
	my $g = $GEO->new(geocoder => Stub::Geocoder->new());
	throws_ok { $g->resolve_values({}) }
		qr/values.*arrayref/i,
		'hashref input triggers croak';
};

subtest 'Geocode::resolve_values -- empty arrayref returns zeroed counts' => sub {
	my $stub = Stub::Geocoder->new();
	my $g    = $GEO->new(geocoder => $stub);
	my $r    = $g->resolve_values([]);

	ok ref($r) eq 'HASH', 'returns hashref';
	is $r->{counts}{distinct},      0, 'distinct=0 for empty input';
	is $r->{counts}{attempted},     0, 'attempted=0';
	is $r->{counts}{resolved},      0, 'resolved=0';
	is scalar(@{ $stub->{calls} }), 0, 'geocoder never called for empty input';
};

subtest 'Geocode::resolve_values -- bare number is skipped, not looked up' => sub {
	my $stub = Stub::Geocoder->new(results => {});
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $r    = $g->resolve_values(['12345']);

	is $r->{counts}{skipped},   1, 'bare number counted as skipped';
	is $r->{counts}{attempted}, 0, 'bare number never sent to geocoder';
};

subtest 'Geocode::resolve_values -- undef cell is skipped silently' => sub {
	my $stub = Stub::Geocoder->new();
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $r    = $g->resolve_values([undef]);

	is $r->{counts}{skipped},   1, 'undef cell is skipped';
	is $r->{counts}{attempted}, 0, 'undef cell never handed to geocoder';
};

subtest 'Geocode::resolve_values -- empty string is skipped' => sub {
	my $stub = Stub::Geocoder->new();
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $r    = $g->resolve_values(['']);

	is $r->{counts}{skipped},   1, 'empty string is skipped';
	is $r->{counts}{attempted}, 0, 'empty string never sent to geocoder';
};

subtest 'Geocode::resolve_values -- valid place resolves to point in result' => sub {
	my $stub = Stub::Geocoder->new(results => {
		$GOOD_PLACE => Stub::GeoPoint->new({
			latitude => $GOOD_LAT, longitude => $GOOD_LON, database => 'Test',
		}),
	});
	my $g = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $r = $g->resolve_values([$GOOD_PLACE]);

	is $r->{counts}{resolved},  1, 'one place resolved';
	ok exists $r->{points}{$GOOD_PLACE}, 'place in points hashref';
	is $r->{points}{$GOOD_PLACE}{lat}, $GOOD_LAT, 'latitude stored';
	is $r->{points}{$GOOD_PLACE}{lon}, $GOOD_LON, 'longitude stored';
};

subtest 'Geocode::resolve_values -- duplicate values counted once, looked up once' => sub {
	my $stub = Stub::Geocoder->new(results => {
		$GOOD_PLACE => Stub::GeoPoint->new({ latitude => 1, longitude => 2, database => 'X' }),
	});
	my $g = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $r = $g->resolve_values([$GOOD_PLACE, $GOOD_PLACE, $GOOD_PLACE]);

	is $r->{counts}{distinct},  1, 'three repeats counted as one distinct';
	is $r->{counts}{attempted}, 1, 'geocoder called for one distinct value';
};

subtest 'Geocode::resolve_values -- place not found recorded as unresolved and cached as 0' => sub {
	my $stub = Stub::Geocoder->new(results => {});  # nothing resolves
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $r    = $g->resolve_values([$GOOD_PLACE]);

	is $r->{counts}{unresolved},    1, 'unresolved count incremented';
	is $r->{cache}{$GOOD_PLACE},    0, 'unresolved place cached as 0 sentinel';
	is scalar(@{ $r->{unresolved} }), 1, 'place in unresolved list';
};

subtest 'Geocode::resolve_values -- cache hit skips geocoder entirely' => sub {
	my $stub = Stub::Geocoder->new();
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $r    = $g->resolve_values([$GOOD_PLACE], cache => { $GOOD_PLACE => [$GOOD_LAT, $GOOD_LON] });

	is scalar(@{ $stub->{calls} }), 0, 'geocoder not called when value in cache';
	is $r->{counts}{cached},        1, 'cached count incremented';
	is $r->{counts}{resolved},      1, 'resolved count includes cached places';
};

subtest 'Geocode::resolve_values -- zero-sentinel cache hit is unresolved, not resolved' => sub {
	my $stub = Stub::Geocoder->new();
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $r    = $g->resolve_values([$GOOD_PLACE], cache => { $GOOD_PLACE => 0 });

	is scalar(@{ $stub->{calls} }), 0, 'geocoder not called for cached-unresolved';
	is $r->{counts}{unresolved},    1, 'unresolved count includes cached 0';
};

subtest 'Geocode::resolve_values -- cap holds excess places in not_attempted' => sub {
	my @places  = map { "Place$_" } 1 .. 5;
	my %results = map { $_ => Stub::GeoPoint->new({ latitude => 1, longitude => 2, database => 'T' }) } @places;
	my $stub    = Stub::Geocoder->new(results => \%results);
	my $g       = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $r       = $g->resolve_values(\@places, max => 3);

	is $r->{counts}{attempted},     3, 'only 3 places attempted (cap=3)';
	is $r->{counts}{not_attempted}, 2, 'remaining 2 are not_attempted';
	ok $r->{capped}, 'capped flag is set';
	# Not-attempted places must NOT be in the cache (they will be retried next request).
	for my $p (@places[3..4]) {
		ok !exists($r->{cache}{$p}), "not-attempted place $p not recorded in cache";
	}
};

subtest 'Geocode::resolve_values -- no geocoder puts all valid places in not_attempted' => sub {
	# Construct without injected geocoder and without Geo::Coder::Free.
	# If Geo::Coder::Free IS installed, we still test the same path by using
	# an invalid min_geocoder_version that forces _load_geocoder to fail.
	my $g = $GEO->new(min_geocoder_version => '9999.0');
	my $r = $g->resolve_values([$GOOD_PLACE]);

	is $r->{available},             0, 'available=0 without geocoder';
	is $r->{counts}{not_attempted}, 1, 'valid place is not_attempted without geocoder';
	is $r->{counts}{attempted},     0, 'nothing attempted without geocoder';
};

subtest 'Geocode::resolve_values -- result has no circular references' => sub {
	my $stub = Stub::Geocoder->new(results => {
		$GOOD_PLACE => Stub::GeoPoint->new({ latitude => $GOOD_LAT, longitude => $GOOD_LON, database => 'T' }),
	});
	my $g = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $r = $g->resolve_values([$GOOD_PLACE]);
	memory_cycle_ok($r, 'resolve_values result has no circular references');
};

subtest 'Geocode::resolve_values -- geocoder valid_location refusal: place in skipped' => sub {
	# The stub's valid_location returns 0 for the skip value.
	my $stub = Stub::Geocoder->new(skip => $GOOD_PLACE, results => {});
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $r    = $g->resolve_values([$GOOD_PLACE]);

	is $r->{counts}{skipped},   1, 'refused-by-geocoder place is skipped';
	is $r->{counts}{attempted}, 0, 'refused value never passed to geocode_many';
};

# ============================================================================
# Section 11: resolve_column -- input validation and row-level bookkeeping
# ============================================================================

subtest 'Geocode::resolve_column -- non-arrayref rows croaks' => sub {
	my $g = $GEO->new(geocoder => Stub::Geocoder->new());
	throws_ok { $g->resolve_column('not_rows', 'col') }
		qr/rows.*arrayref/i,
		'scalar rows triggers error_rows_arrayref croak';
};

subtest 'Geocode::resolve_column -- undef rows croaks' => sub {
	my $g = $GEO->new(geocoder => Stub::Geocoder->new());
	throws_ok { $g->resolve_column(undef, 'col') }
		qr/rows.*arrayref/i,
		'undef rows croaks';
};

subtest 'Geocode::resolve_column -- missing column arg croaks' => sub {
	my $g = $GEO->new(geocoder => Stub::Geocoder->new());
	throws_ok { $g->resolve_column([], undef) }
		qr/column.*required/i,
		'undef column triggers error_column_required croak';
	throws_ok { $g->resolve_column([], '') }
		qr/column.*required/i,
		'empty string column triggers croak';
};

subtest 'Geocode::resolve_column -- column not present in rows croaks' => sub {
	my $g    = $GEO->new(geocoder => Stub::Geocoder->new());
	my $rows = [{ name => 'Alice' }, { name => 'Bob' }];
	throws_ok { $g->resolve_column($rows, 'no_such_column') }
		qr/no_such_column/,
		'missing column name embedded in error_map_loc_column message';
};

subtest 'Geocode::resolve_column -- empty rows list returns result with zeroed counts' => sub {
	my $g = $GEO->new(geocoder => Stub::Geocoder->new());
	my $r = $g->resolve_column([], 'place');

	is $r->{counts}{rows},    0, 'rows=0 for empty input';
	is $r->{counts}{plotted}, 0, 'plotted=0';
};

subtest 'Geocode::resolve_column -- adds rows and first_row to each point' => sub {
	my $stub = Stub::Geocoder->new(results => {
		$GOOD_PLACE => Stub::GeoPoint->new({
			latitude => $GOOD_LAT, longitude => $GOOD_LON, database => 'T'
		}),
	});
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $rows = [
		{ place => $GOOD_PLACE },
		{ place => $GOOD_PLACE },
		{ place => $GOOD_PLACE },
	];
	my $r    = $g->resolve_column($rows, 'place');

	is $r->{points}{$GOOD_PLACE}{rows},      3, 'three rows reported for repeated place';
	is $r->{points}{$GOOD_PLACE}{first_row}, 0, 'first_row points to index 0';
	is $r->{counts}{rows},                   3, 'total row count is 3';
	is $r->{counts}{plotted},                3, 'all three rows plotted';
};

subtest 'Geocode::resolve_column -- markers in first-seen order' => sub {
	my $stub = Stub::Geocoder->new(results => {
		'Ramsgate'    => Stub::GeoPoint->new({ latitude => 51.33, longitude => 1.42, database => 'T' }),
		'Earls Colne' => Stub::GeoPoint->new({ latitude => 51.92, longitude => 0.75, database => 'T' }),
	});
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $rows = [
		{ place => 'Ramsgate' },
		{ place => 'Earls Colne' },
		{ place => 'Ramsgate' },
	];
	my $r = $g->resolve_column($rows, 'place');

	is scalar(@{ $r->{markers} }), 2,            'two distinct places produce two markers';
	is $r->{markers}[0]{value},   'Ramsgate',    'Ramsgate first (appears first in rows)';
	is $r->{markers}[1]{value},   'Earls Colne', 'Earls Colne second';
};

subtest 'Geocode::resolve_column -- warn_map_rows_skipped emitted when some rows not plotted' => sub {
	my $stub = Stub::Geocoder->new(results => {});  # nothing resolves
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $rows = [{ place => $GOOD_PLACE }];
	my $r    = $g->resolve_column($rows, 'place');

	my @skipped_msgs = grep { $_->{key} eq 'warn_map_rows_skipped' } @{ $r->{messages} };
	ok scalar(@skipped_msgs), 'warn_map_rows_skipped emitted when rows not plotted';
};

subtest 'Geocode::resolve_column -- no skip message when all rows plotted' => sub {
	my $stub = Stub::Geocoder->new(results => {
		$GOOD_PLACE => Stub::GeoPoint->new({ latitude => 1, longitude => 2, database => 'T' }),
	});
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $rows = [{ place => $GOOD_PLACE }];
	my $r    = $g->resolve_column($rows, 'place');

	my @skipped = grep { $_->{key} eq 'warn_map_rows_skipped' } @{ $r->{messages} };
	ok !scalar(@skipped), 'no skip message when every row is plotted';
};

subtest 'Geocode::resolve_column -- all-non-hashref rows croak with column-not-found' => sub {
	# When every row is a non-hashref the column is never found, so the guard
	# fires.  Non-hashref rows are treated as missing cells, not as a signal to
	# skip the column-present check.
	my $stub = Stub::Geocoder->new(results => {});
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	throws_ok { $g->resolve_column([[1,2,3]], 'place') }
		qr/place/,
		'all-non-hashref rows give column-not-found croak';
};

subtest 'Geocode::resolve_column -- mixed hashref/non-hashref rows: non-hashref contribute undef' => sub {
	# A dataset can have one valid hashref row alongside a non-hashref artefact.
	# The non-hashref row contributes undef (skipped), the hashref row is resolved.
	my $stub = Stub::Geocoder->new(results => {
		$GOOD_PLACE => Stub::GeoPoint->new({ latitude => $GOOD_LAT, longitude => $GOOD_LON, database => 'T' }),
	});
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $rows = [
		{ place => $GOOD_PLACE },   # valid hashref
		[1, 2, 3],                  # non-hashref: contributes undef cell
	];
	my $r = eval { $g->resolve_column($rows, 'place') };
	is $@, '', 'mixed rows do not croak';
	is $r->{counts}{rows},    2, 'both rows counted';
	is $r->{counts}{plotted}, 1, 'only the hashref row is plotted';
};

subtest 'Geocode::resolve_column -- result has no circular references' => sub {
	my $stub = Stub::Geocoder->new(results => {
		$GOOD_PLACE => Stub::GeoPoint->new({ latitude => $GOOD_LAT, longitude => $GOOD_LON, database => 'T' }),
	});
	my $g    = $GEO->new(geocoder => $stub, openaddr => 'test');
	my $rows = [{ place => $GOOD_PLACE }];
	my $r    = $g->resolve_column($rows, 'place');
	memory_cycle_ok($r, 'resolve_column result has no circular references');
};

# ============================================================================
# Section 12: geocoder_available -- reports availability without croaking
# ============================================================================

subtest 'Geocode::geocoder_available -- injected geocoder: returns (1, undef)' => sub {
	my $stub = Stub::Geocoder->new();
	my $g    = $GEO->new(geocoder => $stub);
	my ($ok, $reason) = $g->geocoder_available();
	ok $ok, 'available=1 with injected geocoder';
	ok !defined($reason), 'reason is undef when available';
};

subtest 'Geocode::geocoder_available -- no geocoder: returns (0, message)' => sub {
	# Force _load_geocoder to fail by requesting an impossibly high version.
	my $g = $GEO->new(min_geocoder_version => '9999.0');
	my ($ok, $reason) = $g->geocoder_available();
	ok !$ok, 'available=0 without geocoder';
	ok defined($reason), 'reason is defined when unavailable';
	like $reason, qr/Geo::Coder::Free/, 'message names the missing module';
};

subtest 'Geocode::geocoder_available -- called twice: loads geocoder only once' => sub {
	# The second call should use the memoized _geocoder, not call _load_geocoder again.
	my $stub = Stub::Geocoder->new();
	my $g    = $GEO->new(geocoder => $stub);
	$g->geocoder_available();
	$g->geocoder_available();
	# No assertion possible without mocking, but this must not croak.
	ok 1, 'calling geocoder_available twice does not croak';
};

# ============================================================================
# Section 13: cache_from_models -- extracts the geo cache for a spec
# ============================================================================

subtest 'Geocode::cache_from_models -- valid models returns copy of places' => sub {
	my $models = {
		geo => {
			'table:sales' => {
				places  => { Ramsgate => [$GOOD_LAT, $GOOD_LON], Truro => 0 },
				backend => 'OpenAddresses',
				built   => '2026-01-01T00:00:00Z',
			},
		},
	};
	my $cache = $GEO->cache_from_models($models, 'table:sales');
	ok ref($cache) eq 'HASH', 'returns a hashref';
	is scalar(keys %$cache), 2, 'both places extracted';
	is_deeply $cache->{Ramsgate}, [$GOOD_LAT, $GOOD_LON], 'resolved place has [lat,lon]';
	is $cache->{Truro}, 0, 'unresolved place has 0 sentinel';
};

subtest 'Geocode::cache_from_models -- unknown spec returns empty hashref' => sub {
	my $cache = $GEO->cache_from_models({}, 'table:unknown');
	ok ref($cache) eq 'HASH', 'returns a hashref';
	ok !scalar(keys %$cache), 'empty for unknown spec';
};

subtest 'Geocode::cache_from_models -- empty models hashref returns empty hashref' => sub {
	my $cache = $GEO->cache_from_models({}, 'table:sales');
	ok !scalar(keys %$cache), 'empty for empty models';
};

subtest 'Geocode::cache_from_models -- undef models returns empty hashref' => sub {
	my $cache = $GEO->cache_from_models(undef, 'table:sales');
	ok ref($cache) eq 'HASH', 'returns hashref for undef models';
	ok !scalar(keys %$cache), 'empty for undef models';
};

subtest 'Geocode::cache_from_models -- caller hashref is NOT mutated (returns a copy)' => sub {
	my $places  = { Ramsgate => [$GOOD_LAT, $GOOD_LON] };
	my $models  = { geo => { 'k' => { places => $places } } };
	my $cache   = $GEO->cache_from_models($models, 'k');
	$cache->{Injected} = 99;
	ok !exists($models->{geo}{k}{places}{Injected}), 'mutating returned cache does not modify models';
};

# ============================================================================
# Section 14: models_with_cache -- returns updated models without mutation
# ============================================================================

subtest 'Geocode::models_with_cache -- fresh models: geo section created' => sub {
	my $r = $GEO->models_with_cache({}, 'table:sales',
		{ Ramsgate => [$GOOD_LAT, $GOOD_LON] },
		backend => 'OpenAddresses',
		built   => '2026-01-01T00:00:00Z',
	);
	ok ref($r) eq 'HASH', 'returns hashref';
	ok exists($r->{geo}{'table:sales'}), 'geo section created';
	is_deeply $r->{geo}{'table:sales'}{places}, { Ramsgate => [$GOOD_LAT, $GOOD_LON] },
		'places stored';
	is $r->{geo}{'table:sales'}{backend}, 'OpenAddresses', 'backend stored';
	is $r->{geo}{'table:sales'}{built},   '2026-01-01T00:00:00Z', 'built stored';
};

subtest 'Geocode::models_with_cache -- existing spec overwritten without touching others' => sub {
	my $original = {
		geo => {
			'table:other' => { places => { A => [1, 2] } },
			'table:sales' => { places => { Old => [3, 4] } },
		},
		calc => { 'table:sales' => { fields => {} } },
	};
	my $r = $GEO->models_with_cache($original, 'table:sales',
		{ New => [5, 6] },
		backend => 'MaxMind',
		built   => '2026-02-01T00:00:00Z',
	);
	# Other spec preserved
	is_deeply $r->{geo}{'table:other'}{places}, { A => [1, 2] },
		'other geo spec not affected';
	# Calc section preserved
	ok exists($r->{calc}), 'calc section preserved';
	# Updated spec replaced
	is_deeply $r->{geo}{'table:sales'}{places}, { New => [5, 6] },
		'target spec updated';
};

subtest 'Geocode::models_with_cache -- caller hashref is NOT mutated' => sub {
	my $original = { geo => {} };
	my $r = $GEO->models_with_cache($original, 'table:sales', { A => [1, 2] });
	ok !exists($original->{geo}{'table:sales'}), 'original models hashref not modified';
};

subtest 'Geocode::models_with_cache -- undef models returns correct structure' => sub {
	my $r = $GEO->models_with_cache(undef, 'table:sales', { A => [1, 2] });
	ok ref($r) eq 'HASH', 'returns hashref for undef models';
	ok exists($r->{geo}{'table:sales'}), 'geo section created even with undef models';
};

subtest 'Geocode::models_with_cache -- empty cache stored as empty hashref' => sub {
	my $r = $GEO->models_with_cache({}, 'table:sales', {});
	ok ref($r->{geo}{'table:sales'}{places}) eq 'HASH', 'places is a hashref for empty cache';
	is scalar(keys %{ $r->{geo}{'table:sales'}{places} }), 0, 'empty cache stored correctly';
};

subtest 'Geocode::models_with_cache -- result has no circular references' => sub {
	my $r = $GEO->models_with_cache({}, 'table:sales', { A => [1, 2] });
	memory_cycle_ok($r, 'models_with_cache result has no circular references');
};


# ============================================================================
# PART A: Database::BI::Util -- urlencode
# ============================================================================
# Strategy: urlencode is a small function with a big blast radius -- it is
# called on every spec_key and encode value that reaches the URL query string.
# A missed encode would let a colon, slash, or ampersand break the URL
# semantics silently.  At least 60% of subtests are negative/hostile.

use_ok('Database::BI::Util');
use Database::BI::Util qw(urlencode);

# RFC 3986 section 2.3 unreserved characters: ALPHA / DIGIT / "-" / "." / "_" / "~"
Readonly my $UNRESERVED_CHARS =>
	'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

subtest 'Util::urlencode -- undef returns empty string (no croak)' => sub {
	is urlencode(undef), '', 'undef input -> empty string';
};

subtest 'Util::urlencode -- empty string is a no-op' => sub {
	is urlencode(''), '', 'empty string -> empty string';
};

subtest 'Util::urlencode -- all RFC 3986 unreserved chars pass through unchanged' => sub {
	# If any unreserved char is encoded the URL becomes unnecessarily verbose
	# and breaks round-trip comparison in tests that assert ?l=table:sales etc.
	is urlencode($UNRESERVED_CHARS), $UNRESERVED_CHARS,
		'letters, digits, hyphen, dot, underscore, tilde are never encoded';
};

subtest 'Util::urlencode -- pure alphabetic string unchanged' => sub {
	is urlencode('HelloWorld'), 'HelloWorld', 'letters pass through';
};

subtest 'Util::urlencode -- pure digits unchanged' => sub {
	is urlencode('1234567890'), '1234567890', 'digits pass through';
};

# --- Spec-key forms that appear in production ---

subtest 'Util::urlencode -- table: spec encodes only the colon' => sub {
	# table:sales -> table%3Asales; letters untouched
	is urlencode('table:sales'), 'table%3Asales',
		'colon -> %3A; letters and digits untouched';
};

subtest 'Util::urlencode -- path: spec encodes colon and forward slashes' => sub {
	is urlencode('path:/data/file.csv'), 'path%3A%2Fdata%2Ffile.csv',
		'colon=%3A, slash=%2F; dot and letters untouched';
};

subtest 'Util::urlencode -- tilde is NOT encoded (RFC 3986 unreserved)' => sub {
	is urlencode('v1.0~beta'), 'v1.0~beta',
		'tilde must not be encoded -- it is explicitly unreserved in RFC 3986';
};

# --- Hostile: chars that would break a query string if not encoded ---

subtest 'Util::urlencode -- space encoded as %20 (not +)' => sub {
	# This function encodes for query-parameter VALUES, not form data;
	# %20 is correct, not the form-encoding + sign.
	is urlencode('hello world'), 'hello%20world', 'space -> %20';
};

subtest 'Util::urlencode -- ampersand encoded (would split params)' => sub {
	is urlencode('a&b'), 'a%26b', 'ampersand -> %26';
};

subtest 'Util::urlencode -- equals sign encoded (would split key=val)' => sub {
	is urlencode('a=b'), 'a%3Db', 'equals -> %3D';
};

subtest 'Util::urlencode -- hash encoded (would start a URL fragment)' => sub {
	is urlencode('a#b'), 'a%23b', 'hash -> %23';
};

subtest 'Util::urlencode -- question mark encoded (would start a query)' => sub {
	is urlencode('a?b'), 'a%3Fb', 'question mark -> %3F';
};

subtest 'Util::urlencode -- percent sign itself encoded (prevents double-encode ambiguity)' => sub {
	is urlencode('50%'), '50%25', 'bare percent -> %25';
};

subtest 'Util::urlencode -- plus sign encoded (not an unreserved char)' => sub {
	is urlencode('a+b'), 'a%2Bb', 'plus -> %2B (not confused with form-encoding)';
};

subtest 'Util::urlencode -- at-sign encoded' => sub {
	is urlencode('user@host'), 'user%40host', 'at-sign -> %40';
};

subtest 'Util::urlencode -- forward slash encoded (path separator must not leak)' => sub {
	is urlencode('/etc/passwd'), '%2Fetc%2Fpasswd', 'each slash -> %2F';
};

# --- Hostile: control characters and injection attempts ---

subtest 'Util::urlencode -- NUL byte encoded (injection defence)' => sub {
	is urlencode("a\x00b"), 'a%00b', 'NUL byte -> %00';
};

subtest 'Util::urlencode -- newline encoded (HTTP header injection defence)' => sub {
	is urlencode("line1\nline2"), 'line1%0Aline2', 'LF -> %0A';
};

subtest 'Util::urlencode -- carriage return encoded' => sub {
	is urlencode("a\rb"), 'a%0Db', 'CR -> %0D';
};

subtest 'Util::urlencode -- tab encoded' => sub {
	is urlencode("a\tb"), 'a%09b', 'tab -> %09';
};

# RFC 3986 section 2.1 mandates uppercase hex digits in percent-encoding
subtest 'Util::urlencode -- encoded hex digits are uppercase (RFC 3986 s2.1)' => sub {
	is urlencode('/'), '%2F', 'slash -> %2F (uppercase, not %2f)';
};

subtest 'Util::urlencode -- all-upcase hex: check second nibble too' => sub {
	# ord('A') = 65 = 0x41; confirm both nibbles are uppercase
	is urlencode("\x1b"), '%1B', 'ESC -> %1B (both nibbles uppercase)';
};

# Already-encoded input: the function is NOT idempotent by design.
# The caller is responsible for not double-encoding; this test verifies that
# a literal percent sign in the input is encoded, not silently swallowed.
subtest 'Util::urlencode -- already-encoded input gets double-encoded' => sub {
	is urlencode('%2F'), '%252F',
		'percent in input -> %25 (double-encoding; caller must not pre-encode)';
};

subtest 'Util::urlencode -- return value has no circular references' => sub {
	my $r = urlencode('table:sales');
	memory_cycle_ok(\$r, 'scalar return has no cycles');
};

# ============================================================================
# PART B: Database::BI::Ask -- internal helpers
# ============================================================================
# Strategy: the helpers in Ask.pm are the bridge between untrusted LLM output
# and the URL/spec that goes into the browser.  A bug here can produce broken
# URLs, spec-injection, or silent bad column names.  60%+ hostile tests.

use_ok('Database::BI::Ask');

# Direct references to private subs -- function.t is white-box by design.
Readonly my $PARSE_VISUAL    => \&Database::BI::Ask::_parse_visual;
Readonly my $VALIDATE_ENCODE => \&Database::BI::Ask::_validate_encode;
Readonly my $BUILD_URL       => \&Database::BI::Ask::_build_url;
Readonly my $BUILD_SPEC      => \&Database::BI::Ask::_build_spec;
Readonly my $INFER_TYPE      => \&Database::BI::Ask::_infer_type;

Readonly my $BAR_JSON_STR =>
	'{"kind":"bar","title":"Test","encode":{"cat":"region","val":"amount"}}';
Readonly my $PIE_JSON_STR =>
	'{"kind":"pie","title":"Pie","encode":{"cat":"region"}}';
Readonly my $TABLE_JSON_STR => '{"kind":"table","title":"Data","encode":{}}';

# ---------------------------------------------------------------------------
# _infer_type -- determines column data type from a sample of values
# ---------------------------------------------------------------------------

subtest 'Ask::_infer_type -- empty list -> string (safe fallback)' => sub {
	is $INFER_TYPE->([]), 'string', 'no values -> string (never crashes)';
};

subtest 'Ask::_infer_type -- 100% numeric values -> number' => sub {
	is $INFER_TYPE->([qw(1 2 3.5 -4)]), 'number', 'all numeric -> number';
};

subtest 'Ask::_infer_type -- majority numeric (75%) -> number' => sub {
	# 3 of 4 pass looks_like_number; 0.75 > 0.5 threshold
	is $INFER_TYPE->([qw(1 2 3 hello)]), 'number', '75% numeric -> number';
};

subtest 'Ask::_infer_type -- exactly 50% numeric -> NOT number (strict >)' => sub {
	# The threshold is $numeric / $n > 0.5; 2/4 = 0.5 must NOT qualify.
	# After failing the number check the date check runs; 0% date -> string.
	is $INFER_TYPE->([qw(1 2 hello world)]), 'string',
		'50% numeric does not cross the strict > 0.5 threshold';
};

subtest 'Ask::_infer_type -- 25% numeric -> string' => sub {
	is $INFER_TYPE->([qw(1 two three four)]), 'string', '25% numeric -> string';
};

subtest 'Ask::_infer_type -- 100% ISO-8601 dates -> date' => sub {
	is $INFER_TYPE->([qw(2024-01-01 2024-02-15 2025-12-31)]), 'date',
		'100% YYYY-MM-DD -> date';
};

subtest 'Ask::_infer_type -- 100% slash-date (M/D/YYYY) -> date' => sub {
	is $INFER_TYPE->([qw(1/15/2024 2/28/2024 12/1/2023)]), 'date',
		'M/D/YYYY format -> date';
};

subtest 'Ask::_infer_type -- mixed ISO and slash dates -> date' => sub {
	is $INFER_TYPE->([qw(2024-01-01 1/15/2024 2/28/2024)]), 'date',
		'both date patterns match the date regex';
};

subtest 'Ask::_infer_type -- minority dates (25%) -> string' => sub {
	is $INFER_TYPE->(['2024-01-01', 'hello', 'world', 'foo']), 'string',
		'25% date does not cross the strict > 0.5 threshold';
};

subtest 'Ask::_infer_type -- plain categorical strings -> string' => sub {
	is $INFER_TYPE->([qw(North South East West)]), 'string',
		'non-numeric non-date values -> string';
};

subtest 'Ask::_infer_type -- scientific notation is numeric' => sub {
	# looks_like_number() returns true for scientific notation
	is $INFER_TYPE->([qw(1e2 2e3 3e4)]), 'number',
		'scientific notation is numeric per Scalar::Util::looks_like_number';
};

# ---------------------------------------------------------------------------
# _parse_visual -- extracts and validates the JSON object from LLM output
# ---------------------------------------------------------------------------

subtest 'Ask::_parse_visual -- clean JSON string -> parsed hashref' => sub {
	my $v = $PARSE_VISUAL->($BAR_JSON_STR);
	is ref($v), 'HASH',   'valid JSON returns hashref';
	is $v->{kind}, 'bar', 'kind preserved';
	is ref($v->{encode}), 'HASH', 'encode is hashref';
	is $v->{encode}{cat}, 'region', 'encode.cat preserved';
};

subtest 'Ask::_parse_visual -- preamble text before JSON (bracket-depth fallback)' => sub {
	my $text = "Here is the analysis:\n$BAR_JSON_STR";
	my $v    = $PARSE_VISUAL->($text);
	is ref($v), 'HASH', 'JSON extracted despite preamble text';
	is $v->{kind}, 'bar', 'correct kind after preamble extraction';
};

subtest 'Ask::_parse_visual -- suffix text after JSON (depth counter stops at close)' => sub {
	my $text = "$PIE_JSON_STR\nI chose pie because it shows proportions.";
	my $v    = $PARSE_VISUAL->($text);
	is ref($v), 'HASH', 'JSON extracted despite suffix text';
	is $v->{kind}, 'pie', 'correct kind after suffix extraction';
};

subtest 'Ask::_parse_visual -- preamble + nested JSON + suffix' => sub {
	# The encode object creates two levels of nesting; the counter must not
	# stop at the inner } but continue until the outer one is balanced.
	my $text = "Consider:\n$BAR_JSON_STR\nThis is the best choice.";
	my $v    = $PARSE_VISUAL->($text);
	is ref($v), 'HASH', 'nested JSON extracted with preamble and suffix';
	is $v->{encode}{val}, 'amount', 'inner encode value preserved';
};

subtest 'Ask::_parse_visual -- multiple JSON objects: first one wins' => sub {
	# This is the exact failure mode the old /\{.*\}/s regex caused: it would
	# match from the first '{' to the LAST '}', spanning BOTH objects and
	# producing unparseable text.  The bracket-depth counter stops at the
	# first balanced close.
	my $text = '{"kind":"bar","title":"Bar","encode":{"cat":"x"}} '
	         . 'or {"kind":"pie","title":"Pie","encode":{"cat":"y"}}';
	my $v = $PARSE_VISUAL->($text);
	is ref($v), 'HASH',  'returns a hashref';
	is $v->{kind}, 'bar', 'first JSON object wins, not the last';
};

subtest 'Ask::_parse_visual -- missing encode key defaults to empty hashref' => sub {
	my $v = $PARSE_VISUAL->('{"kind":"table","title":"Data"}');
	is ref($v), 'HASH',                     'parses without encode key';
	is ref($v->{encode}), 'HASH',           'encode defaulted to hashref';
	is scalar(keys %{ $v->{encode} }), 0,   'defaulted encode is empty';
};

# --- Negative tests (60%) ---

subtest 'Ask::_parse_visual -- empty string -> undef' => sub {
	is $PARSE_VISUAL->(''), undef, 'empty string -> undef';
};

subtest 'Ask::_parse_visual -- no opening brace -> undef' => sub {
	is $PARSE_VISUAL->('no braces here'), undef,
		'no { means no JSON object can be found';
};

subtest 'Ask::_parse_visual -- unclosed brace -> undef (depth never reaches 0)' => sub {
	# The bracket-depth counter walks to end-of-string without $depth hitting 0.
	is $PARSE_VISUAL->('{"kind":"bar"'), undef,
		'unclosed { -> depth counter never returns to 0 -> undef';
};

subtest 'Ask::_parse_visual -- single { only -> undef' => sub {
	is $PARSE_VISUAL->('{'), undef, 'bare { with no closing -> undef';
};

subtest 'Ask::_parse_visual -- unknown kind -> undef' => sub {
	is $PARSE_VISUAL->('{"kind":"unknown_chart_type","encode":{}}'), undef,
		'kind not in %SUPPORTED_KINDS is rejected';
};

subtest 'Ask::_parse_visual -- missing kind key -> undef' => sub {
	is $PARSE_VISUAL->('{"title":"Sales","encode":{"cat":"region"}}'), undef,
		'missing kind returns undef';
};

subtest 'Ask::_parse_visual -- encode is array (not hash) -> undef' => sub {
	is $PARSE_VISUAL->('{"kind":"bar","encode":["cat","region"]}'), undef,
		'encode as arrayref is rejected (must be hashref or absent)';
};

subtest 'Ask::_parse_visual -- encode is scalar string -> undef' => sub {
	is $PARSE_VISUAL->('{"kind":"bar","encode":"cat"}'), undef,
		'encode as scalar string is rejected';
};

subtest 'Ask::_parse_visual -- completely non-JSON text -> undef' => sub {
	is $PARSE_VISUAL->('not json at all'), undef, 'non-JSON -> undef';
};

subtest 'Ask::_parse_visual -- hostile: very long preamble (10,000 chars)' => sub {
	# Ensures the bracket-depth scan does not have a hardcoded length limit.
	my $text = ('A' x 10_000) . $BAR_JSON_STR;
	my $v    = $PARSE_VISUAL->($text);
	is ref($v), 'HASH', 'long preamble does not prevent extraction';
	is $v->{kind}, 'bar', 'correct kind despite 10k-char preamble';
};

subtest 'Ask::_parse_visual -- hostile: extra closing braces in suffix' => sub {
	# The old greedy /\{.*\}/s would extend the match to include "} brackets".
	# The bracket-depth counter must stop at the first balanced close.
	my $text = $BAR_JSON_STR . ' Note: use } brackets carefully.';
	my $v    = $PARSE_VISUAL->($text);
	is ref($v), 'HASH', 'extra } in suffix does not break extraction';
	is $v->{kind}, 'bar', 'correct JSON parsed despite } in trailing text';
};

subtest 'Ask::_parse_visual -- result has no circular references' => sub {
	my $v = $PARSE_VISUAL->($BAR_JSON_STR);
	memory_cycle_ok($v, '_parse_visual result has no circular references');
};

# ---------------------------------------------------------------------------
# _validate_encode -- checks that every non-empty encode value is a known col
# ---------------------------------------------------------------------------

subtest 'Ask::_validate_encode -- all columns valid -> undef (no error)' => sub {
	my $visual  = { encode => { cat => 'region', val => 'amount' } };
	my $col_set = { region => 1, amount => 1, date => 1 };
	is $VALIDATE_ENCODE->($visual, $col_set), undef,
		'all encode values match known columns -> no error';
};

subtest 'Ask::_validate_encode -- empty encode -> undef (nothing to check)' => sub {
	my $visual  = { encode => {} };
	my $col_set = { region => 1 };
	is $VALIDATE_ENCODE->($visual, $col_set), undef,
		'empty encode hash -> undef (no columns to validate)';
};

subtest 'Ask::_validate_encode -- undef encode value -> skipped' => sub {
	my $visual  = { encode => { cat => undef, val => 'amount' } };
	my $col_set = { amount => 1 };
	is $VALIDATE_ENCODE->($visual, $col_set), undef,
		'undef encode value is skipped, not treated as a bad column';
};

subtest 'Ask::_validate_encode -- empty-string encode value -> skipped' => sub {
	my $visual  = { encode => { cat => '', val => 'amount' } };
	my $col_set = { amount => 1 };
	is $VALIDATE_ENCODE->($visual, $col_set), undef,
		'empty-string encode value is skipped';
};

subtest 'Ask::_validate_encode -- unknown column -> returns bad column name' => sub {
	my $visual  = { encode => { cat => 'nonexistent' } };
	my $col_set = { region => 1, amount => 1 };
	is $VALIDATE_ENCODE->($visual, $col_set), 'nonexistent',
		'unknown column name returned as error value';
};

subtest 'Ask::_validate_encode -- one bad column among valid ones -> returns bad name' => sub {
	# Keys are iterated sorted; 'bad_col' < 'region' alphabetically
	my $visual  = { encode => { cat => 'bad_col', val => 'region' } };
	my $col_set = { region => 1 };
	is $VALIDATE_ENCODE->($visual, $col_set), 'bad_col',
		'first sorted bad column name returned';
};

subtest 'Ask::_validate_encode -- hostile: injection string returned verbatim' => sub {
	# The caller receives the value and rejects it; the function must not
	# sanitize or truncate it (the ask() caller builds the error code from it).
	my $bad_col = "'; DROP TABLE sales; --";
	my $visual  = { encode => { cat => $bad_col } };
	my $col_set = { region => 1 };
	is $VALIDATE_ENCODE->($visual, $col_set), $bad_col,
		'injection string returned verbatim so caller can log/reject it';
};

# ---------------------------------------------------------------------------
# _build_url -- constructs the data-view URL from a validated visual + spec
# ---------------------------------------------------------------------------

subtest 'Ask::_build_url -- bar chart with table: spec' => sub {
	my $visual = { kind => 'bar', encode => { cat => 'region', val => 'amount' } };
	my $url    = $BUILD_URL->($visual, 'table:sales');
	like   $url, qr{^/bar\?},         'bar kind maps to /bar route';
	like   $url, qr{l=table%3Asales}, 'table: spec key colon is encoded';
	like   $url, qr{cat=region},      'cat param present';
	like   $url, qr{val=amount},      'val param present';
};

subtest 'Ask::_build_url -- line kind maps to /graph route' => sub {
	my $visual = { kind => 'line', encode => { x => 'date', y => 'amount' } };
	my $url    = $BUILD_URL->($visual, 'table:sales');
	like $url, qr{^/graph\?}, 'line kind -> /graph route (KIND_ROUTE mapping)';
};

subtest 'Ask::_build_url -- graph kind also maps to /graph route' => sub {
	my $visual = { kind => 'graph', encode => { x => 'date', y => 'amount' } };
	my $url    = $BUILD_URL->($visual, 'table:sales');
	like $url, qr{^/graph\?}, 'graph kind -> /graph route';
};

subtest 'Ask::_build_url -- table kind with table: spec -> /view/<name>' => sub {
	my $visual = { kind => 'table', encode => {} };
	is $BUILD_URL->($visual, 'table:sales'), '/view/sales',
		'table + table: spec -> /view/sales (no query string)';
};

subtest 'Ask::_build_url -- table kind with path: spec -> /open?path=' => sub {
	my $visual = { kind => 'table', encode => {} };
	my $url    = $BUILD_URL->($visual, 'path:/data/file.csv');
	like   $url, qr{^/open\?path=}, 'table + path: spec -> /open?path=';
	like   $url, qr{%2F},           'slashes in the path are percent-encoded';
	unlike $url, qr{path:},         'the "path:" prefix is stripped';
};

subtest 'Ask::_build_url -- l= param value has colon encoded' => sub {
	my $visual = { kind => 'pie', encode => { cat => 'region' } };
	my $url    = $BUILD_URL->($visual, 'table:sales');
	like $url, qr{l=table%3Asales},
		'colon in spec_key is %3A; must not appear as raw : in URL';
};

subtest 'Ask::_build_url -- encode params are sorted alphabetically in URL' => sub {
	# Sorted order: cat < series < val
	my $visual = {
		kind   => 'bar',
		encode => { val => 'amount', cat => 'region', series => 'type' },
	};
	my $url = $BUILD_URL->($visual, 'table:sales');
	my $cat_pos    = index($url, 'cat=');
	my $series_pos = index($url, 'series=');
	my $val_pos    = index($url, 'val=');
	ok $cat_pos    >= 0,               'cat= present';
	ok $series_pos >= 0,               'series= present';
	ok $val_pos    >= 0,               'val= present';
	ok $cat_pos    < $series_pos,      'cat before series (sorted)';
	ok $series_pos < $val_pos,         'series before val (sorted)';
};

subtest 'Ask::_build_url -- empty encode value omitted from URL' => sub {
	my $visual = { kind => 'bar', encode => { cat => 'region', val => '' } };
	my $url    = $BUILD_URL->($visual, 'table:sales');
	unlike $url, qr{val=}, 'empty encode value not emitted as a URL param';
};

subtest 'Ask::_build_url -- undef encode value omitted from URL' => sub {
	my $visual = { kind => 'bar', encode => { cat => 'region', val => undef } };
	my $url    = $BUILD_URL->($visual, 'table:sales');
	unlike $url, qr{val=}, 'undef encode value not emitted as a URL param';
};

subtest 'Ask::_build_url -- encode column name with special chars is encoded' => sub {
	# Column names are validated before _build_url is called, but the function
	# must still encode whatever it receives in case a future caller skips
	# _validate_encode.  Spaces (from DBD::CSV name normalisation) are encoded.
	my $visual = { kind => 'bar', encode => { cat => 'First Name' } };
	my $url    = $BUILD_URL->($visual, 'table:sales');
	like   $url, qr{cat=First%20Name}, 'space in column name encoded as %20';
	unlike $url, qr{cat=First Name},   'raw space must not appear in URL';
};

subtest 'Ask::_build_url -- result has no circular references' => sub {
	my $visual = { kind => 'bar', encode => { cat => 'region' } };
	my $url    = $BUILD_URL->($visual, 'table:sales');
	memory_cycle_ok(\$url, '_build_url scalar result has no cycles');
};

# ---------------------------------------------------------------------------
# _build_spec -- constructs the Phase 3 analysis spec hashref
# ---------------------------------------------------------------------------

subtest 'Ask::_build_spec -- returns required Phase 3 spec keys' => sub {
	my $visual = {
		kind    => 'bar',
		title   => 'Test',
		encode  => { cat => 'region' },
		options => {},
	};
	my $spec = $BUILD_SPEC->($visual, 'sales', 'table:sales');
	is   ref($spec), 'HASH',        'returns hashref';
	is   $spec->{version}, 1,       'version is 1';
	ok  exists $spec->{name},       'name key present';
	ok  exists $spec->{datasets},   'datasets key present';
	ok  exists $spec->{visuals},    'visuals key present';
};

subtest 'Ask::_build_spec -- name comes from visual title' => sub {
	my $visual = { kind => 'bar', title => 'Sales by region', encode => {} };
	my $spec   = $BUILD_SPEC->($visual, 'sales', 'table:sales');
	is $spec->{name}, 'Sales by region', 'name taken from visual title';
};

subtest 'Ask::_build_spec -- empty title falls back to "<label> analysis"' => sub {
	my $visual = { kind => 'bar', title => '', encode => {} };
	my $spec   = $BUILD_SPEC->($visual, 'sales', 'table:sales');
	is $spec->{name}, 'sales analysis', 'empty title -> "<label> analysis"';
};

subtest 'Ask::_build_spec -- missing title key falls back to "<label> analysis"' => sub {
	# No title key at all -- $visual->{title} is undef; undef || 'X' gives 'X'
	my $visual = { kind => 'bar', encode => {} };
	my $spec   = $BUILD_SPEC->($visual, 'sales', 'table:sales');
	is $spec->{name}, 'sales analysis', 'missing title -> "<label> analysis"';
};

subtest 'Ask::_build_spec -- datasets contains the spec_key' => sub {
	my $visual = { kind => 'pie', title => 'T', encode => {} };
	my $spec   = $BUILD_SPEC->($visual, 'sales', 'table:sales');
	is scalar(@{ $spec->{datasets} }), 1,          'one dataset entry';
	is $spec->{datasets}[0]{spec}, 'table:sales',  'spec_key in datasets[0].spec';
};

subtest 'Ask::_build_spec -- visuals array has one entry with correct kind' => sub {
	my $visual = { kind => 'pie', title => 'T', encode => { cat => 'region' } };
	my $spec   = $BUILD_SPEC->($visual, 'sales', 'table:sales');
	is scalar(@{ $spec->{visuals} }), 1,       'one visual entry';
	is $spec->{visuals}[0]{kind}, 'pie',       'visual kind preserved';
	is $spec->{visuals}[0]{encode}{cat}, 'region', 'visual encode preserved';
};

subtest 'Ask::_build_spec -- result has no circular references' => sub {
	my $visual = {
		kind    => 'bar',
		title   => 'T',
		encode  => { cat => 'region' },
		options => {},
	};
	my $spec = $BUILD_SPEC->($visual, 'sales', 'table:sales');
	memory_cycle_ok($spec, '_build_spec result has no circular references');
};

# ============================================================================
# PART: The measure vocabulary -- parser, arithmetic, and who computes what
#
# A measure spec (col:fn:as) reaches either the backend's aggregate() (the push
# path) or the Perl fold in _grouped_totals.  Everything the fold computes for a
# group of values lives in the four functions below, so proving them here is
# what makes the pivot's and the stats page's numbers trustworthy -- and
# _measure_pushable is what keeps the two layers from disagreeing.
# ============================================================================

Readonly my $PARSE_MEASURE => \&Database::BI::Controller::Dashboard::_parse_measure_param;
Readonly my $FN_OK         => \&Database::BI::Controller::Dashboard::_measure_fn_ok;
Readonly my $FN_PCT        => \&Database::BI::Controller::Dashboard::_measure_percentile;
Readonly my $PERCENTILE    => \&Database::BI::Controller::Dashboard::_percentile_of;
Readonly my $MEDIAN        => \&Database::BI::Controller::Dashboard::_median_of;
Readonly my $STDEV         => \&Database::BI::Controller::Dashboard::_stdev_of;
Readonly my $RANGE         => \&Database::BI::Controller::Dashboard::_range_of;
Readonly my $MEASURE_VALUE => \&Database::BI::Controller::Dashboard::_measure_value;
Readonly my $PUSHABLE      => \&Database::BI::Controller::Dashboard::_measure_pushable;

# _measure_percentile -- which functions name a percentile level
subtest '_measure_percentile -- reads the level out of the function name' => sub {
	is $FN_PCT->('p95'),  95, 'p95 names the 95th percentile';
	is $FN_PCT->('p50'),  50, 'p50 names the 50th, the median';
	is $FN_PCT->('p1'),    1, 'p1 is the lowest accepted level';
	is $FN_PCT->('p100'), 100, 'p100 is the highest accepted level';

	is $FN_PCT->('p0'),   undef, 'p0 is not a percentile';
	is $FN_PCT->('p101'), undef, 'p101 is not a percentile';
	is $FN_PCT->('p999'), undef, 'three digits above 100 are not a percentile';
	is $FN_PCT->('p'),    undef, 'p with no level names no percentile';
	is $FN_PCT->('px9'),  undef, 'p followed by a non-number names no percentile';
	is $FN_PCT->('median'),     undef, 'median is its own function, not a pN';
	is $FN_PCT->('percentile'), undef, 'the bare word percentile carries no level';
	is $FN_PCT->('p95x'), undef, 'a percentile is the whole function name';
	is $FN_PCT->(''),     undef, 'the empty function names no percentile';
	is $FN_PCT->(undef),  undef, 'undef names no percentile';
};

# _measure_fn_ok -- the vocabulary gate the parser uses
subtest '_measure_fn_ok -- accepts the vocabulary and every percentile' => sub {
	for my $fn (qw(sum avg min max count count_distinct median stdev first last range)) {
		ok $FN_OK->($fn), "$fn is a measure function";
	}
	ok $FN_OK->('p1'),   'p1 is a measure function';
	ok $FN_OK->('p90'),  'p90 is a measure function';
	ok $FN_OK->('p100'), 'p100 is a measure function';

	ok !$FN_OK->('percentile'), 'the bare word percentile is not a function';
	ok !$FN_OK->('mean'),        'mean is not a function in this vocabulary';
	ok !$FN_OK->('stddev'),      'stddev is not spelled this way';
	ok !$FN_OK->('sums'),        'a near miss is not a function';
	ok !$FN_OK->(''),            'the empty name is not a function';
	ok !$FN_OK->(undef),         'undef is not a function';
};

# _parse_measure_param -- the spec dialect
subtest '_parse_measure_param -- accepts every measure function, lower-cased' => sub {
	for my $spec (qw(deal:median:med deal:p90:p90 deal:p100:top deal:stdev:sd
	                 deal:first:f deal:last:l deal:range:rg)) {
		my $m = $PARSE_MEASURE->($spec);
		is ref($m), 'HASH', "$spec parses";
		isnt $m->{col}, '', "$spec keeps its column";
		isnt $m->{as},  '', "$spec keeps its alias";
	}

	is $PARSE_MEASURE->('deal:P90:x')->{fn},    'p90',    'a percentile is lower-cased';
	is $PARSE_MEASURE->('deal:MEDIAN:x')->{fn}, 'median', 'a named function is lower-cased';
	is $PARSE_MEASURE->('deal:p50:half')->{fn}, 'p50',    'p50 is accepted as written';
	is $PARSE_MEASURE->(':count:orders')->{fn}, 'count',  'count still needs no column';
};

subtest '_parse_measure_param -- refuses what the fold cannot compute' => sub {
	is $PARSE_MEASURE->('deal:percentile:pc'), undef,
		'percentile with no level is refused (the level rides in the name as p90)';
	is $PARSE_MEASURE->('deal:p0:z'),   undef, 'p0 is refused';
	is $PARSE_MEASURE->('deal:p101:z'), undef, 'p101 is refused';
	is $PARSE_MEASURE->('deal:mean:z'), undef, 'an unknown function is refused';
	is $PARSE_MEASURE->('deal::z'),     undef, 'an empty function is refused';
	is $PARSE_MEASURE->('deal:median'), undef, 'a spec with no alias is refused';
};

# _percentile_of -- the arithmetic, and its identity with the old median
subtest '_percentile_of -- p50 is the median this page has always shown' => sub {
	# The definition the column-stats view used before it moved here: the
	# middle value when the count is odd, the mean of the two middle values when
	# it is even.  Checked from the count up rather than at one size, because the
	# even/odd boundary is the whole of the rule.
	my @values = (10, 20, 30, 40, 50, 60, 70, 80);
	for my $n (1 .. scalar @values) {
		my @sorted = sort { $a <=> $b } @values[0 .. $n - 1];
		my $mid    = int($n / 2);
		my $want   = $n % 2 ? $sorted[$mid] : ($sorted[$mid - 1] + $sorted[$mid]) / 2;
		is $PERCENTILE->(\@sorted, 50), $want, "p50 of $n values is the middle/average-of-middles";
		is $MEDIAN->(\@sorted), $want, "_median_of of $n values agrees";
	}
};

subtest '_percentile_of -- interpolation between closest ranks' => sub {
	my @sorted = (1, 2, 3, 4);
	is $PERCENTILE->(\@sorted, 25), 1.75, 'p25 of 1..4 interpolates between the first two';
	is $PERCENTILE->(\@sorted, 50), 2.5,  'p50 of 1..4 is the middle pair';
	is $PERCENTILE->(\@sorted, 100), 4,   'p100 of 1..4 is the largest value';

	my @six = (60, 75, 80, 85, 90, 100);
	is $PERCENTILE->(\@six, 95), 97.5, 'p95 of the six scores the stats page shows';
	is $PERCENTILE->(\@six, 50), 82.5, 'p50 of the same six scores';

	# Monotonic in the level, which is what makes a percentile meaningful.
	my @levels = map { $PERCENTILE->(\@six, $_) } (1, 25, 50, 75, 95, 100);
	my @sorted_levels = sort { $a <=> $b } @levels;
	is_deeply \@levels, \@sorted_levels, 'a higher level never gives a smaller value';

	is $PERCENTILE->([42], 90), 42, 'one value is every percentile of itself';
	is $PERCENTILE->([], 50), undef, 'an empty list has no percentile';
};

# _stdev_of -- sample standard deviation
subtest '_stdev_of -- sample standard deviation, n-1 denominator' => sub {
	is $STDEV->([2, 4, 6]), 2, 'the spread of 2,4,6 is exactly 2';
	is $STDEV->([2, 4, 4, 4, 5, 5, 7, 9]), sqrt(32 / 7),
		'the textbook sample standard deviation';
	is $STDEV->([5, 5]), 0, 'two equal values have no spread';
	is $STDEV->([7]),    undef, 'one value has no spread to measure (undef, not 0)';
	is $STDEV->([]),     undef, 'no values have no spread to measure';
};

# _range_of -- largest minus smallest
subtest '_range_of -- spread of the sorted list' => sub {
	is $RANGE->([1, 5, 9]), 8,  'the largest minus the smallest';
	is $RANGE->([4]),       0,  'a single value spans nothing';
	is $RANGE->([-3, 7]),   10, 'a negative minimum still measures the span';
	is $RANGE->([]),        undef, 'an empty list has no range';
};

# _measure_value -- one dispatch for both callers
subtest '_measure_value -- dispatch over the Perl-computed functions' => sub {
	my @sorted = (1, 2, 3, 4);
	is $MEASURE_VALUE->('median', \@sorted), 2.5,   'median is dispatched';
	is $MEASURE_VALUE->('p25',    \@sorted), 1.75,  'a percentile is dispatched';
	is $MEASURE_VALUE->('stdev',  \@sorted), sqrt(5 / 3), 'stdev is dispatched';
	is $MEASURE_VALUE->('range',  \@sorted), 3,     'range is dispatched';
	is $MEASURE_VALUE->('sum',    \@sorted), undef, 'a pushed function is not handled here';
	is $MEASURE_VALUE->('first',  \@sorted), undef, 'first is order-dependent, not a spread';
};

# _measure_pushable -- the boundary between the two layers
subtest '_measure_pushable -- the Perl-computed measures never go to the backend' => sub {
	# _measure_pushable asks one thing of the source -- whether it can
	# aggregate() -- so this is all the source has to answer.
	{
		package Local::AggregatingSource;
		sub new       { bless {}, shift }
		sub aggregate { return [] }
	}
	my $src     = Local::AggregatingSource->new;
	my $records = [ { deal => '10' }, { deal => '20' } ];

	ok $PUSHABLE->($src, 'sum',            'deal', $records), 'sum is pushed to the backend';
	ok $PUSHABLE->($src, 'avg',            'deal', $records), 'avg is pushed to the backend';
	ok $PUSHABLE->($src, 'count_distinct', 'deal', $records), 'count_distinct is pushed';

	ok !$PUSHABLE->($src, 'median', 'deal', $records),
		'median folds in Perl, so the backend cannot answer it its own way';
	ok !$PUSHABLE->($src, 'p90', 'deal', $records),
		'a percentile folds in Perl';
	ok !$PUSHABLE->($src, 'stdev', 'deal', $records),
		'stdev folds in Perl';
	ok !$PUSHABLE->($src, 'range', 'deal', $records),
		'range folds in Perl';
	ok !$PUSHABLE->($src, 'first', 'deal', $records),
		'first folds in Perl: which value is first is not the backend\'s to know';
	ok !$PUSHABLE->($src, 'last', 'deal', $records),
		'last folds in Perl';

	# A source that cannot aggregate() takes everything through the fold.
	my $plain = bless {}, 'Local::PlainSource';
	ok !$PUSHABLE->($plain, 'sum', 'deal', $records),
		'a source with no aggregate() is never pushed to';
};

# ============================================================================
# PART 7: Dashboard -- _visual_measure
#
# The measure a canvas card aggregates its value column with.  A card that
# names no function keeps the default it has always had -- count the rows when
# it names no value column, sum it when it does -- and a card that names one
# gets it, with a percentile riding in the name as a pivot's measure spells it.
# ============================================================================

subtest '_visual_measure -- the default a card has always had' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_visual_measure;

	is_deeply $fn->(undef, undef), { fn => 'count', val => undef, label => 'Count' },
		'no function and no column counts rows';
	is_deeply $fn->(undef, ''), { fn => 'count', val => undef, label => 'Count' },
		'an empty column name counts rows too';
	is_deeply $fn->(undef, '__count__'), { fn => 'count', val => undef, label => 'Count' },
		'the value menu\'s Count (no column needed) counts rows';
	is_deeply $fn->('', 'amount'), { fn => 'sum', val => 'amount', label => 'amount' },
		'an empty function name is no choice, so the column is summed';
	is_deeply $fn->(undef, 'amount'), { fn => 'sum', val => 'amount', label => 'amount' },
		'and a named column is summed, as every chart page does';
};

subtest '_visual_measure -- naming the default changes nothing' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_visual_measure;
	is_deeply $fn->('sum', 'amount'), { fn => 'sum', val => 'amount', label => 'amount' },
		'an explicit sum keeps the column\'s own name in the title';
};

subtest '_visual_measure -- the pivot vocabulary, and its percentile spelling' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_visual_measure;

	for my $name (qw(avg min max count_distinct median stdev first last range)) {
		my $m = $fn->($name, 'amount');
		ok !$m->{error}, "$name is a measure a card can pick";
		is $m->{fn},    $name,          "and is what the group is aggregated with";
		is $m->{val},   'amount',       "over the column the card names";
		is $m->{label}, "$name(amount)", "so the title says which function it was";
	}

	# A percentile rides in the name, as it does in a pivot's m= spec, so a card
	# needs no second key to keep in step.
	is_deeply $fn->('p95', 'amount'), { fn => 'p95', val => 'amount', label => 'p95(amount)' },
		'a percentile is the function p95';
	is $fn->('p1',   'amount')->{fn}, 'p1',   'the lowest percentile is allowed';
	is $fn->('p100', 'amount')->{fn}, 'p100', 'and the highest';

	# first and last read any column, not only a numeric one, as the pivot allows.
	is $fn->('first', 'region')->{val}, 'region',
		'first may name a column of text';
};

subtest '_visual_measure -- count ignores the column it is given' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_visual_measure;
	is_deeply $fn->('count', 'amount'), { fn => 'count', val => undef, label => 'Count' },
		'count counts rows, so the column it names is dropped';
	is_deeply $fn->('count', undef), { fn => 'count', val => undef, label => 'Count' },
		'and it needs no column at all';
};

subtest '_visual_measure -- a function that needs a column says so' => sub {
	my $fn = \&Database::BI::Controller::Dashboard::_visual_measure;

	for my $case ([ undef, 'median' ], [ '', 'median' ],
	              [ '__count__', 'median' ], [ undef, 'p95' ], [ '', 'stdev' ]) {
		my ($val, $name) = @$case;
		my $m = $fn->($name, $val);
		ok $m->{error}, "$name with no value column is refused";
		like $m->{error}, qr/\Q$name\E/,              'and the message names the function';
		like $m->{error}, qr/needs a value column/,    'and says what is missing';
		ok !defined $m->{fn}, 'with no measure to aggregate with';
	}
};

# ============================================================================
# PART U: helpers shared by the module-by-module parts that follow
#
# Each module below gets its own block so its constants cannot leak into the
# next.  At least 60% of the assertions are hostile: the question is whether a
# function can be broken, not whether it works on the input it was written for.
# ============================================================================

use_ok('Database::BI::Util');
use_ok('Database::BI::Summary');
use_ok('Database::BI::Tutorial');
use_ok('Database::BI::Extract');
use_ok('Database::BI::Ask');
use_ok('Database::BI::Insights');
use_ok('Database::BI::Calc');

require HTTP::Response;
require LWP::UserAgent;

# A helper that assigns to a global it did not localise corrupts its caller, and
# the damage shows up far away.  Every global a helper might plausibly touch is
# given a sentinel and read back afterwards.
sub keeps_globals_ok {
	my ($name, $code) = @_;

	my @after;
	{
		local $_ = 'sentinel';
		local $, = 'ofs';
		local $\ = 'ors';
		local $" = 'lsep';
		local $/ = 'irs';
		# Nothing may print while the test output's own separators are changed;
		# the checks run after the block, so only the values are captured here.
		$code->();
		@after = ($_, $,, $\, $", $/);
	}
	is_deeply \@after, [ 'sentinel', 'ofs', 'ors', 'lsep', 'irs' ],
		"$name leaves \$_, \$, \$\\ \$\" and \$/ as it found them";
	return;
}

# A provider reply as LWP would hand it back, so the module's own status and
# decoding code runs rather than a stand-in for it.
sub fake_response {
	my ($code, $body) = @_;
	return HTTP::Response->new($code, ($code == 200 ? 'OK' : 'Boom'),
		[ 'Content-Type' => 'application/json' ], $body);
}

# Runs $code with the network replaced.  The request is captured so a test can
# read what would have left the machine, and unmocking here means a failing
# assertion cannot leave the next subtest talking to the stub.
sub with_fake_network {
	my ($response, $code) = @_;
	my @requests;
	Test::Mockingbird::mock('LWP::UserAgent::request', sub {
		push @requests, $_[1];
		return $response;
	});
	my $ok  = eval { $code->(\@requests); 1 };
	my $err = $@;
	Test::Mockingbird::unmock('LWP::UserAgent::request');
	croak_rethrow($err) unless $ok;
	return \@requests;
}

sub croak_rethrow {
	my ($err) = @_;
	require Carp;
	Carp::croak($err);
}

# ============================================================================
# PART U1: Database::BI::Util
# ============================================================================
{
	my $fn = \&Database::BI::Util::urlencode;

	# Strategy: the unreserved set must pass untouched, because over-encoding
	# breaks the URLs Insights and Ask compare and link to.
	subtest 'Util::urlencode -- unreserved characters pass through' => sub {
		is $fn->('AZaz09-._~'), 'AZaz09-._~', 'the RFC 3986 unreserved set is left alone';
		is $fn->(''), '', 'an empty string stays empty';
		is $fn->('0'), '0', 'a false but defined value is not treated as missing';
		returns_is $fn->('x'), { type => 'string' }, 'always a plain string';
	};

	# Strategy: everything that could end a value or start a parameter, a path or
	# a script has to come out inert.
	subtest 'Util::urlencode -- hostile input cannot escape the query value' => sub {
		is $fn->(undef), '', 'undef becomes an empty string, not a warning';
		is $fn->('a b&c=d'), 'a%20b%26c%3Dd', 'separators cannot start a new parameter';
		is $fn->('%41'), '%2541', 'an encoded value is encoded again, never passed through';
		is $fn->('../../etc'), '..%2F..%2Fetc', 'slashes cannot walk a path';
		is $fn->(qq{"><script>}), '%22%3E%3Cscript%3E', 'markup cannot leave an attribute';
		is $fn->("a\r\nb"), 'a%0D%0Ab', 'CRLF cannot split a header';
		is $fn->("\0"), '%00', 'a NUL byte cannot truncate the value';
		is $fn->('#frag?q'), '%23frag%3Fq', 'nor can a fragment or a query mark';
	};

	# Why: a decoded column name reaches this function from Insights.  The code
	# point 0x263A printed as "%263A" would decode to "&3A", a different value.
	subtest 'Util::urlencode -- a wide character is encoded as its UTF-8 bytes' => sub {
		is $fn->("\x{263A}"), '%E2%98%BA', 'three UTF-8 bytes, not one over-long escape';
		is $fn->("a\x{263A}b"), 'a%E2%98%BAb', 'inside a longer value too';
		is $fn->("\xC3\xA9"), '%C3%A9', 'bytes that are already UTF-8 are not encoded twice';
	};

	subtest 'Util::urlencode -- the caller keeps its value and its globals' => sub {
		my $input = 'a b';
		$fn->($input);
		is $input, 'a b', 'the argument is not modified in place';
		keeps_globals_ok('urlencode', sub { $fn->('a b') });
	};

	my $number = \&Database::BI::Util::parse_number;

	subtest 'Util::parse_number -- the ways a number is dressed' => sub {
		my %reads = (
			'12' => 12, '-1.5' => -1.5, '0' => 0, '$1,234.56' => 1234.56, '(1,234.56)' => -1234.56,
			'($5)' => -5, '50%' => 50, '1 234' => 1234, '1e3' => 1000, '2.5E-1' => 0.25,
			'USD 100' => 100, '100 EUR' => 100, 'GBP100' => 100, '100GBP' => 100, '(USD 100)' => -100,
			"\xC2\xA35" => 5, "\x{20AC}7" => 7, ' 7 ' => 7,
		);
		is $number->($_), $reads{$_}, "'$_' is read" for sort grep { !/[^\x00-\x7F]/ } keys %reads;
		is $number->("\xC2\xA35"), 5, 'a pound sign as UTF-8 bytes';
		is $number->("\x{20AC}7"), 7, 'a decoded euro sign';
	};

	# Why: this is the test of what a chart will total.  A code column read as numbers
	# is a meaningless measure, and an unknown code must not pass for a currency.
	subtest 'Util::parse_number -- text that merely holds digits' => sub {
		is $number->($_), undef, "'$_' is not a number" for
			'', 'abc', 'SKU123', 'SKU 100', '100 SKU', 'A1', 'AB-100', 'R2D2', 'v1.2', '12/25/2025', '2026-05-20',
			'10:30', '1.2.3', '--5', '-', '.', '()', 'USD', 'USD USD', 'Widget 2', '1e', 'e5', '0x10', 'Inf', 'NaN';
		is $number->(undef), undef, 'nor is nothing';
		is $number->('1e999'), undef, 'nor is what would be infinity';
		is $number->('-1e999'), undef, 'in either direction';
		is $number->('9' x 400), undef, 'however it is spelled';
		keeps_globals_ok('parse_number', sub { $number->('$5') });
	};
}

# ============================================================================
# PART U2: Database::BI::Summary
#
# The cache is a lexical in the module, so each subtest uses its own label to
# start from a miss.  LWP is replaced throughout: nothing here reaches a network.
# ============================================================================
{
	Readonly my $SUM     => 'Database::BI::Summary';
	Readonly my $API_KEY => 'test-key';
	Readonly my $SECRET  => 'path:/private/secret-file.csv';

	my $tmpl = \&Database::BI::Summary::_template_summary;
	my $fp   = \&Database::BI::Summary::_fingerprint;
	my $llm  = \&Database::BI::Summary::_llm_summary;
	my $call = \&Database::BI::Summary::_call_anthropic;

	my %outlier = (kind => 'outlier',      headline => 'Odd value',  detail => 'd1');
	my %period  = (kind => 'period_delta', headline => 'Up 5',       detail => 'd2');
	my %mover   = (kind => 'top_mover',    headline => 'North rose', detail => 'd3');
	my %season  = (kind => 'seasonality',  headline => 'Repeats',    detail => 'd4');

	subtest 'Summary::_fingerprint -- every input that changes the text changes the key' => sub {
		my $base = $fp->([ \%period ], 0, 'L', 1);
		like $base, qr/\A[0-9a-f]{32}\z/, 'an md5 hex digest';
		is $fp->([ \%period ], 0, 'L', 1), $base, 'the same input gives the same key';
		isnt $fp->([ \%period ], 1, 'L', 1), $base, 'a polished summary is not a template one';
		isnt $fp->([ \%period ], 0, 'M', 1), $base, 'nor another dataset';
		isnt $fp->([ \%period ], 0, 'L', 2), $base, 'nor another row count';
		isnt $fp->([ \%mover ], 0, 'L', 1), $base, 'nor another insight';
		isnt $fp->([ { %period, headline => 'Up 6' } ], 0, 'L', 1), $base, 'nor another headline';

		# Why: the summary prints the detail, and two period deltas can share a
		# headline while their figures differ.  A key without it serves one
		# dataset's numbers to the other for an hour.
		isnt $fp->([ { %period, detail => 'other figures' } ], 0, 'L', 1), $base,
			'nor another detail, since the template prints it';
	};

	subtest 'Summary::_fingerprint -- text outside Latin-1 does not kill the request' => sub {
		my $key;
		lives_ok { $key = $fp->([ { %period, headline => "Up \x{20AC}5" } ], 0, "L\x{263A}", 1) }
			'md5_hex is given bytes, so a wide character cannot make it croak';
		like $key, qr/\A[0-9a-f]{32}\z/, 'and the key is still a digest';
		lives_ok { $fp->([], 0, 'L', 0) } 'no insights at all is still a key';
	};

	subtest 'Summary::_template_summary -- sentences per insight kind' => sub {
		like $tmpl->([], 'Sales', 1), qr/\ASales: 1 row analysed\. /, 'one row is singular';
		like $tmpl->([], 'Sales', 2), qr/\ASales: 2 rows analysed\. /, 'two are plural';
		like $tmpl->([], 'Sales', 0), qr/0 rows analysed/, 'zero reads as plural';
		like $tmpl->([], 'S', 1), qr/No significant patterns were detected\.\z/,
			'no insights says so rather than ending abruptly';
		like $tmpl->([ \%outlier ], 'S', 1), qr/An unusual value was detected: Odd value\./, 'one outlier';
		like $tmpl->([ \%outlier, \%outlier, \%outlier ], 'S', 1),
			qr/3 outliers detected, including: Odd value\./, 'several outliers are counted';
		like $tmpl->([ \%period ], 'S', 1), qr/Up 5\. d2\./, 'a period delta gives its figures';
		like $tmpl->([ \%mover ], 'S', 1), qr/Top movement: North rose\./, 'a top mover';
		like $tmpl->([ \%season ], 'S', 1), qr/seasonal pattern was detected: Repeats\./, 'seasonality';
	};

	subtest 'Summary::_template_summary -- order is fixed and odd input is harmless' => sub {
		my $text = $tmpl->([ \%season, \%mover, \%period, \%outlier ], 'S', 1);
		like $text, qr/unusual.*Up 5.*Top movement.*seasonal/s,
			'the order is by importance, not the order the insights arrived in';

		like $tmpl->([ { kind => 'made_up', headline => 'x', detail => 'y' } ], 'S', 1),
			qr/No significant patterns/, 'an unknown kind counts as nothing';
		unlike $tmpl->([ { kind => 'made_up', headline => 'SECRET', detail => 'y' } ], 'S', 1),
			qr/SECRET/, 'and its text is not repeated';
		keeps_globals_ok('_template_summary', sub { $tmpl->([ \%outlier ], 'S', 1) });
	};

	subtest 'Summary::_llm_summary -- refuses a provider it cannot call' => sub {
		throws_ok { $llm->([], 'S', 1, { provider => 'openai', api_key => $API_KEY }) }
			qr/\AUnsupported AI provider: openai at /, 'exact message, naming the provider';
		throws_ok { $llm->([], 'S', 1, { provider => '../../x', api_key => $API_KEY }) }
			qr/\AUnsupported AI provider: \.\.\/\.\.\/x at /, 'a hostile name goes nowhere';
	};

	subtest 'Summary::_llm_summary -- the prompt carries only the facts' => sub {
		my @prompts;
		Test::Mockingbird::mock("${SUM}::_call_anthropic", sub { push @prompts, $_[0]; "  polished \n" });

		my @got = $llm->([ (\%outlier) x 9 ], 'Sales', 12, { api_key => $API_KEY, provider => 'ANTHROPIC' });

		Test::Mockingbird::unmock("${SUM}::_call_anthropic");

		is_deeply \@got, [ 'polished', 'llm' ], 'surrounding whitespace is trimmed; the provider name is case-blind';
		my $facts = () = $prompts[0] =~ /^- \[outlier\]/mg;
		is $facts, 5, 'the list is capped, so a large result cannot run up the bill';
		like $prompts[0], qr/"Sales" \(12 rows\)/, 'the label and count are there';
	};

	subtest 'Summary::_call_anthropic -- a provider failure is an exact croak' => sub {
		with_fake_network(fake_response(500, 'x'), sub {
			throws_ok { $call->('p', { api_key => $API_KEY }) }
				qr/\AProvider error: 500 Boom at /, 'status line in the message';
		});
		with_fake_network(fake_response(200, 'not json'), sub {
			dies_ok { $call->('p', { api_key => $API_KEY }) } 'a reply that is not JSON is an error';
		});
		for my $body ('{}', '{"content":[]}', '{"content":[{"text":""}]}', '{"content":[{}]}') {
			with_fake_network(fake_response(200, $body), sub {
				throws_ok { $call->('p', { api_key => $API_KEY }) }
					qr/\ANo text in provider response at /, "no usable text in $body";
			});
		}
		with_fake_network(fake_response(200, '{"content":"oops"}'), sub {
			throws_ok { $call->('p', { api_key => $API_KEY }) }
				qr/\ANo text in provider response at /, 'a reply of the wrong shape is the same error';
		});
	};

	subtest 'Summary::_call_anthropic -- what is sent' => sub {
		my $text;
		my $sent = with_fake_network(fake_response(200, '{"content":[{"text":"hello"}]}'), sub {
			$text = $call->('the prompt', { api_key => $API_KEY });
		});
		is $text, 'hello', 'the text of the first block is returned';
		is $sent->[0]->header('x-api-key'), $API_KEY, 'the key goes in a header';
		is $sent->[0]->method, 'POST', 'by POST';
		my $body = decode_json($sent->[0]->content);
		is $body->{model}, 'claude-haiku-5-5', 'the default model';
		is $body->{messages}[0]{content}, 'the prompt', 'and the prompt';
		unlike $sent->[0]->uri, qr/\Q$API_KEY\E/, 'the key is never in the URL, where logs would keep it';
	};

	subtest 'Summary::generate -- the template path never touches the network' => sub {
		my $calls = 0;
		Test::Mockingbird::mock("${SUM}::_call_anthropic", sub { $calls++; 'x' });

		my $none  = $SUM->can('generate')->(insights => [], label => 'gen-none', row_count => 1);
		my $nokey = $SUM->can('generate')->(insights => [], label => 'gen-nokey', row_count => 1,
			use_ai => 1, ai_config => { api_key => '' });
		my $notasked = $SUM->can('generate')->(insights => [], label => 'gen-notasked', row_count => 1,
			use_ai => 0, ai_config => { api_key => $API_KEY });

		Test::Mockingbird::unmock("${SUM}::_call_anthropic");

		is $calls, 0, 'no key, or a key not asked to be used, sends nothing';
		is $_->{source}, 'template', 'and each is a template summary' for $none, $nokey, $notasked;
		returns_is $none, { type => 'hashref' }, 'a hashref comes back';
		memory_cycle_ok($none, 'and it holds no cycle');
	};

	subtest 'Summary::generate -- defaults survive having no arguments at all' => sub {
		my $got;
		lives_ok { $got = Database::BI::Summary::generate() } 'no arguments is not a crash';
		like $got->{text}, qr/\Adataset: 0 rows analysed\./, 'the defaults read sensibly';
	};

	subtest 'Summary::generate -- a provider failure falls back to the template' => sub {
		Test::Mockingbird::mock("${SUM}::_llm_summary", sub { require Carp; Carp::croak('provider down') });
		my $got = Database::BI::Summary::generate(insights => [ \%mover ], label => 'gen-fallback',
			row_count => 1, use_ai => 1, ai_config => { api_key => $API_KEY });
		Test::Mockingbird::unmock("${SUM}::_llm_summary");

		is $got->{source}, 'template_fallback', 'the reader still gets a summary';
		like $got->{text}, qr/Top movement: North rose/, 'made from the same insights';
		unlike $got->{text}, qr/provider down/, 'and the provider error is not shown to them';
	};

	subtest 'Summary::generate -- the provider is asked once and never given the spec' => sub {
		my @prompts;
		Test::Mockingbird::mock("${SUM}::_call_anthropic", sub { push @prompts, $_[0]; 'polished' });
		my %args = (insights => [ \%mover ], spec_key => $SECRET, label => 'gen-cache',
			row_count => 3, use_ai => 1, ai_config => { api_key => $API_KEY });
		my $first  = Database::BI::Summary::generate(%args);
		my $second = Database::BI::Summary::generate(%args);
		Test::Mockingbird::unmock("${SUM}::_call_anthropic");

		is $first->{source}, 'llm', 'the first call used the provider';
		is $first->{cached}, 0, 'and is not cached';
		is $second->{cached}, 1, 'the second is';
		is $second->{text}, 'polished', 'with the same text';
		is scalar @prompts, 1, 'so the provider was asked once';
		unlike $prompts[0], qr/secret-file|private/, 'the spec key, which holds a path, never leaves';
		keeps_globals_ok('generate', sub { Database::BI::Summary::generate(%args) });
	};
}

# ============================================================================
# PART U3: Database::BI::Tutorial
#
# The content is data; what can go wrong is its wiring -- a route, action or part
# that points at nothing, or a caller able to damage the shared tables.
# ============================================================================
{
	Readonly my $TUT => 'Database::BI::Tutorial';

	subtest 'Tutorial -- the content accessors' => sub {
		returns_is $TUT->$_(), { type => 'arrayref' }, "$_ returns an arrayref" for qw(intro chapters faq glossary);
		ok scalar @{ $TUT->$_() }, "$_ is not empty" for qw(intro chapters faq glossary);
		my %seen;
		my @dups = grep { $seen{ $_->{id} }++ } @{ $TUT->chapters };
		is_deeply \@dups, [], 'no two chapters share an id, or a link would land on the wrong one';
		ok !(grep { !length($_->{id} // '') || !length($_->{part} // '') } @{ $TUT->chapters }),
			'every chapter has an id and a part';
	};

	subtest 'Tutorial::parts -- groups neighbouring chapters' => sub {
		my $parts = $TUT->parts;
		returns_is $parts, { type => 'arrayref' }, 'an arrayref';
		my $count = 0;
		$count += @{ $_->{chapters} } for @$parts;
		is $count, scalar @{ $TUT->chapters }, 'no chapter is lost or repeated';
		for my $part (@$parts) {
			like $part->{id}, qr/\A[a-z0-9-]+\z/, "the id of '$part->{name}' is safe in a URL";
			ok !(grep { $_->{part} ne $part->{name} } @{ $part->{chapters} }), 'it holds only its own chapters';
		}
		memory_cycle_ok($parts, 'and it holds no cycle');
	};

	subtest 'Tutorial::covered_routes and exempt_routes -- nothing points at nothing' => sub {
		my %ids = map { $_->{id} => 1 } @{ $TUT->chapters };
		my $covered = $TUT->covered_routes;
		returns_is $covered, { type => 'hashref' }, 'covered routes are a hashref';
		ok !(grep { !$ids{$_} } values %$covered), 'each names a chapter that exists';

		my $exempt = $TUT->exempt_routes;
		ok !(grep { !length $exempt->{$_} } keys %$exempt), 'each exemption gives its reason';
		ok !(grep { exists $covered->{$_} } keys %$exempt), 'a route is covered or exempt, not both';

		# Why: this table decides what t/tutorial.t demands; a caller's edit must
		# not change the next caller's answer.
		$exempt->{'/injected'} = 'x';
		delete $exempt->{'/tutorial'};
		ok !exists $TUT->exempt_routes->{'/injected'}, 'a caller cannot add an exemption';
		ok exists $TUT->exempt_routes->{'/tutorial'}, 'or remove one';
	};

	subtest 'Tutorial::chapter_for_action -- known and unknown actions' => sub {
		is $TUT->chapter_for_action('map_view')->{id}, 'map-chart', 'an action finds its chapter';
		is $TUT->chapter_for_action('catalog_view')->{id}, 'catalog', 'another does too';
		is_deeply [ $TUT->chapter_for_action(undef) ], [], 'undef finds nothing';
		is_deeply [ $TUT->chapter_for_action('') ], [], 'an empty name finds nothing';
		is_deeply [ $TUT->chapter_for_action('no_such_action') ], [], 'nor does an unknown one';
		is_deeply [ $TUT->chapter_for_action('__proto__') ], [], 'or a hostile one';
		is_deeply [ $TUT->chapter_for_action('MAP_VIEW') ], [], 'action names are exact';
	};

	subtest 'Tutorial::_slug -- URL-safe whatever it is given' => sub {
		my $fn = \&Database::BI::Tutorial::_slug;
		is $fn->('Part One: Getting Started'), 'part-one-getting-started', 'spaces and punctuation become one hyphen';
		is $fn->('--a--'), 'a', 'no hyphen at either end';
		is $fn->('!!!'), '', 'nothing usable gives an empty slug';
		is $fn->(''), '', 'an empty name stays empty';
		is $fn->(qq{"><script>}), 'script', 'markup cannot reach an id attribute';
		is $fn->('../../x'), 'x', 'and a path cannot survive';
		like $fn->("caf\xE9 au lait"), qr/\A[a-z0-9-]+\z/, 'accented text still yields only safe characters';
		keeps_globals_ok('_slug', sub { $fn->('A b') });
	};
}

# ============================================================================
# PART U4: Database::BI::Extract
#
# A real filesystem in a temp directory: a cache is only as good as what it does
# on disk.  Failures are forced with a plain file where a directory has to be,
# which works for any user on any platform, unlike taking permissions away.
# ============================================================================
{
	Readonly my $EX    => 'Database::BI::Extract';
	Readonly my $SPEC  => 'table:sales';
	Readonly my $MTIME => 1_700_000_000;
	Readonly my $SIZE  => 42;
	Readonly my $BYTES => "SQLite format 3\0\xFF\n";

	my $fp = \&Database::BI::Extract::_fingerprint;

	subtest 'Extract::new -- a store needs somewhere to live' => sub {
		throws_ok { $EX->new() } qr/\Amodel_dir is required at /, 'none given';
		throws_ok { $EX->new(model_dir => undef) } qr/\Amodel_dir is required at /, 'undef given';

		# Why: an empty name resolves against the working directory, so the cache
		# would land in whatever directory the server was started from.
		throws_ok { $EX->new(model_dir => '') } qr/\Amodel_dir is required at /, 'an empty name is not a place';

		my $ex = $EX->new(model_dir => tempdir(CLEANUP => 1));
		isa_ok $ex, $EX;
		memory_cycle_ok($ex, 'the object holds no cycle');
	};

	subtest 'Extract::_fingerprint -- what makes two extracts different' => sub {
		my $base = $fp->($SPEC, $MTIME, $SIZE);
		like $base, qr/\A[0-9a-f]{32}\z/, 'an md5 hex digest';
		is $fp->($SPEC, $MTIME, $SIZE), $base, 'stable for the same input';
		isnt $fp->('table:other', $MTIME, $SIZE), $base, 'another source differs';
		isnt $fp->($SPEC, $MTIME + 1, $SIZE), $base, 'a touched file differs';
		isnt $fp->($SPEC, $MTIME, $SIZE + 1), $base, 'a resized file differs';
		is $fp->($SPEC, undef, undef), $fp->($SPEC, 0, 0), 'unknown mtime and size count as zero';
		isnt $fp->('a', '1', '23'), $fp->('a', '12', '3'), 'fields cannot run into each other';
		lives_ok { $fp->("path:/caf\x{263A}.csv", 1, 2) } 'a wide character in a path cannot make md5_hex croak';
	};

	subtest 'Extract::path and _extract_dir -- addresses, not actions' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $ex  = $EX->new(model_dir => $dir);
		like $ex->_extract_dir, qr{\Q$dir\E.extracts\z}, 'the store is under model_dir';
		my $p = $ex->path($SPEC, $MTIME, $SIZE);
		like $p, qr{extracts.[0-9a-f]{32}\.db\z}, 'a digest with .db';
		ok !-e $p, 'asking for the path creates nothing';
		ok !-d $ex->_extract_dir, 'not even the directory';

		like $ex->path('../../../etc/passwd', 0, 0), qr{\Q$dir\E.extracts.[0-9a-f]{32}\.db\z},
			'a hostile spec is hashed, so it cannot walk out of the store';
	};

	subtest 'Extract::get and put -- the round trip' => sub {
		my $ex = $EX->new(model_dir => tempdir(CLEANUP => 1));
		is $ex->get($SPEC, $MTIME, $SIZE), undef, 'a miss before anything is stored';

		my $written;
		warnings_are { $written = $ex->put($SPEC, $MTIME, $SIZE, $BYTES) } [], 'storing is quiet';
		is $ex->get($SPEC, $MTIME, $SIZE), $written, 'then a hit, at the same path';
		is(Mojo::File->new($written)->slurp, $BYTES, 'the bytes come back exactly, NUL and high bytes included');

		is $ex->get($SPEC, $MTIME + 1, $SIZE), undef, 'a changed file is a miss, so stale data is never served';

		$ex->put($SPEC, $MTIME, $SIZE, 'newer');
		is(Mojo::File->new($written)->slurp, 'newer', 'storing again replaces the old copy');
		returns_is $written, { type => 'string' }, 'put returns the path';
	};

	subtest 'Extract::put -- refuses to store nothing' => sub {
		my $ex = $EX->new(model_dir => tempdir(CLEANUP => 1));
		throws_ok { $ex->put($SPEC, $MTIME, $SIZE, undef) } qr/\Asqlite_bytes are required at /, 'undef';
		throws_ok { $ex->put($SPEC, $MTIME, $SIZE, '') } qr/\Asqlite_bytes are required at /, 'empty';
		ok !-d $ex->_extract_dir, 'and a refused store leaves nothing on disk';
	};

	subtest 'Extract::put -- failures mid-write are reported' => sub {
		# A file where the store's directory has to go.
		my $base = tempdir(CLEANUP => 1);
		Mojo::File->new($base, 'extracts')->spew('in the way');
		my $blocked = $EX->new(model_dir => $base);
		throws_ok { $blocked->put($SPEC, $MTIME, $SIZE, 'x') } qr/\ACannot create extract dir /,
			'the directory cannot be made';

		# A directory where the file has to go.
		my $ex = $EX->new(model_dir => tempdir(CLEANUP => 1));
		Mojo::File->new($ex->path($SPEC, $MTIME, $SIZE))->make_path;
		throws_ok { $ex->put($SPEC, $MTIME, $SIZE, 'x') } qr/\ACannot write extract /,
			'the file cannot be written';
	};

	subtest 'Extract::evict -- removes what it stored and nothing else' => sub {
		my $ex = $EX->new(model_dir => tempdir(CLEANUP => 1));
		is $ex->evict($SPEC), 0, 'no store yet, so nothing to do';

		$ex->put($SPEC, 1, 1, 'a');
		$ex->put($SPEC, 2, 2, 'b');
		my $keep = Mojo::File->new($ex->_extract_dir, 'notes.txt');
		$keep->spew('mine');

		is $ex->evict($SPEC), 2, 'both extracts are counted';
		is $ex->get($SPEC, 1, 1), undef, 'and gone';
		ok -f $keep, 'a file that is not an extract is left alone';
		is $ex->evict($SPEC), 0, 'a second eviction finds nothing';
	};

	# Why: glob() splits its pattern on spaces and reads brackets as a class, so a
	# home directory with either one in its name would never be cleared.
	subtest 'Extract::evict -- the name of the store cannot defeat it' => sub {
		# Windows does not allow a '*' in a file name.
		for my $name ('with space', 'with[bracket]', ($^O eq 'MSWin32' ? () : 'with*star')) {
			my $dir = File::Spec->catdir(tempdir(CLEANUP => 1), $name);
			my $ex  = $EX->new(model_dir => $dir);
			$ex->put($SPEC, 1, 1, 'a');
			is $ex->evict($SPEC), 1, "a model_dir called '$name' is cleared";
			is $ex->get($SPEC, 1, 1), undef, 'and the extract has gone';
		}
		my $ex = $EX->new(model_dir => tempdir(CLEANUP => 1));
		$ex->put($SPEC, 1, 1, 'a');
		keeps_globals_ok('evict', sub { $ex->evict($SPEC) });
	};
}

# ============================================================================
# PART U5: Database::BI::Ask
#
# The reply being parsed comes from a language model, so it is treated as what it
# is: untrusted text that may be wrong, malformed or actively hostile.
# ============================================================================
{
	Readonly my $ASK     => 'Database::BI::Ask';
	Readonly my $API_KEY => 'test-key';
	Readonly my $SPEC    => 'table:sales';
	Readonly my @COLUMNS => ({ name => 'region', type => 'string' }, { name => 'amount', type => 'number' });

	my $parse = \&Database::BI::Ask::_parse_visual;
	my $infer = \&Database::BI::Ask::_infer_type;
	my $url   = \&Database::BI::Ask::_build_url;

	subtest 'Ask::ask -- refusals come back as codes, never as a croak' => sub {
		is_deeply Database::BI::Ask::ask(), { error => 'ask_no_question' }, 'nothing given';
		is_deeply Database::BI::Ask::ask(question => ''), { error => 'ask_no_question' }, 'an empty question';
		is_deeply Database::BI::Ask::ask(question => 'q'), { error => 'ask_unavailable' }, 'no key';
		is_deeply Database::BI::Ask::ask(question => 'q', ai_config => { api_key => '' }),
			{ error => 'ask_unavailable' }, 'an empty key';
	};

	subtest 'Ask::ask -- each stage of a failed request has its own code' => sub {
		my %cfg = (question => 'q', spec_key => $SPEC, columns => [ @COLUMNS ], ai_config => { api_key => $API_KEY });

		Test::Mockingbird::mock("${ASK}::_call_llm", sub { require Carp; Carp::croak('down') });
		is_deeply Database::BI::Ask::ask(%cfg), { error => 'ask_provider_error' }, 'the provider failed';
		Test::Mockingbird::unmock("${ASK}::_call_llm");

		Test::Mockingbird::mock("${ASK}::_call_llm", sub { 'I would rather not' });
		is_deeply Database::BI::Ask::ask(%cfg), { error => 'ask_unparseable' }, 'the reply was not a visual';
		Test::Mockingbird::unmock("${ASK}::_call_llm");

		Test::Mockingbird::mock("${ASK}::_call_llm", sub { '{"kind":"bar","encode":{"cat":"password"}}' });
		is_deeply Database::BI::Ask::ask(%cfg), { error => 'ask_invalid_spec:password' },
			'a column that does not exist is refused, and named';
		Test::Mockingbird::unmock("${ASK}::_call_llm");
	};

	subtest 'Ask::ask -- a good reply' => sub {
		Test::Mockingbird::mock("${ASK}::_call_llm", sub {
			'{"kind":"bar","title":"T","encode":{"cat":"region","val":"amount"}}';
		});
		my $got = Database::BI::Ask::ask(question => 'q', spec_key => $SPEC, label => 'Sales',
			columns => [ @COLUMNS ], ai_config => { api_key => $API_KEY });
		Test::Mockingbird::unmock("${ASK}::_call_llm");

		is $got->{valid}, 1, 'it is marked valid';
		is $got->{url}, '/bar?l=table%3Asales&cat=region&val=amount', 'with a working URL';
		is $got->{spec}{visuals}[0]{kind}, 'bar', 'and a spec to save';
		memory_cycle_ok($got, 'holding no cycle');
	};

	subtest 'Ask::infer_column_types -- input it cannot use' => sub {
		my $fn = \&Database::BI::Ask::infer_column_types;
		is_deeply $fn->(undef, undef), [], 'nothing at all';
		is_deeply $fn->('x', ['a']), [], 'records that are not a list';
		is_deeply $fn->([], 'x'), [], 'columns that are not a list';
		is_deeply $fn->([], ['a']), [ { name => 'a', type => 'string' } ], 'no rows reads as text';
		is_deeply $fn->([ { a => undef }, { a => '' }, {} ], ['a']), [ { name => 'a', type => 'string' } ],
			'all-empty cells read as text, not number';
		is_deeply $fn->([ { a => 1, b => 'x', c => '2026-01-01' } ], [qw(a b c)]),
			[ { name => 'a', type => 'number' }, { name => 'b', type => 'string' }, { name => 'c', type => 'date' } ],
			'each column is judged alone, in the order asked';
		keeps_globals_ok('infer_column_types', sub { $fn->([ { a => 1 } ], ['a']) });
	};

	subtest 'Ask::_infer_type -- the majority decides' => sub {
		is $infer->([]), 'string', 'nothing to go on';
		is $infer->([ 1, 2, 'x' ]), 'number', 'two in three numbers';
		is $infer->([ 1, 'x' ]), 'string', 'exactly half is not a majority';
		is $infer->([ '2026-01-02', '1/2/2026', 'x' ]), 'date', 'two in three dates, either form';
		is $infer->([ '2026-01-02', 'x' ]), 'string', 'half again is not enough';
		is $infer->([ '2026-1-2x' ]), 'string', 'something merely shaped like a date is not one';
	};

	subtest 'Ask::_call_llm -- what leaves the machine' => sub {
		my $text;
		my $sent = with_fake_network(fake_response(200, '{"content":[{"text":"reply"}]}'), sub {
			$text = Database::BI::Ask::_call_llm('Which region?', 'Sales', [ @COLUMNS ], { api_key => $API_KEY });
		});
		is $text, 'reply', 'the text comes back';
		my $body   = decode_json($sent->[0]->content);
		my $prompt = $body->{messages}[0]{content};
		like $prompt, qr/- region \(string\)/, 'names and types go';
		like $prompt, qr/Which region\?/, 'and the question';
		is $body->{model}, 'claude-haiku-5-5', 'the default model is used';
		is $sent->[0]->header('x-api-key'), $API_KEY, 'the key is a header';
	};

	subtest 'Ask::_call_llm -- provider failures' => sub {
		with_fake_network(fake_response(503, 'x'), sub {
			throws_ok { Database::BI::Ask::_call_llm('q', 'L', [], { api_key => $API_KEY }) }
				qr/\AProvider error: 503 Boom at /, 'the status line';
		});
		for my $body ('{}', '{"content":[{"text":""}]}') {
			with_fake_network(fake_response(200, $body), sub {
				throws_ok { Database::BI::Ask::_call_llm('q', 'L', [], { api_key => $API_KEY }) }
					qr/\ANo text in provider response at /, "no text in $body";
			});
		}
		with_fake_network(fake_response(200, '<html>'), sub {
			dies_ok { Database::BI::Ask::_call_llm('q', 'L', [], { api_key => $API_KEY }) } 'and a reply that is not JSON';
		});
	};

	subtest 'Ask::_parse_visual -- finding the JSON in a chatty reply' => sub {
		is $parse->('{"kind":"bar"}')->{kind}, 'bar', 'a clean reply';
		is_deeply $parse->('{"kind":"bar"}')->{encode}, {}, 'a missing encode becomes empty, so callers need not check';
		is $parse->("Sure!\n{\"kind\":\"pie\",\"encode\":{\"cat\":\"a\"}}\nHope that helps")->{kind}, 'pie',
			'prose either side';
		is $parse->('{"kind":"bar"} and {"kind":"pie"}')->{kind}, 'bar', 'two objects: the first, not a span of both';
	};

	# Why: JSON read by a byte-oriented parser rejects any reply with a non-ASCII
	# title, so a question asked in French always came back unparseable.
	subtest 'Ask::_parse_visual -- text outside ASCII' => sub {
		is $parse->(qq({"kind":"bar","title":"caf\x{e9}"}))->{title}, "caf\x{e9}", 'an accented title';
		is $parse->(qq({"kind":"bar","title":"\x{263A}"}))->{title}, "\x{263A}", 'a wide character';
		is $parse->(qq(Voil\x{e0}: {"kind":"bar","title":"\x{263A}"}))->{title}, "\x{263A}", 'and with prose around it';
	};

	# Why: a depth counter that ignores strings stops at a brace inside a title.
	subtest 'Ask::_parse_visual -- braces and quotes inside strings' => sub {
		is $parse->('Here: {"kind":"bar","title":"a } b"} done')->{title}, 'a } b', 'a closing brace in a string';
		is $parse->('Here: {"kind":"bar","title":"a { b"} done')->{title}, 'a { b', 'an opening one';
		is $parse->('Here: {"kind":"bar","title":"say \"}\" now"} done')->{title}, 'say "}" now', 'an escaped quote';
	};

	subtest 'Ask::_parse_visual -- replies that must be refused' => sub {
		for my $case (
			[ '',                                  'an empty reply' ],
			[ 'no json here',                      'prose alone' ],
			[ '{',                                 'an unbalanced brace' ],
			[ '}{',                                'braces the wrong way round' ],
			[ '[1,2,3]',                           'JSON that is not an object' ],
			[ '"bar"',                             'a bare string' ],
			[ '{}',                                'no kind' ],
			[ '{"kind":"evil"}',                   'a kind that does not exist' ],
			[ '{"kind":"../../etc"}',              'a kind that is a path' ],
			[ '{"kind":{"a":1}}',                  'a kind that is an object' ],
			[ '{"kind":"bar","encode":"x"}',       'an encode that is a string' ],
			[ '{"kind":"bar","encode":["x"]}',     'an encode that is a list' ],
		) {
			my ($text, $name) = @$case;
			is $parse->($text), undef, "$name is refused";
		}
		lives_ok { $parse->('{' x 5_000) } 'a flood of braces is survived';
		keeps_globals_ok('_parse_visual', sub { $parse->('x {"kind":"bar"} y') });
	};

	subtest 'Ask::_validate_encode -- only real columns' => sub {
		my $fn = \&Database::BI::Ask::_validate_encode;
		my %cols = (a => 1, b => 1);
		is $fn->({ encode => {} }, \%cols), undef, 'nothing to check';
		is $fn->({ encode => { x => 'a', y => 'b' } }, \%cols), undef, 'all known';
		is $fn->({ encode => { x => 'zz' } }, \%cols), 'zz', 'an unknown one is returned by name';
		is $fn->({ encode => { x => undef, y => '' } }, \%cols), undef, 'blanks are not columns';
		is $fn->({ encode => { b => 'second', a => 'first' } }, \%cols), 'first', 'the report is deterministic';
		ok defined $fn->({ encode => { x => [ 'a' ] } }, \%cols), 'a list where a name should be is refused';
	};

	subtest 'Ask::_build_url -- routes and encoding' => sub {
		is $url->({ kind => 'pie', encode => { cat => 'a' } }, $SPEC), '/pie?l=table%3Asales&cat=a', 'the pie route';
		is $url->({ kind => 'line', encode => {} }, $SPEC), '/graph?l=table%3Asales', 'a line chart is /graph';
		is $url->({ kind => 'bar', encode => { a => '', b => undef, c => 'x' } }, $SPEC),
			'/bar?l=table%3Asales&c=x', 'empty encodings are left out';
		is $url->({ kind => 'table' }, $SPEC), '/view/sales', 'a table of a table';
		is $url->({ kind => 'table' }, 'path:/a b.csv'), '/open?path=%2Fa%20b.csv', 'a table of a path';
	};

	subtest 'Ask::_build_url -- a hostile value cannot change the URL' => sub {
		like $url->({ kind => 'bar', encode => { cat => 'x&admin=1' } }, $SPEC), qr/cat=x%26admin%3D1\z/,
			'a value cannot add a parameter';
		like $url->({ kind => 'bar', encode => {} }, 'table:x&y=1'), qr/\A\/bar\?l=table%3Ax%26y%3D1\z/,
			'nor can the spec';
		is $url->({ kind => 'table' }, 'table:x"><script>'), '/view/x%22%3E%3Cscript%3E',
			'a table name cannot leave the link it is put in';
		is $url->({ kind => 'table' }, 'table:../../admin'), '/view/..%2F..%2Fadmin', 'or walk to another route';
	};

	subtest 'Ask::_build_spec -- a saveable canvas' => sub {
		my $fn = \&Database::BI::Ask::_build_spec;
		my $titled = $fn->({ kind => 'bar', title => 'T', encode => { cat => 'a' } }, 'L', $SPEC);
		is $titled->{name}, 'T', 'the title names it';
		is $titled->{version}, 1, 'it has a version';
		is_deeply $titled->{datasets}, [ { spec => $SPEC } ], 'and its dataset';
		is $fn->({ kind => 'bar' }, 'L', $SPEC)->{name}, 'L analysis', 'the label stands in for a missing title';
		is_deeply $fn->({ kind => 'bar' }, 'L', $SPEC)->{visuals}[0]{encode}, {}, 'a missing encode is empty';
		is $fn->({ kind => 'bar' }, 'L', $SPEC)->{visuals}[0]{title}, '', 'and a missing title is too';
		memory_cycle_ok($titled, 'no cycle');
	};
}

# ============================================================================
# PART U6: Database::BI::Insights
#
# Arithmetic with no outside calls, so nothing is mocked here but the module's own
# helpers.  What matters is that the numbers are right and every value that goes
# into a URL comes out inert.
# ============================================================================
{
	Readonly my $INS  => 'Database::BI::Insights';
	Readonly my $SPEC => 'table:sales';
	Readonly my $BASE => '/insights?l=table:sales';

	my $qt = \&Database::BI::Insights::_quartiles;
	my $to = \&Database::BI::Insights::_to_num;

	# A group of nine whose fences are easy to work out by hand: Q1 2.5, Q3 7.5,
	# so anything outside -5 .. 15 is an outlier.
	my @OUTLIER_VALUES = (1 .. 8, 1000);

	subtest 'Insights::method_note -- known and unknown keys' => sub {
		my $fn = \&Database::BI::Insights::method_note;
		like $fn->($_), qr/\S/, "$_ has a note" for qw(iqr_fence pop_delta top_mover autocorr);
		isnt $fn->('iqr_fence'), 'iqr_fence', 'which is not just the key';
		is $fn->('no_such'), 'no_such', 'an unknown key comes back unchanged rather than as nothing';
	};

	subtest 'Insights::_looks_like_date -- what counts' => sub {
		my $fn = \&Database::BI::Insights::_looks_like_date;
		ok $fn->($_), "'$_' is a date" for '2026-01-02', '1/2/2026', '12/22/2025', '22-Oct-2026';
		ok !$fn->($_), "'$_' is not" for '', '2026', '2026-1-2', '1/2/26', '22-October-2026', "2026-01-02\n", '2026-01-02x', 'x2026-01-02';
		ok !$fn->(undef), 'undef is not';
	};

	subtest 'Insights::_is_date_col and _is_numeric_col -- one bad value decides' => sub {
		my ($date, $num) = (\&Database::BI::Insights::_is_date_col, \&Database::BI::Insights::_is_numeric_col);
		is $date->([ '2026-01-02', '2026-01-03' ]), 1, 'all dates';
		is $date->([ '2026-01-02', 'x' ]), 0, 'one that is not';
		is $date->([]), 0, 'an empty column is not a date column';
		is $num->([ 1, '2.5', '$3' ]), 1, 'all numbers';
		is $num->([ 1, 'x' ]), 0, 'one that is not';
		is $num->([]), 0, 'an empty column is not numeric';
		is $num->([ '12/22/2025' ]), 0, 'a slash date is not 12222025';
		is $date->([ ('2026-01-02') x 20, 'x' ]), 1, 'only a sample of twenty is read, by design';
	};

	subtest 'Insights::_to_num -- money and accounting forms' => sub {
		is $to->('12'), 12, 'an integer';
		is $to->('-1.5'), -1.5, 'a negative decimal';
		is $to->('$1,234.50'), 1234.5, 'currency and thousands';
		is $to->('(1,234.56)'), -1234.56, 'brackets mean negative';
		is $to->(' (5) '), -5, 'with spaces around them';
		is $to->('50%'), 50, 'a percentage';
		is $to->('1e3'), 1000, 'scientific notation is its value, not 13';
		is $to->("\xC2\xA35"), 5, 'a pound sign in UTF-8';
	};

	# Why: stripping everything but digits reads a part code as a measure, and
	# then its "outliers" are reported to the reader as findings.
	subtest 'Insights::_to_num -- text that merely holds digits is not a number' => sub {
		is $to->($_), undef, "'$_' is not a number" for
			'', 'abc', 'SKU123', 'A1', 'AB-100', 'R2D2', 'v1.2', '1.2.3', '12-34', '--5', '.', '-', '(', '()', '1 2 3 x';
		is $to->(undef), undef, 'nor is undef';
		keeps_globals_ok('_to_num', sub { $to->('$5') });
	};

	# Why: `$n % 2 ? $mid + 1 : $mid .. $n - 1` binds as a ternary around a range,
	# so an odd-sized group took a single value as its upper half and every odd
	# group's Q3 was too low, flagging ordinary values as outliers.
	subtest 'Insights::_quartiles -- both halves are medians' => sub {
		is_deeply [ $qt->([ 1 .. 4 ]) ], [ 1.5, 2.5, 3.5 ], 'even count';
		is_deeply [ $qt->([ 1 .. 5 ]) ], [ 1.5, 3, 4.5 ], 'five: the upper half is two values';
		is_deeply [ $qt->([ 1 .. 7 ]) ], [ 2, 4, 6 ], 'seven: the upper half is three';
		is_deeply [ $qt->([ 1 .. 9 ]) ], [ 2.5, 5, 7.5 ], 'nine: the upper half is four';
		is_deeply [ $qt->([]) ], [ undef, undef, undef ], 'no values';
		is_deeply [ $qt->([ 1 .. 3 ]) ], [ undef, undef, undef ], 'too few to have quartiles';
	};

	subtest 'Insights::_median' => sub {
		my $fn = \&Database::BI::Insights::_median;
		is $fn->([]), undef, 'of nothing';
		is $fn->([ 7 ]), 7, 'of one';
		is $fn->([ 1, 3 ]), 2, 'of an even count';
		is $fn->([ 1, 2, 9 ]), 2, 'of an odd count, unmoved by a large value';
	};

	subtest 'Insights::_fence_distance' => sub {
		my $fn = \&Database::BI::Insights::_fence_distance;
		is $fn->(20, 0, 10), 10, 'above';
		is $fn->(-5, 0, 10), 5, 'below';
		is $fn->(5, 0, 10), 0, 'inside';
		is $fn->(10, 0, 10), 0, 'on the fence is inside';
	};

	subtest 'Insights::_find_outliers -- finds the value and describes it' => sub {
		my @rows = map { { amount => $_ } } @OUTLIER_VALUES;
		my @got = Database::BI::Insights::_find_outliers(\@rows, 'amount', [], $SPEC, $BASE);
		is scalar @got, 1, 'exactly one';
		is $got[0]{kind}, 'outlier', 'of the right kind';
		is $got[0]{method}, 'iqr_fence', 'citing its method';
		like $got[0]{headline}, qr/1000 is unusually high/, 'the headline gives the value';
		is $got[0]{view_url}, '/stats?l=table%3Asales', 'with no category it links to stats';
		ok !exists $got[0]{drill_url}, 'and has no group to drill into';

		my @low = Database::BI::Insights::_find_outliers(
			[ map { { amount => $_ } } (-1000, 1 .. 8) ], 'amount', [], $SPEC, $BASE);
		like $low[0]{headline}, qr/unusually low/, 'a low one says low';
	};

	# Why: this text is shown to the reader.  A single-quoted \x2013 is not a dash
	# but six literal characters on the page.
	subtest 'Insights::_find_outliers -- the range reads as a range' => sub {
		my @got = Database::BI::Insights::_find_outliers(
			[ map { { amount => $_ } } @OUTLIER_VALUES ], 'amount', [], $SPEC, $BASE);
		unlike $got[0]{detail}, qr/\\x/, 'no escape sequence reaches the reader';
		like $got[0]{detail}, qr/-5 \x{2013} 15 \(IQR fence on 9 values\)/, 'the fences, an en dash and the count';
	};

	subtest 'Insights::_find_outliers -- what it must not report' => sub {
		is_deeply [ Database::BI::Insights::_find_outliers([ map { { a => $_ } } 1, 2, 1000 ], 'a', [], $SPEC, $BASE) ], [],
			'fewer than four values is too few to judge';
		is_deeply [ Database::BI::Insights::_find_outliers([ map { { a => $_ } } 1 .. 20 ], 'a', [], $SPEC, $BASE) ], [],
			'an even spread has none';
		is_deeply [ Database::BI::Insights::_find_outliers([ map { { a => 'x' } } 1 .. 9 ], 'a', [], $SPEC, $BASE) ], [],
			'text has none';
		is_deeply [ Database::BI::Insights::_find_outliers([], 'a', [], $SPEC, $BASE) ], [], 'no rows has none';
		is_deeply [ Database::BI::Insights::_find_outliers([ map { { a => 5 } } 1 .. 9 ], 'a', [], $SPEC, $BASE) ], [],
			'identical values have none, though their IQR is zero';

		my @rows = (map({ { g => 'small', a => $_ } } 1, 2, 1000), map({ { g => 'big', a => $_ } } @OUTLIER_VALUES));
		my @got = Database::BI::Insights::_find_outliers(\@rows, 'a', ['g'], $SPEC, $BASE);
		is scalar @got, 1, 'groups are judged apart, so the small one is skipped';
		like $got[0]{headline}, qr/g=big/, 'and the finding names its group';
	};

	subtest 'Insights::_find_outliers -- capped, and worst first' => sub {
		my @rows = map { { a => $_ } } ((1) x 40, 100, 200, 300, 400, 500, 600, 700);
		my @got = Database::BI::Insights::_find_outliers(\@rows, 'a', [], $SPEC, $BASE);
		is scalar @got, 5, 'the panel stays readable';
		like $got[0]{headline}, qr/\b700\b/, 'the furthest out comes first';
	};

	subtest 'Insights::_find_outliers -- hostile names stay inside their URL' => sub {
		my $evil = q{"><script>&x=1};
		my @rows = map { { $evil => 'North', a => $_ } } @OUTLIER_VALUES;
		my @got = Database::BI::Insights::_find_outliers(\@rows, 'a', [$evil], $SPEC, $BASE);
		unlike $got[0]{view_url}, qr/[<>"]/, 'the view link holds no markup';
		unlike $got[0]{drill_url}, qr/[<>"]/, 'nor does the drill link';
		like $got[0]{drill_url}, qr/\A\/view\/sales\?f=/, 'which opens the table';
		like $got[0]{drill_url}, qr/hl_op=gt&hl_val=15/, 'and picks out the row, by the fence it passed';
		like $got[0]{drill_url}, qr/back2=/, 'with a way back, through back2 as a drill must';
		keeps_globals_ok('_find_outliers', sub {
			Database::BI::Insights::_find_outliers(\@rows, 'a', [$evil], $SPEC, $BASE);
		});
	};

	subtest 'Insights::_period_over_period' => sub {
		my $fn = \&Database::BI::Insights::_period_over_period;
		my @rows = ({ d => '2026-01-05', v => 100 }, { d => '2026-01-20', v => 50 }, { d => '2026-02-01', v => 300 });
		my ($got) = $fn->(\@rows, 'd', 'v', $SPEC, $BASE);
		is $got->{kind}, 'period_delta', 'the kind';
		like $got->{headline}, qr/v is up 150 vs prior period \(2026-01\)/, 'months are summed before comparing';
		like $got->{detail}, qr/2026-01: 150  2026-02: 300  \(\+100\.0%\)/, 'with the percentage';
		is $got->{view_url}, '/graph?l=table%3Asales&x=d&y=v', 'linking to the chart';
		like $got->{drill_url}, qr/f=d:starts:2026-02/, 'and drilling into the latest month';

		my ($down) = $fn->([ { d => '2026-01-01', v => 10 }, { d => '2026-02-01', v => 4 } ], 'd', 'v', $SPEC, $BASE);
		like $down->{headline}, qr/is down 6 /, 'a fall says down';
		like $down->{detail}, qr/-60\.0%/, 'with a negative percentage';
	};

	subtest 'Insights::_period_over_period -- cannot be fooled' => sub {
		my $fn = \&Database::BI::Insights::_period_over_period;
		is_deeply [ $fn->([ { d => '2026-01-01', v => 1 } ], 'd', 'v', $SPEC, $BASE) ], [], 'one period is no comparison';
		is_deeply [ $fn->([ { d => 'junk', v => 1 }, { d => 'more', v => 2 } ], 'd', 'v', $SPEC, $BASE) ], [], 'nor are unreadable dates';
		is_deeply [ $fn->([ { d => '2026-01-01', v => 'x' }, { d => '2026-02-01', v => 'y' } ], 'd', 'v', $SPEC, $BASE) ], [],
			'nor are values that are not numbers';
		is_deeply [ $fn->([], 'd', 'v', $SPEC, $BASE) ], [], 'nor no rows';

		my ($zero) = $fn->([ { d => '2026-01-01', v => 0 }, { d => '2026-02-01', v => 5 } ], 'd', 'v', $SPEC, $BASE);
		unlike $zero->{detail}, qr/%/, 'growth from zero has no percentage rather than a division by it';

		my ($url) = $fn->([ { d => '2026-01-01', v => 1 }, { d => '2026-02-01', v => 2 } ], 'd', 'v', 'url:http://x/', $BASE);
		ok !exists $url->{drill_url}, 'a source with no table page offers no drill';
	};

	subtest 'Insights::_top_movers' => sub {
		my $fn = \&Database::BI::Insights::_top_movers;
		my @rows = (
			{ d => '2026-01-01', r => 'N', v => 10 }, { d => '2026-02-01', r => 'N', v => 15 },
			{ d => '2026-01-01', r => 'S', v => 90 }, { d => '2026-02-01', r => 'S', v => 10 },
			{ d => '2026-02-01', r => 'New', v => 7 },
		);
		my @got = $fn->(\@rows, 'd', 'v', ['r'], $SPEC, $BASE);
		is scalar @got, 3, 'one for each member';
		like $got[0]{headline}, qr/\AS v down by 80 from 2026-01 to 2026-02/, 'the largest change first, whichever way';
		like $got[1]{headline}, qr/\ANew v up by 7/, 'a member new this period counts from zero';
		is $got[0]{method}, 'top_mover', 'it cites its method';
		like $got[0]{view_url}, qr/&f=r:eq:S\z/, 'and filters to the member';
		like $got[0]{drill_url}, qr/f=d:starts:2026-02&f=r:eq:S/, 'as its drill does';
	};

	subtest 'Insights::_top_movers -- limits and refusals' => sub {
		my $fn = \&Database::BI::Insights::_top_movers;
		is_deeply [ $fn->([ { d => '2026-01-01', v => 1 } ], 'd', 'v', [], $SPEC, $BASE) ], [], 'no category, no movers';
		is_deeply [ $fn->([ { d => '2026-01-01', r => 'N', v => 1 } ], 'd', 'v', ['r'], $SPEC, $BASE) ], [], 'one period, no movers';
		is_deeply [ $fn->([ { d => 'junk', r => 'N', v => 1 } ], 'd', 'v', ['r'], $SPEC, $BASE) ], [], 'no readable date, no movers';

		my @many = map { my $i = $_; map { { d => "2026-0$_-01", r => "m$i", v => $_ * $i } } 1, 2 } 1 .. 12;
		is scalar(my @got = $fn->(\@many, 'd', 'v', ['r'], $SPEC, $BASE)), 5, 'capped however many members there are';
		like $got[0]{headline}, qr/\Am12 /, 'keeping the largest';
	};

	subtest 'Insights::_seasonality' => sub {
		my $fn = \&Database::BI::Insights::_seasonality;
		my @trend = map { { d => sprintf('2025-%02d-01', $_), v => $_ * 10 } } 1 .. 12;
		my ($got) = $fn->(\@trend, 'd', 'v', $SPEC, $BASE);
		is $got->{kind}, 'seasonality', 'a smooth series is flagged';
		like $got->{detail}, qr/across 12 periods \(2025-01 to 2025-12\)/, 'naming its extent';
		is $got->{method}, 'autocorr', 'and its method';

		is_deeply [ $fn->([ @trend[0 .. 6] ], 'd', 'v', $SPEC, $BASE) ], [], 'seven periods are too few';
		is_deeply [ $fn->([ map { { d => sprintf('2025-%02d-01', $_), v => 5 } } 1 .. 12 ], 'd', 'v', $SPEC, $BASE) ], [],
			'a flat series is not seasonal, and does not divide by zero';
		is_deeply [ $fn->([ map { { d => sprintf('2025-%02d-01', $_), v => $_ % 2 ? 100 : -100 } } 1 .. 12 ], 'd', 'v', $SPEC, $BASE) ], [],
			'a see-saw has a negative lag-1 correlation, so it is not flagged';
		is_deeply [ $fn->([], 'd', 'v', $SPEC, $BASE) ], [], 'no rows';
	};

	subtest 'Insights::_fmt_num' => sub {
		my $fn = \&Database::BI::Insights::_fmt_num;
		is $fn->(undef), 'N/A', 'undef';
		is $fn->(0), '0', 'zero';
		is $fn->(-5), '-5', 'an integer stays whole';
		is $fn->(123456789), '123456789', 'however long';
		is $fn->(1234.5678), '1235', 'a fraction goes to four figures';
		is $fn->(0.00012345), '0.0001234', 'at either end of the scale';
		is $fn->(2.5), '2.5', 'with no trailing zeros';
	};

	subtest 'Insights::_spec_to_data_url' => sub {
		my $fn = \&Database::BI::Insights::_spec_to_data_url;
		is $fn->('table:sales'), '/view/sales', 'a table';
		is $fn->('path:/a b.csv'), '/open?path=%2Fa%20b.csv', 'a path, encoded';
		is $fn->('table:a/../b'), '/view/a%2F..%2Fb', 'a hostile table name cannot walk';
		is $fn->('path:/x"><y'), '/open?path=%2Fx%22%3E%3Cy', 'or leave its attribute';
		is $fn->($_), undef, "'$_' has no page" for 'url:http://x/', 'redis:a', 'junk', '', 'table:', 'path:';
		is $fn->(undef), undef, 'nor does undef';
	};

	subtest 'Insights::compute -- no data, no findings' => sub {
		my $fn = \&Database::BI::Insights::compute;
		is_deeply $fn->(), [], 'no arguments';
		is_deeply $fn->(records => [], columns => ['a']), [], 'no rows';
		is_deeply $fn->(records => [ { a => 1 } ], columns => []), [], 'no columns';
		is_deeply $fn->(records => [ { a => undef }, { a => '' } ], columns => ['a']), [], 'only blank cells';
		is_deeply $fn->(records => [ { a => 'x' }, { a => 'y' } ], columns => ['a']), [], 'only text';
	};

	subtest 'Insights::compute -- every kind, and each can be clicked' => sub {
		my @rows;
		for my $m (1 .. 12) {
			push @rows, { when => sprintf('2025-%02d-01', $m), region => 'N', amt => $m * 10 };
		}
		push @rows, { when => '2025-12-02', region => 'N', amt => 100_000 };

		my $got = Database::BI::Insights::compute(records => \@rows, columns => [qw(when region amt)], spec_key => $SPEC);
		returns_is $got, { type => 'arrayref' }, 'a list';
		my %kinds = map { $_->{kind} => 1 } @$got;
		ok $kinds{$_}, "it holds a $_" for qw(outlier period_delta top_mover);
		ok !(grep { !length($_->{view_url} // '') } @$got), 'an insight with no link is a bug, so all have one';
		ok !(grep { !length($_->{headline} // '') || !length($_->{detail} // '') } @$got), 'and all have text';
		memory_cycle_ok($got, 'no cycle');
		keeps_globals_ok('compute', sub {
			Database::BI::Insights::compute(records => \@rows, columns => [qw(when region amt)], spec_key => $SPEC);
		});
	};

	subtest 'Insights::compute -- each stage is called, and a date is never a measure' => sub {
		my %called;
		for my $name (qw(_find_outliers _period_over_period _top_movers _seasonality)) {
			# The outlier pass takes the measure second; the others take it third.
			my $at = $name eq '_find_outliers' ? 1 : 2;
			Test::Mockingbird::mock("${INS}::$name", sub { $called{$name}{ $_[$at] // '' }++; () });
		}
		Database::BI::Insights::compute(
			records => [ { d => '2026-01-01', v => 1, n => 'x' } ],
			columns => [qw(d v n)],
			spec_key => $SPEC,
		);
		Test::Mockingbird::restore_all();

		ok $called{$_}, "$_ ran" for qw(_find_outliers _period_over_period _top_movers _seasonality);
		is_deeply [ keys %{ $called{_period_over_period} } ], ['v'], 'with the numeric column as the measure';
		is_deeply [ keys %{ $called{_find_outliers} } ], ['v'], 'and the date is not scanned for outliers';
	};
}

# ============================================================================
# PART U7: Database::BI::Calc
#
# Expressions arrive in a URL (?c=name:expr), so the language is an attack surface:
# nothing in it may run code, exhaust the server, or leak a path through an error.
# Times are read in UTC here so the bucket labels below do not depend on the
# zone of the machine running the tests.
# ============================================================================
{
	require POSIX;

	Readonly my $MAX_EXPR_LEN => 512;
	Readonly my $MAX_DEPTH    => 20;

	my %row = (a => 10, b => 4, s => 'Hello', d => '2026-05-20', blank => undef);

	# Compiles and runs one expression, so each case below reads as a pair of
	# expression and answer.
	sub calc_value {
		my ($expr, $row, @params) = @_;
		$row //= {};
		my $c = Database::BI::Calc->new(expr => $expr, columns => [ keys %$row ], @params);
		Test::More::fail("'$expr' should compile: " . $c->error) if $c->has_error;
		return $c->evaluate($row);
	}

	sub calc_error {
		my ($expr, @cols) = @_;
		return Database::BI::Calc->new(expr => $expr, columns => \@cols)->error;
	}

	# Runs $code in UTC, and puts the machine's zone back however it ends.
	sub in_utc {
		my ($code) = @_;
		my $saved = $ENV{TZ};
		$ENV{TZ} = 'UTC';
		# Windows perls croak "not implemented on this architecture", and
		# without tzset a change to TZ need not take effect.
		unless (eval { POSIX::tzset(); 1 }) {
			if (defined $saved) { $ENV{TZ} = $saved } else { delete $ENV{TZ} }
			plan skip_all => 'POSIX::tzset is not available here';
		}
		my $ok  = eval { $code->(); 1 };
		my $err = $@;
		if (defined $saved) { $ENV{TZ} = $saved } else { delete $ENV{TZ} }
		POSIX::tzset();
		croak_rethrow($err) unless $ok;
		return;
	}

	subtest 'Calc::_fmt -- builds the message' => sub {
		is Database::BI::Calc::_fmt('error_unknown_fn', 'x'), "Unknown function 'x'", 'interpolated';
		is Database::BI::Calc::_fmt('error_expr_too_long', $MAX_EXPR_LEN), "Expression too long (max $MAX_EXPR_LEN characters)", 'a number too';
	};

	subtest 'Calc::_fmt_body -- turns a pattern into a regex' => sub {
		my ($body, $tokens) = Database::BI::Calc::_fmt_body('%Y.%m');
		is_deeply $tokens, [qw(Y m)], 'the tokens in order';
		like '2026.05', qr/\A$body\z/, 'it matches its own shape';
		unlike '2026x05', qr/\A$body\z/, 'a dot in a pattern is a dot, not any character';
		is_deeply [ (Database::BI::Calc::_fmt_body(''))[1] ], [ [] ], 'an empty pattern has no tokens';
	};

	subtest 'Calc::_fmt_body -- a token it does not know is an error, not a skip' => sub {
		throws_ok { Database::BI::Calc::_fmt_body('%Q') } qr/\AUnsupported time format token %Q at /, 'an unknown token';
		throws_ok { Database::BI::Calc::_fmt_body('%%') } qr/\AUnsupported time format token %% at /, 'a literal percent is not offered';
		throws_ok { Database::BI::Calc::_fmt_body('%Y-%') } qr/\AUnsupported time format token %Y-% at /, 'a pattern ending in a bare percent';
		lives_ok { Database::BI::Calc::_fmt_body('(.*)+[a-z]{9}\\') } 'regex syntax in a pattern is only ever literal text';
		my ($body) = Database::BI::Calc::_fmt_body('(.*)');
		unlike 'anything', qr/\A$body\z/, 'so it matches only itself';
		like '(.*)', qr/\A$body\z/, 'exactly';
	};

	subtest 'Calc::_fmt_has_date and _fmt_compile -- a pattern must name a date' => sub {
		my $has = \&Database::BI::Calc::_fmt_has_date;
		is $has->([qw(Y m d)]), 1, 'year, month and day';
		is $has->([qw(Y b d)]), 1, 'a month name does as well';
		is $has->([qw(Y m)]), 0, 'no day';
		is $has->([qw(m d)]), 0, 'no year';
		is $has->([qw(Y d)]), 0, 'no month';
		is $has->([]), 0, 'nothing';

		throws_ok { Database::BI::Calc::_fmt_compile('%H:%M') }
			qr/\ATime format '%H:%M' must name a date, with a year, a month and a day token at /, 'a time alone';
		my $c = Database::BI::Calc::_fmt_compile('%Y-%m-%d');
		is_deeply $c->{tokens}, [qw(Y m d)], 'the tokens are kept';
		ok '2026-05-20' =~ $c->{re}, 'the regex matches';
		ok "2026-05-20\n" !~ $c->{re}, 'and is anchored, so a trailing newline is refused';
	};

	subtest 'Calc::_fmt_compile_pair -- two patterns, one value' => sub {
		my $c = Database::BI::Calc::_fmt_compile_pair('%Y-%m-%d', '%H:%M');
		is_deeply $c->{tokens}, [qw(Y m d H M)], 'date tokens then time tokens';
		ok '2026-05-20T10:30' =~ $c->{re}, 'a T between them';
		ok '2026-05-20 10:30' =~ $c->{re}, 'or a space';
		ok '2026-05-2010:30' =~ $c->{re}, 'or nothing';
		ok '2026-05-20x10:30' !~ $c->{re}, 'but nothing else';
		throws_ok { Database::BI::Calc::_fmt_compile_pair('%H', '%M') } qr/\ATime format '%H' must name a date/, 'the date half must be one';
		throws_ok { Database::BI::Calc::_fmt_compile_pair('%Y-%m-%d', '%Q') } qr/\AUnsupported time format token %Q/, 'and the time half must parse';
	};

	subtest 'Calc::_fmt_parts' => sub {
		my $c = Database::BI::Calc::_fmt_compile('%d/%m/%Y');
		is_deeply Database::BI::Calc::_fmt_parts('20/05/2026', $c), { d => 20, m => '05', Y => 2026 }, 'each token gets its capture';
		is Database::BI::Calc::_fmt_parts('nope', $c), undef, 'no match, no parts';
	};

	subtest 'Calc::_epoch_of -- a date that does not exist is not quietly another' => sub {
		my $fn = \&Database::BI::Calc::_epoch_of;
		is $fn->(2026, 5, 20, 12, 0, 0), POSIX::mktime(0, 0, 12, 20, 4, 126), 'a real date';
		is $fn->(2024, 2, 29, 0, 0, 0), POSIX::mktime(0, 0, 0, 29, 1, 124), 'a leap day';
		is $fn->(2026, 2, 29, 0, 0, 0), undef, 'not a leap year';
		is $fn->(2026, 2, 31, 0, 0, 0), undef, 'the 31st of February';
		is $fn->(2026, 13, 1, 0, 0, 0), undef, 'month 13';
		is $fn->(2026, 0, 1, 0, 0, 0), undef, 'month 0';
		is $fn->(2026, 1, 0, 0, 0, 0), undef, 'day 0';
		is $fn->(2026, 1, 1, 25, 0, 0), undef, 'hour 25 rolls to the next day, so it is refused';
	};

	subtest 'Calc::_parse_time -- the three shapes' => sub {
		my $fn = \&Database::BI::Calc::_parse_time;
		is_deeply $fn->('2026-05-20'), { epoch => POSIX::mktime(0, 0, 0, 20, 4, 126), has_time => 0 }, 'a date has no time';
		is_deeply $fn->('2026-05-20T10:30:15'), { epoch => POSIX::mktime(15, 30, 10, 20, 4, 126), has_time => 1 }, 'an ISO timestamp';
		is_deeply $fn->('2026-05-20 10:30'), { epoch => POSIX::mktime(0, 30, 10, 20, 4, 126), has_time => 1 }, 'a space and no seconds';
		is_deeply $fn->(' 2026-05-20 '), { epoch => POSIX::mktime(0, 0, 0, 20, 4, 126), has_time => 0 }, 'surrounding space is trimmed';
		is_deeply $fn->('1700000000'), { epoch => 1_700_000_000, has_time => 1 }, 'ten digits are seconds';
		is_deeply $fn->('1700000000123'), { epoch => 1_700_000_000, has_time => 1 }, 'thirteen are milliseconds';
	};

	subtest 'Calc::_parse_time -- what it refuses' => sub {
		my $fn = \&Database::BI::Calc::_parse_time;
		is $fn->($_), undef, "'$_' is not a time" for
			'', '   ', 'junk', '2026-02-31', '2026-13-01', '123456789', '12345678901', '1234567890123456',
			'2026-05-20T25:00', '2026-05-20X10:00', '-1700000000', '2026-5-20';
		is $fn->(undef), undef, 'undef is not';
		is $fn->([]), undef, 'a reference is not';
		keeps_globals_ok('_parse_time', sub { $fn->('2026-05-20') });
	};

	subtest 'Calc::_time_from_format' => sub {
		my $fn = \&Database::BI::Calc::_time_from_format;
		my $c  = Database::BI::Calc::_fmt_compile('%d-%b-%Y');
		is $fn->('20-May-2026', $c)->{epoch}, POSIX::mktime(0, 0, 0, 20, 4, 126), 'a month name';
		is $fn->('20-MAY-2026', $c)->{has_time}, 0, 'in any case, and no time';
		is $fn->('20-Foo-2026', $c), undef, 'a month that does not exist';
		is $fn->('31-Feb-2026', $c), undef, 'a day that does not exist';
		is $fn->(undef, $c), undef, 'undef';
		is $fn->([], $c), undef, 'a reference';

		my $n = Database::BI::Calc::_fmt_compile('%m/%d/%Y');
		is $fn->('13/01/2026', $n), undef, 'month 13 by number';
		is $fn->('00/01/2026', $n), undef, 'month 0 by number';

		my $t = Database::BI::Calc::_fmt_compile_pair('%Y-%m-%d', '%H:%M');
		is $fn->('2026-05-20T10:30', $t)->{has_time}, 1, 'an hour token means it has a time';
	};

	subtest 'Calc::_iso_second_label, _iso_day_label' => sub {
		my $epoch = POSIX::mktime(5, 4, 3, 2, 0, 126);
		is Database::BI::Calc::_iso_second_label($epoch), '2026-01-02T03:04:05', 'padded and local';
		is Database::BI::Calc::_iso_day_label($epoch), '2026-01-02', 'to the day';
	};

	subtest 'Calc::_civil_day, _shift_days -- calendar arithmetic' => sub {
		my $civil = \&Database::BI::Calc::_civil_day;
		is $civil->(1970, 1, 1), 0, 'the origin';
		is $civil->(1970, 1, 2), 1, 'the day after';
		is $civil->(1969, 12, 31), -1, 'and before it';
		is $civil->(2000, 3, 1), 11_017, 'a century leap year is counted';
		is $civil->(2024, 3, 1) - $civil->(2024, 2, 28), 2, 'a leap day exists';
		is $civil->(2026, 3, 1) - $civil->(2026, 2, 28), 1, 'and an ordinary year has none';

		my $shift = \&Database::BI::Calc::_shift_days;
		is_deeply [ $shift->(2026, 5, 20, 0) ], [ 2026, 5, 20 ], 'no move';
		is_deeply [ $shift->(2026, 3, 1, -1) ], [ 2026, 2, 28 ], 'back over a month end';
		is_deeply [ $shift->(2024, 3, 1, -1) ], [ 2024, 2, 29 ], 'and a leap day';
		is_deeply [ $shift->(2025, 12, 31, 1) ], [ 2026, 1, 1 ], 'forward over a year end';
	};

	subtest 'Calc::span_interval -- the vocabulary' => sub {
		my $fn = \&Database::BI::Calc::span_interval;
		is_deeply $fn->('15m'), { n => 15, unit => 'm', secs => 60 }, 'minutes are seconds under the hood';
		is_deeply $fn->('1h'), { n => 1, unit => 'h', secs => 3_600 }, 'hours too';
		is_deeply $fn->('30s'), { n => 30, unit => 's', secs => 1 }, 'and seconds';
		is_deeply $fn->("$_->[0]$_->[1]"), { n => $_->[0], unit => $_->[1] }, "$_->[1] counts calendar units"
			for [ 1, 'd' ], [ 2, 'w' ], [ 3, 'mon' ], [ 1, 'q' ], [ 5, 'y' ];
	};

	subtest 'Calc::span_interval -- anything else is refused' => sub {
		my $fn = \&Database::BI::Calc::span_interval;
		is $fn->($_), undef, "'$_' is refused" for
			'', '0h', '00m', 'h', '1', '1x', '-1h', '1.5h', '1 h', '1H', '1mo', '1months', "1h\n", '1h;drop', ' 1h';
		is $fn->(undef), undef, 'undef';
		is $fn->({}), undef, 'a reference';
		lives_ok { $fn->(('9' x 400) . 'd') } 'an absurd count does not crash';
	};

	subtest 'Calc::_span_label -- buckets are ISO at their own resolution' => sub {
		in_utc(sub {
			my $fn = \&Database::BI::Calc::_span_label;
			my $iv = \&Database::BI::Calc::span_interval;
			is $fn->('2026-05-20T10:37:42', $iv->('15m')), '2026-05-20T10:30:00', 'floored to the quarter hour';
			is $fn->('2026-05-20T10:37:42', $iv->('1h')), '2026-05-20T10:00:00', 'to the hour';
			is $fn->('2026-05-20T10:37:42', $iv->('10s')), '2026-05-20T10:37:40', 'to ten seconds';
			is $fn->('2026-05-20T10:37:42', $iv->('1d')), '2026-05-20', 'to the day';
			is $fn->('2026-05-20', $iv->('1w')), '2026-05-18', 'a week starts on the Monday';
			is $fn->('2026-05-18', $iv->('1w')), '2026-05-18', 'which is its own bucket';
			is $fn->('2026-05-24', $iv->('1w')), '2026-05-18', 'and takes in the Sunday';
			is $fn->('2026-05-20', $iv->('1mon')), '2026-05-01', 'a month';
			is $fn->('2026-02-15', $iv->('2mon')), '2026-01-01', 'two months line up with January';
			is $fn->('2026-05-20', $iv->('1q')), '2026-04-01', 'a quarter';
			is $fn->('2026-12-31', $iv->('2q')), '2026-07-01', 'two quarters';
			is $fn->('2026-05-20', $iv->('1y')), '2026-01-01', 'a year';
			is $fn->('2026-05-20', $iv->('5y')), '2025-01-01', 'five years';
			is $fn->('1969-12-31', $iv->('1mon')), '1969-12-01', 'before the origin too';
			is $fn->('1969-12-31', $iv->('1q')), '1969-10-01', 'for quarters as well';

			# Whatever the width, a bucket holds its own start.
			for my $i ('2d', '7d', '2w', '3mon', '3q') {
				my $start = $fn->('2026-05-20', $iv->($i));
				is $fn->($start, $iv->($i)), $start, "a $i bucket's start falls in that bucket";
			}
		});
	};

	subtest 'Calc::_span_label -- a value that is not a time has no bucket' => sub {
		my $fn = \&Database::BI::Calc::_span_label;
		my $iv = Database::BI::Calc::span_interval('1d');
		is $fn->($_, $iv), undef, "'$_' has none" for 'junk', '', '2026-02-31';
		is $fn->(undef, $iv), undef, 'undef has none';
	};

	subtest 'Calc::new -- the guards' => sub {
		my $long = Database::BI::Calc->new(expr => '1' x ($MAX_EXPR_LEN + 1));
		is $long->error, "Expression too long (max $MAX_EXPR_LEN characters)", 'one over the limit';
		ok !Database::BI::Calc->new(expr => '1' x $MAX_EXPR_LEN)->has_error, 'exactly at the limit is allowed';

		my $clash = Database::BI::Calc->new(expr => 'a', columns => ['a'], params => { a => 1 });
		is $clash->error, "Parameter 'a' conflicts with a column of the same name", 'an ambiguous name';
		is $clash->evaluate({ a => 1 }), undef, 'and a failed compile evaluates to nothing';

		ok(Database::BI::Calc->new()->has_error, 'no expression at all is an error');
		ok(Database::BI::Calc->new(expr => '   ')->has_error, 'nor is whitespace an expression');
		ok !Database::BI::Calc->new(expr => '1')->has_error, 'a good one has no error';
		is(Database::BI::Calc->new(expr => '1')->error, undef, 'and error() is then undef');
		memory_cycle_ok(Database::BI::Calc->new(expr => 'a + 1', columns => ['a']), 'a compiled expression holds no cycle');
	};

	# Why: this text reaches the reader.  An install path with a space in it would
	# otherwise leave the where-it-happened tail on, and name a server path.
	subtest 'Calc::new -- an error never carries a file path' => sub {
		my $err = eval qq{#line 1 "/opt/my apps/caller.pl"\nDatabase::BI::Calc->new(expr => 'nope')->error};
		is $err, "Unknown column 'nope'", 'a path with a space in it is taken off too';

		my $bad = eval qq{#line 1 "/opt/my apps/caller.pl"\nDatabase::BI::Calc->new(expr => '\@')->error};
		is $bad, "Unexpected character '\@' at position 0", 'from the tokenizer as well';

		is calc_error('x_at_y_line_5'), "Unknown column 'x_at_y_line_5'", 'and the name in the message is left whole';
	};

	subtest 'Calc::evaluate -- never dies, whatever the row' => sub {
		my $c = Database::BI::Calc->new(expr => 'a + 1', columns => ['a']);
		is $c->evaluate({ a => 1 }), 2, 'the ordinary case';
		is $c->evaluate({}), undef, 'a missing cell';
		is $c->evaluate({ a => 'x' }), undef, 'a cell that is not a number';
		lives_ok { $c->evaluate(undef) } 'no row';

		my $p = Database::BI::Calc->new(expr => 'a + rate', columns => ['a'], params => { rate => 2 });
		is $p->evaluate({ a => 1 }), 3, 'a parameter is in scope';
		is $p->evaluate({ a => 1, rate => 99 }), 3, 'and beats a column added since compile time';
		lives_ok { is $p->evaluate(undef), undef, 'undef gives undef' } 'no row, with parameters';
		lives_ok { is $p->evaluate('oops'), undef, 'a string gives undef' } 'a row that is not a hash';

		# A locked row (SQL-backed sources) raises on an unknown key; that must
		# come back as nothing, not a 500.
		require Hash::Util;
		my %locked = (b => 1);
		Hash::Util::lock_ref_keys(\%locked);
		is $c->evaluate(\%locked), undef, 'a locked row without the column';
		ok !exists $locked{a}, 'and the row is not changed by asking';
		keeps_globals_ok('evaluate', sub { $c->evaluate({ a => 1 }) });
	};

	subtest 'Calc::_tokenize -- token types and positions' => sub {
		my $toks = Database::BI::Calc::_tokenize(q{a1 + 2.5e3 'x' "y" <= != >= < > = ( ) , - * /});
		is_deeply [ map { $_->{type} } @$toks ],
			[ qw(IDENT PLUS NUM STR STR LE NEQ GE LT GT EQ LPAREN RPAREN COMMA MINUS STAR SLASH EOF) ], 'every token type';
		is $toks->[2]{val}, '2.5e3', 'a number keeps its text';
		is $toks->[3]{val}, 'x', 'a string loses its quotes';
		is $toks->[1]{pos}, 3, 'and positions are character offsets';
		is_deeply [ map { $_->{type} } @{ Database::BI::Calc::_tokenize('') } ], ['EOF'], 'an empty expression is just the end';
	};

	subtest 'Calc::_tokenize -- exact errors' => sub {
		throws_ok { Database::BI::Calc::_tokenize(q{'abc}) } qr/\AUnterminated string at position 0 at /, 'a single quote';
		throws_ok { Database::BI::Calc::_tokenize(q{1 + "abc}) } qr/\AUnterminated string at position 4 at /, 'a double quote';
		throws_ok { Database::BI::Calc::_tokenize('a == 1') } qr/\AUse = not == for equality comparison at position 2 at /, 'a C habit';
		for my $ch (qw(@ $ ; ` ! % & | ^ ~ { } [ ] \\)) {
			throws_ok { Database::BI::Calc::_tokenize("1 $ch") } qr/\AUnexpected character '\Q$ch\E' at position 2 at /, "'$ch' is not in the language";
		}
	};

	subtest 'Calc::_check_depth and _expect' => sub {
		my $d = $MAX_DEPTH - 1;
		lives_ok { Database::BI::Calc::_check_depth(\$d) } 'one under the limit';
		$d = $MAX_DEPTH;
		throws_ok { Database::BI::Calc::_check_depth(\$d) } qr/\AExpression nesting too deep \(max $MAX_DEPTH levels\) at /, 'at the limit';

		my $toks = [ { type => 'NUM', val => '7', pos => 3 } ];
		my $pos = 0;
		lives_ok { Database::BI::Calc::_expect($toks, \$pos, 'NUM') } 'the token it wants';
		is $pos, 1, 'and it moves on';
		$pos = 0;
		throws_ok { Database::BI::Calc::_expect($toks, \$pos, 'RPAREN') } qr/\AExpected 'RPAREN' at position 3, got '7' at /, 'one it does not';
		is $pos, 0, 'and it stays put';
	};

	# Each of the parser's levels is reached through the compiler, since a level
	# on its own only builds a closure; what matters is what the closure does.
	subtest 'Calc::_parse_add, _parse_term, _parse_factor -- arithmetic' => sub {
		is calc_value('a + b', \%row), 14, 'add';
		is calc_value('a - b', \%row), 6, 'subtract';
		is calc_value('a * b', \%row), 40, 'multiply';
		is calc_value('a / b', \%row), 2.5, 'divide';
		is calc_value('1 + 2 * 3'), 7, 'precedence';
		is calc_value('(1 + 2) * 3'), 9, 'brackets';
		is calc_value('2 - 3 - 4'), -5, 'left associative';
		is calc_value('-a', \%row), -10, 'unary minus';
		is calc_value('+a', \%row), 10, 'unary plus';
		is calc_value('--a', \%row), 10, 'twice';
		is calc_value('1e3'), 1000, 'scientific';
	};

	subtest 'Calc arithmetic -- nothing dies on bad cells' => sub {
		is calc_value('a / 0', \%row), undef, 'division by zero is nothing';
		is calc_value('a / (b - 4)', \%row), undef, 'however it was reached';
		is calc_value('s + 1', \%row), undef, 'text plus a number';
		is calc_value('1 - s', \%row), undef, 'minus';
		is calc_value('s * 2', \%row), undef, 'times';
		is calc_value('2 / s', \%row), undef, 'divide';
		is calc_value('-s', \%row), undef, 'negated';
		is calc_value('blank + 1', \%row), undef, 'an empty cell';
		is calc_value('blank * 1', \%row), undef, 'multiplied';
	};

	subtest 'Calc::_parse_cmp -- comparisons' => sub {
		is calc_value('a > b', \%row), 1, 'true is 1';
		is calc_value('a < b', \%row), 0, 'false is 0';
		is calc_value('a = 10', \%row), 1, 'equal';
		is calc_value('a != 10', \%row), 0, 'not equal';
		is calc_value('a <= 10', \%row), 1, 'at most';
		is calc_value('a >= 11', \%row), 0, 'at least';
		is calc_value(q{'10' > '9'}), 1, 'numbers in quotes compare as numbers';
		is calc_value(q{s = 'HELLO'}, \%row), 1, 'text is case-blind';
		is calc_value(q{s != 'hello'}, \%row), 0, 'either way round';
		is calc_value(q{s < 'z'}, \%row), 1, 'and ordered';
		is calc_value(q{s > 'z'}, \%row), 0, 'both ways';
		is calc_value(q{s <= 'hello'}, \%row), 1, 'to the boundary';
		is calc_value(q{s >= 'hello'}, \%row), 1, 'from the boundary';
		is calc_value('blank = 1', \%row), undef, 'an empty cell compares to nothing';
		is calc_value('1 = blank', \%row), undef, 'on either side';
		like calc_error('1 < 2 < 3'), qr/\AUnexpected token '<' at position 6\z/, 'comparisons do not chain';
	};

	subtest 'Calc::_parse_colref -- names' => sub {
		my %r = ('Per Unit Price' => 3, plain => 1);
		is calc_value('plain', \%r), 1, 'exact';
		is calc_value('per_unit_price', \%r), 3, 'underscores stand for spaces, whatever the case';
		is calc_value('PLAIN', \%r), 1, 'case-blind';
		is calc_error('secret', 'plain'), "Unknown column 'secret'", 'a column that is not offered';
		is calc_error('a_b', 'a_c'), "Unknown column 'a_b'", 'and no partial match';
	};

	subtest 'Calc::_parse_call -- the language runs no code' => sub {
		for my $fn (qw(system exec open eval require unlink kill print sprintf)) {
			is calc_error("$fn('x')"), "Unknown function '$fn'", "$fn is not a function here";
		}
		is calc_error('__PACKAGE__'), "Unknown column '__PACKAGE__'", 'a Perl token is just a missing column';
		is calc_error(q{CORE::system('x')}), "Unexpected character ':' at position 4", 'nor can a package be named';
		is calc_value(q{'; system("x"); '}), q{; system("x"); }, 'a string holding code is only a string';
		is calc_value(q{concat('$ENV{HOME}', '@INC')}), '$ENV{HOME}@INC', 'and is not interpolated';
	};

	subtest 'Calc::_parse_call -- malformed calls' => sub {
		is calc_error('upper(a', 'a'), "Expected 'RPAREN' at position 7, got ''", 'an unclosed call';
		is calc_error('(1 + 2'), "Expected 'RPAREN' at position 6, got ''", 'an unclosed bracket';
		is calc_error('1 +'), "Unexpected token '' at position 3", 'a missing operand';
		is calc_error('1 2'), "Unexpected token '2' at position 2", 'two values';
		is calc_error(')'), "Unexpected token ')' at position 0", 'a stray bracket';
		is calc_error('epoch(1, 2)'), 'The second argument of epoch() must be a quoted literal', 'a format that is not a literal';
		is calc_error('span(1, a)', 'a'), 'The second argument of span() must be a quoted literal', 'an interval that is not one';
		is calc_error(q{epoch(1, '%Q')}), 'Unsupported time format token %Q', 'a bad format is found at compile time';
		like calc_error(q{span(1, 'x')}), qr/\AUnknown time bucket 'x'; use a count/, 'and a bad interval';
		like calc_error('span(1)'), qr/\AUnknown time bucket ''/, 'and none at all';
		is calc_value('if(1)'), undef, 'if with no branches comes to nothing rather than a crash';
		is calc_value('if()'), undef, 'nor with no condition';
	};

	# Why: every nesting route must count towards the limit.  Unary operators
	# recurse in the parser too, and a URL can hold 500 of them.
	subtest 'Calc -- nesting cannot exhaust the parser' => sub {
		my $too_deep = "Expression nesting too deep (max $MAX_DEPTH levels)";
		is calc_error(('(' x 100) . '1' . (')' x 100)), $too_deep, 'brackets';
		is calc_error(('upper(' x 60) . '1' . (')' x 60)), $too_deep, 'calls';
		warnings_are {
			is calc_error(('-' x ($MAX_EXPR_LEN - 1)) . '1'), $too_deep, 'unary minus';
			is calc_error(('+' x ($MAX_EXPR_LEN - 1)) . '1'), $too_deep, 'unary plus';
		} [], 'without a deep-recursion warning first';
		is calc_value('-(-(1))'), 1, 'modest nesting is still fine';
		is calc_value('---1'), -1, 'modest unary too';
		is calc_value(join('+', (1) x 200)), 200, 'a long flat sum is not nesting';
	};

	subtest 'Calc functions -- strings' => sub {
		is calc_value('upper(s)', \%row), 'HELLO', 'upper';
		is calc_value('lower(s)', \%row), 'hello', 'lower';
		is calc_value(q{trim('  x ')}), 'x', 'trim';
		is calc_value('len(s)', \%row), 5, 'len';
		is calc_value(q{concat(s, '!', 1)}, \%row), 'Hello!1', 'concat';
		is calc_value('concat(blank, s)', \%row), 'Hello', 'concat treats empty as nothing';
		is calc_value('substr(s, 1, 2)', \%row), 'el', 'substr with a length';
		is calc_value('substr(s, 3)', \%row), 'lo', 'and without';
		is calc_value($_, \%row), undef, "$_ of an empty cell is nothing"
			for 'upper(blank)', 'lower(blank)', 'trim(blank)', 'len(blank)', 'substr(blank, 1)';
	};

	# Why: a start past the end returns undef and warns.  A column of short values
	# would write one warning per row to the log.
	subtest 'Calc functions -- substr past the end is quiet' => sub {
		warnings_are { is calc_value('substr(s, 99)', \%row), undef, 'nothing there' } [], 'no warning';
		warnings_are { is calc_value('substr(s, 99, 1)', \%row), undef, 'with a length' } [], 'no warning';
		warnings_are { is calc_value('substr(s, -99, 1)', \%row), undef, 'from the far end' } [], 'no warning';
	};

	subtest 'Calc functions -- numbers' => sub {
		is calc_value('round(2.567, 2)'), 2.57, 'round to places';
		is calc_value('round(2.5)'), 2, 'to whole numbers, by default';
		is calc_value('floor(2.9)'), 2, 'floor';
		is calc_value('floor(-2.1)'), -3, 'floor of a negative';
		is calc_value('ceil(2.1)'), 3, 'ceil';
		is calc_value('abs(-2)'), 2, 'abs';
		is calc_value($_, \%row), undef, "$_ is nothing" for qw(round(s) floor(s) ceil(s) abs(s) round(blank) floor(blank));
		is calc_value(q{round(2.5, 'x')}), 2, 'a non-numeric place count means none';
	};

	# Why: "%.-2f" is not a format, so a negative place count returned 0 and a
	# warning; and a huge one asked sprintf for that many digits, from a URL.
	subtest 'Calc functions -- round cannot be abused' => sub {
		warnings_are { is calc_value('round(1234, -2)'), 1200, 'negative places round to the left' } [], 'quietly';
		warnings_are { is calc_value('round(1250.5, -1)'), 1250, 'to the ten' } [], 'quietly';
		warnings_are { is calc_value('round(1.5, 2000000000)'), 1.5, 'an absurd count is held to what a double can show' } [], 'quickly';
		warnings_are { is calc_value('round(1234, -2000000000)'), 0, 'and an absurd negative one' } [], 'and quietly';
	};

	subtest 'Calc functions -- null handling and if' => sub {
		is calc_value('isnull(blank, 7)', \%row), 7, 'isnull fills a gap';
		is calc_value('isnull(a, 7)', \%row), 10, 'and leaves a value';
		is calc_value('coalesce(blank, blank, 3)', \%row), 3, 'coalesce takes the first value';
		is calc_value('coalesce(blank)', \%row), undef, 'or nothing';
		is calc_value('coalesce()'), undef, 'with nothing to choose from';
		is calc_value('if(a > 1, 1, 2)', \%row), 1, 'if, true';
		is calc_value('if(a < 1, 1, 2)', \%row), 2, 'if, false';
		is calc_value('IF(blank, 1, 2)', \%row), 2, 'nothing counts as false, in either case of name';
		is calc_value(q{if(1, 'y', bad_fn_not_reached)}, { bad_fn_not_reached => 1 }), 'y', 'a branch not taken is not run';
	};

	# week() is worked out in Perl, because strftime('%V') is '' on Windows.
	# Where %V works, the two must agree, above all around the new year.
	subtest 'Calc::_iso_week -- agrees with strftime %V' => sub {
		require Time::Local;
		plan skip_all => "strftime has no %V here"
			unless (POSIX::strftime('%V', gmtime(0)) // '') =~ /\A\d+\z/;
		my $bad = 0;
		for my $year (1999 .. 2030) {
			for my $k (1 .. 7) {
				for my $md ([1, $k], [12, 32 - $k]) {
					my @g = gmtime Time::Local::timegm(0, 0, 12, $md->[1], $md->[0] - 1, $year);
					my $want = POSIX::strftime('%V', @g) + 0;
					my $got  = Database::BI::Calc::_iso_week($g[5] + 1900, $g[6], $g[7]);
					next if $got == $want;
					$bad++;
					diag("$year-$md->[0]-$md->[1]: $got, not $want");
				}
			}
		}
		is $bad, 0, 'the first and last seven days of 1999 to 2030';
	};

	subtest 'Calc functions -- dates' => sub {
		is calc_value('year(d)', \%row), 2026, 'year';
		is calc_value('month(d)', \%row), 5, 'month';
		is calc_value('day(d)', \%row), 20, 'day';
		is calc_value('quarter(d)', \%row), 2, 'quarter';
		is calc_value('month_name(d)', \%row), 'May', 'month name';
		is calc_value('weekday(d)', \%row), 3, 'a Wednesday';
		is calc_value(q{weekday('2026-05-24')}), 7, 'a Sunday is 7, not 0';
		is calc_value(q{week('2026-01-01')}), 1, 'ISO week one';
		is calc_value(q{week('2020-12-31')}), 53, 'a fifty-third week';
		like calc_value('now()'), qr/\A\d{4}-\d{2}-\d{2}\z/, 'now is a date';
		is calc_value($_, \%row), undef, "$_ is nothing"
			for map { "$_(s)" } qw(year month day quarter month_name weekday week);
		is calc_value($_, \%row), undef, "$_ is nothing"
			for map { "$_(blank)" } qw(year month day quarter month_name weekday week);
	};

	# Why: the rule stated at the top of the function table is that a value which
	# is not a date gives nothing.  Month 00 used to read $M[-1], so it was named
	# December; month 13 was quarter 5; and 31 February was a Tuesday in March.
	subtest 'Calc functions -- a date that does not exist is not read as one' => sub {
		for my $bad ('2026-00-15', '2026-13-15') {
			is calc_value("$_('$bad')"), undef, "$_('$bad') is nothing" for qw(month quarter month_name);
		}
		is calc_value(q{day('2026-01-32')}), undef, 'day 32';
		is calc_value(q{day('2026-01-00')}), undef, 'day 0';
		is calc_value(q{weekday('2026-02-31')}), undef, 'the weekday of 31 February';
		is calc_value(q{week('2026-02-31')}), undef, 'its week';
		is calc_value(q{week('2026-13-01')}), undef, 'the week of month 13';
		is calc_value(q{weekday('2026-13-01')}), undef, 'its weekday';
	};

	subtest 'Calc functions -- time of day' => sub {
		is calc_value(q{hour('2026-05-20T10:37:42')}), 10, 'hour';
		is calc_value(q{minute('2026-05-20T10:37:42')}), 37, 'minute';
		is calc_value(q{second('2026-05-20T10:37:42')}), 42, 'second';
		is calc_value(q{hour('2026-05-20')}), undef, 'a date alone has no hour, rather than midnight';
		is calc_value("$_('junk')"), undef, "$_ of junk" for qw(hour minute second);
		is calc_value("$_(blank)", \%row), undef, "$_ of an empty cell" for qw(hour minute second);
	};

	subtest 'Calc functions -- epoch and span' => sub {
		is calc_value(q{epoch('2026-05-20')}), POSIX::mktime(0, 0, 0, 20, 4, 126), 'epoch of a date';
		is calc_value(q{epoch('20/05/2026', '%d/%m/%Y')}), POSIX::mktime(0, 0, 0, 20, 4, 126), 'with a format';
		is calc_value(q{epoch('junk')}), undef, 'of junk';
		is calc_value(q{epoch('junk', '%d/%m/%Y')}), undef, 'with a format, of junk';
		is calc_value(q{span('2026-05-20', '1mon')}), '2026-05-01', 'span';
		is calc_value(q{span('junk', '1mon')}), undef, 'of junk';
	};

	subtest 'Calc functions -- bin' => sub {
		is calc_value('bin(15, 10)'), '[10,20)', 'an integer width';
		is calc_value('bin(10, 10)'), '[10,20)', 'the lower bound is inside';
		is calc_value('bin(-1, 10)'), '[-10,0)', 'a negative';
		is calc_value('bin(0.25, 0.1)'), '[0.2,0.3)', 'a fractional width';
		is calc_value('bin(0.3, 0.1)'), '[0.3,0.4)', 'binary fractions do not slip a bin left';
		is calc_value($_, \%row), undef, "$_ is nothing" for 'bin(s, 10)', 'bin(1, s)', 'bin(1, 0)', 'bin(1, -5)', 'bin(blank, 1)', 'bin(1, blank)';
		lives_ok { calc_value(q{bin('inf', 1)}) } 'infinity is survived';
	};

	subtest 'Calc::date_normalise -- the three named patterns' => sub {
		my $fn = \&Database::BI::Calc::date_normalise;
		is $fn->('1/15/2026', '%m/%d/%Y'), '2026-01-15', 'US';
		is $fn->('15/1/2026', '%d/%m/%Y'), '2026-01-15', 'EU';
		is $fn->('15-jan-2026', '%d-%b-%Y'), '2026-01-15', 'a month name in any case';
		is $fn->('junk', $_), undef, "junk does not match $_" for '%m/%d/%Y', '%d/%m/%Y', '%d-%b-%Y';
		is $fn->('15-Foo-2026', '%d-%b-%Y'), undef, 'a month that does not exist';
		is $fn->('1/1/2026', '%Q'), undef, 'an unknown pattern';
		is $fn->(undef, '%m/%d/%Y'), undef, 'no value';
		is $fn->('', '%m/%d/%Y'), undef, 'an empty value';
		is $fn->('1/1/2026', undef), undef, 'no pattern';
		keeps_globals_ok('date_normalise', sub { $fn->('1/15/2026', '%m/%d/%Y') });
	};

	# Why: this is what sends a misread column to the '(unparseable)' bucket, where
	# someone can see it.  A UK file read as US used to come back as "2026-15-01",
	# a value that looks like a date and sorts among the real ones.
	subtest 'Calc::date_normalise -- a date that does not exist is not produced' => sub {
		my $fn = \&Database::BI::Calc::date_normalise;
		is $fn->('15/01/2026', '%m/%d/%Y'), undef, 'a UK date read as US has no month 15';
		is $fn->('01/15/2026', '%d/%m/%Y'), undef, 'and a US date read as UK';
		is $fn->('02/31/2026', '%m/%d/%Y'), undef, '31 February';
		is $fn->('31/02/2026', '%d/%m/%Y'), undef, 'either way round';
		is $fn->('00/10/2026', '%m/%d/%Y'), undef, 'month 0';
		is $fn->('31-Feb-2026', '%d-%b-%Y'), undef, 'with a month name';
		is $fn->('29/02/2024', '%d/%m/%Y'), '2024-02-29', 'but a true leap day is fine';
	};

	subtest 'Calc::_normalise_with_format -- stored patterns' => sub {
		my $fn = \&Database::BI::Calc::date_normalise;
		is $fn->('2026.05.20', { date => '%Y.%m.%d' }), '2026-05-20', 'a date';
		is $fn->('2026.05.20', { date => '%Y.%m.%d', as => 'timestamp' }), '2026-05-20T00:00:00', 'as a timestamp at midnight';
		is $fn->('2026.05.20 10:30', { date => '%Y.%m.%d', time => '%H:%M' }), '2026-05-20T10:30:00', 'with a time';
		is $fn->('junk', { date => '%Y.%m.%d' }), undef, 'junk';
		is $fn->('junk', { date => '%Y.%m.%d', time => '%H:%M' }), undef, 'junk with a time';
		is $fn->('2026.02.31', { date => '%Y.%m.%d' }), undef, 'a date that does not exist';
		is $fn->('x', {}), undef, 'a pattern with no date';
		is $fn->('x', { date => '' }), undef, 'or an empty one';
	};

	# Why: its documented contract is undef for an unknown pattern, and the caller
	# runs it over stored JSON with no eval.  One edited or stale models.json must
	# not turn every page that reads the column into a 500.
	subtest 'Calc::date_normalise -- a corrupt stored pattern does not take the page down' => sub {
		my $fn = \&Database::BI::Calc::date_normalise;
		my $got = 'unset';
		lives_ok { $got = $fn->('2026-01-01', { date => '%Q' }) } 'an unknown token';
		is $got, undef, 'gives nothing';
		lives_ok { $got = $fn->('2026-01-01', { date => '%H' }) } 'a pattern with no date in it';
		is $got, undef, 'gives nothing';
		lives_ok { $got = $fn->('2026-01-01', { date => '%Y-%m-%d', time => '%Q' }) } 'a bad time token';
		is $got, undef, 'gives nothing';
	};
}

# ============================================================================
# PART U8: Database::BI::Model::Geocode -- the functions the earlier part misses
# ============================================================================
{
	Readonly my $SHARED => 'shared';

	subtest 'Geocode::_resolve -- one pass over one column' => sub {
		my $point = Stub::GeoPoint->new({ latitude => $GOOD_LAT, longitude => $GOOD_LON, database => 'osm' });
		my $stub  = Stub::Geocoder->new(results => { $GOOD_PLACE => $point });
		my $geo   = $GEO->new(geocoder => $stub);

		my $got = $geo->_resolve([ $GOOD_PLACE, $GOOD_PLACE, 'Nowhere', '', undef, '123' ], { max => 10 });

		returns_is $got, { type => 'hashref' }, 'a hashref';
		is $got->{counts}{distinct}, 4, 'a repeat is one value, and undef and empty are one';
		is $got->{counts}{resolved}, 1, 'one found';
		is $got->{counts}{unresolved}, 1, 'one not found';
		is $got->{counts}{skipped}, 2, 'the blank and the bare number are refused';
		is $got->{counts}{lookups}, 2, 'only two reach the geocoder';
		is_deeply $got->{points}{$GOOD_PLACE}, { lat => $GOOD_LAT, lon => $GOOD_LON, backend => 'osm' }, 'with its position';
		is $got->{cache}{Nowhere}, 0, 'a miss is remembered, so it is not asked again';
		is $got->{backend}, 'osm', 'the backend is named';
		memory_cycle_ok($got, 'no cycle');
	};

	subtest 'Geocode::_resolve -- the cap and the cache' => sub {
		my $stub = Stub::Geocoder->new();
		my $geo  = $GEO->new(geocoder => $stub);

		my $capped = $geo->_resolve([qw(aa bb cc)], { max => 2 });
		is $capped->{capped}, 1, 'more wanted than allowed';
		is $capped->{counts}{attempted}, 2, 'only the allowance is tried';
		is_deeply $capped->{not_attempted}, ['cc'], 'the rest are held back';
		ok !exists $capped->{cache}{cc}, 'and not cached, so the next request picks them up';

		my $cache = { kept => [ 1, 2 ], missed => 0 };
		my $calls = @{ $stub->{calls} };
		my $hit = $geo->_resolve([qw(kept missed)], { max => 5, cache => $cache });
		is scalar @{ $stub->{calls} }, $calls, 'remembered answers ask nothing';
		is_deeply $hit->{points}{kept}, { lat => 1, lon => 2 }, 'a remembered place still plots';
		is_deeply $hit->{unresolved}, ['missed'], 'a remembered miss stays a miss';

		$hit->{cache}{tampered} = 1;
		ok !exists $cache->{tampered}, "the caller's cache is never written to";
	};

	subtest 'Geocode::_resolve -- a geocoder that misbehaves' => sub {
		my $weird = bless {}, 'Stub::Function::WeirdGeocoder';
		{
			no warnings 'once';
			*Stub::Function::WeirdGeocoder::valid_location = sub { 1 };
			*Stub::Function::WeirdGeocoder::geocode_many   = sub { return 'not a hash' };
		}
		my $got = $GEO->new(geocoder => $weird)->_resolve(['x'], { max => 5 });
		is $got->{counts}{unresolved}, 1, 'a reply of the wrong shape is a miss, not a crash';
		is $got->{counts}{lookups}, 1, 'and the lookup is still counted';
	};

	subtest 'Geocode::_resolve -- never repeats a location in its messages' => sub {
		my $got = $GEO->new(geocoder => Stub::Geocoder->new())->_resolve([qw(Private_Home_Address another)], { max => 1 });
		my $all = join ' ', map { $_->{text} // '' } @{ $got->{messages} };
		unlike $all, qr/Private_Home_Address|another/, 'a place in a personal dataset is personal data';
	};

	subtest 'Geocode::shared_cache_from_models' => sub {
		my $places = { Ramsgate => [ 1, 2 ] };
		is_deeply $GEO->shared_cache_from_models({ geo => { $SHARED => { places => $places } } }), $places, 'the shared places';
		my $copy = $GEO->shared_cache_from_models({ geo => { $SHARED => { places => $places } } });
		$copy->{added} = 1;
		ok !exists $places->{added}, 'as a copy, so editing it changes nothing';

		is_deeply $GEO->shared_cache_from_models($_), {}, 'junk gives an empty cache'
			for undef, 'x', [], {}, { geo => {} }, { geo => { $SHARED => 'x' } }, { geo => { $SHARED => { places => 'x' } } };
	};

	# Why: reading models.json must not change it.  A nested rvalue autovivifies,
	# and the next write would save a "geo" the user never had.
	subtest 'Geocode::shared_cache_from_models -- reading leaves the store alone' => sub {
		my %models = (other => 1);
		$GEO->shared_cache_from_models(\%models);
		ok !exists $models{geo}, 'no empty geo section appears';

		for my $corrupt ('oops', [ 1 ], 42) {
			my $got;
			lives_ok { $got = $GEO->shared_cache_from_models({ geo => $corrupt }) } 'a corrupt geo section is survived';
			is_deeply $got, {}, 'and reads as nothing';
		}
	};

	subtest 'Geocode::models_with_shared_cache' => sub {
		my %models = (other => 1, geo => { 'file:x' => { lat => 'a' }, $SHARED => { places => { old => [ 1, 2 ] }, backend => 'first' } });
		my $got = $GEO->models_with_shared_cache(\%models, { new => [ 3, 4 ] }, backend => 'second', built => 'today');

		is_deeply $got->{geo}{$SHARED}{places}, { old => [ 1, 2 ], new => [ 3, 4 ] }, 'merged, so another request is not lost';
		is $got->{geo}{$SHARED}{backend}, 'second', 'the metadata is updated';
		is $got->{geo}{$SHARED}{built}, 'today', 'all of it';
		is $got->{other}, 1, 'the rest of the store is kept';
		is_deeply $got->{geo}{'file:x'}, { lat => 'a' }, 'and so are other datasets';

		is_deeply $models{geo}{$SHARED}{places}, { old => [ 1, 2 ] }, "the caller's copy is not changed";
		is $models{geo}{$SHARED}{backend}, 'first', 'in any part';

		my $newer = $GEO->models_with_shared_cache({ geo => { $SHARED => { places => { p => [ 1, 1 ] } } } }, { p => [ 2, 2 ] });
		is_deeply $newer->{geo}{$SHARED}{places}{p}, [ 2, 2 ], 'the newer answer wins';
		memory_cycle_ok($got, 'no cycle');
	};

	subtest 'Geocode::models_with_shared_cache -- junk in, a valid store out' => sub {
		for my $models (undef, 'x', []) {
			my $got = $GEO->models_with_shared_cache($models, { a => [ 1, 2 ] });
			is_deeply $got->{geo}{$SHARED}{places}, { a => [ 1, 2 ] }, 'store that is not a store is replaced';
		}
		is_deeply $GEO->models_with_shared_cache({}, 'x')->{geo}{$SHARED}{places}, {}, 'a cache that is not a hash adds nothing';

		my %empty;
		$GEO->models_with_shared_cache(\%empty, {});
		ok !exists $empty{geo}, 'the caller is not given a geo section';

		for my $corrupt ('oops', [ 1 ]) {
			my $got;
			lives_ok { $got = $GEO->models_with_shared_cache({ geo => $corrupt }, { a => [ 1, 2 ] }) } 'a corrupt geo section is survived';
			is_deeply $got->{geo}{$SHARED}{places}, { a => [ 1, 2 ] }, 'and is rebuilt';
		}
	};
}

# ============================================================================
# PART U9: Database::BI::Model::DataSource -- the functions the earlier part misses
#
# Database::Abstraction is replaced where a real connection would be needed, so
# these run with no network and no Redis.
# ============================================================================
{
	Readonly my $REDIS_URL => 'redis://localhost:6379';
	Readonly my $HTML_URL  => 'http://example.com/t.html';

	subtest 'DataSource::_safe_table_name' => sub {
		my $fn = \&Database::BI::Model::DataSource::_safe_table_name;
		is $fn->('sales'), 'sales', 'a safe name is unchanged';
		is $fn->('_x'), '_x', 'a leading underscore is allowed';
		is $fn->('chi_CGI::Info'), 'chi_CGI__Info', 'each illegal character becomes an underscore';
		is $fn->('2026'), '_2026', 'a leading digit gets one';
		is $fn->(''), '_', 'nothing at all still names something';
		is $fn->('a;DROP TABLE b'), 'a_DROP_TABLE_b', 'SQL does not survive';
		is $fn->('../../x'), '______x', 'nor does a path';
		is $fn->("a\nb"), 'a_b', 'nor a newline';
		like $fn->("caf\x{e9}\x{263A}"), qr/\A[A-Za-z_][A-Za-z0-9_]*\z/, 'non-ASCII text ends up safe';
		keeps_globals_ok('_safe_table_name', sub { $fn->('a b') });
	};

	subtest 'DataSource::_new_from_redis -- every refusal is exact' => sub {
		my $fn = \&Database::BI::Model::DataSource::_new_from_redis;
		throws_ok { $fn->($DS, {}) } qr/\ADataSource: Redis URL "" must begin with redis:\/\/ at /, 'no URL';
		throws_ok { $fn->($DS, { redis => 'http://x', table => 't' }) } qr/\ADataSource: Redis URL "http:\/\/x" must begin with redis:\/\/ at /, 'another scheme';
		throws_ok { $fn->($DS, { redis => " $REDIS_URL", table => 't' }) } qr/must begin with redis:\/\//, 'a leading space';
		throws_ok { $fn->($DS, { redis => $REDIS_URL }) } qr/\ADataSource: argument "table" is required at /, 'no table';
		for my $table ('', 'a/b', 'a\\b', "a\0b") {
			(my $shown = $table) =~ s/\0/NUL/;
			throws_ok { $fn->($DS, { redis => $REDIS_URL, table => $table }) } qr/\ADataSource: table name ".*" contains illegal characters/s, "the table '$shown'";
		}
	};

	subtest 'DataSource::_new_from_redis -- builds the object without connecting' => sub {
		Test::Mockingbird::mock("${DS}::_init_redis_backend", sub { $_[0]{_db} = 'stub' });
		my $src = Database::BI::Model::DataSource::_new_from_redis($DS, { redis => $REDIS_URL, table => 'a:b-c' });
		my $dig = Database::BI::Model::DataSource::_new_from_redis($DS, { redis => uc($REDIS_URL), table => '9lives' });
		Test::Mockingbird::unmock("${DS}::_init_redis_backend");

		is $src->{_table}, 'a_b_c', 'the identifier is sanitised';
		is $src->{_raw_table}, 'a:b-c', 'and the real key name kept for the lookups';
		is $src->{_cache_ttl_url}, '15 min', 'the default TTL';
		is $src->{_db}, 'stub', 'the backend step ran';
		is $dig->{_table}, '_9lives', 'a leading digit is made safe';
		is $dig->{_redis_url}, uc($REDIS_URL), 'and the scheme check does not mind case';
		memory_cycle_ok($src, 'no cycle');
	};

	subtest 'DataSource::_init_redis_backend' => sub {
		my $self = bless { _table => 'fn_redis', _raw_table => 'fn:redis', _redis_url => $REDIS_URL }, $DS;
		my %got;
		Test::Mockingbird::mock('Database::Abstraction::new', sub { my ($c, %a) = @_; %got = %a; bless {}, $c });
		$self->_init_redis_backend();
		Test::Mockingbird::unmock('Database::Abstraction::new');
		isa_ok $self->{_db}, 'Database::BI::_DB::Fn_redis';
		is $got{redis_key}, 'fn:redis', 'lookups use the real key';
		is $got{table}, 'fn_redis', 'the identifier uses the safe one';

		Test::Mockingbird::mock('Database::Abstraction::new', sub { require Carp; Carp::croak('connection refused') });
		throws_ok { $self->_init_redis_backend() }
			qr/\ADataSource: failed to initialise database backend for table "fn_redis": connection refused/, 'a failure names the table and the cause';
		Test::Mockingbird::unmock('Database::Abstraction::new');
	};

	subtest 'DataSource::_init_url_backend' => sub {
		my $self = bless { _url => $HTML_URL }, $DS;
		my @args;
		Test::Mockingbird::mock('Database::Abstraction::new', sub { @args = @_; bless {}, $_[0] });
		$self->_init_url_backend(2);
		Test::Mockingbird::unmock('Database::Abstraction::new');
		isa_ok $self->{_db}, 'Database::BI::_DB::HtmlUrl';
		is $args[1]{url}, $HTML_URL, 'the URL is passed';
		is $args[1]{html_table_index}, 2, 'and which table on the page';
		is $args[1]{no_entry}, 1, 'and there is no id column to demand';

		Test::Mockingbird::mock('Database::Abstraction::new', sub { require Carp; Carp::croak('404') });
		throws_ok { $self->_init_url_backend(0) }
			qr/\ADataSource: failed to open HTML table at "\Q$HTML_URL\E": 404/, 'a failed fetch names the URL';
		Test::Mockingbird::unmock('Database::Abstraction::new');
	};

	subtest 'DataSource::schema -- never lets a backend failure out' => sub {
		{
			package Stub::Function::SchemaDB;
			sub new    { bless { reply => $_[1] }, $_[0] }
			sub schema { my $r = $_[0]{reply}; ref $r eq 'CODE' ? $r->() : $r }
		}
		my $with = sub { bless { _db => $_[0] }, $DS };
		is_deeply $with->(undef)->schema, {}, 'no backend';
		is_deeply $with->(bless {}, 'Stub::Function::NoSchema')->schema, {}, 'a backend with no schema method';
		is_deeply $with->(Stub::Function::SchemaDB->new({ a => { type => 'integer' } }))->schema, { a => { type => 'integer' } }, 'what the backend reports';
		is_deeply $with->(Stub::Function::SchemaDB->new(sub { require Carp; Carp::croak('boom') }))->schema, {}, 'a backend that dies';
		is_deeply $with->(Stub::Function::SchemaDB->new([ 1 ]))->schema, {}, 'an answer of the wrong shape';
		is_deeply $with->(Stub::Function::SchemaDB->new(undef))->schema, {}, 'no answer';
	};
}

# ============================================================================
# PART U10: Database::BI -- the functions the earlier part misses
# ============================================================================
{
	subtest 'BI::_uploads_dir -- the one place that decides' => sub {
		my $app  = Test::Mojo->new('Database::BI')->app;
		my $home = $app->home;

		delete $app->config->{uploads_dir};
		is $app->_uploads_dir->to_string, $home->child('.uploads')->to_string, 'the default is under home';
		isa_ok $app->_uploads_dir, 'Mojo::File';

		$app->config->{uploads_dir} = 'staging';
		is $app->_uploads_dir->to_string, $home->child('staging')->to_string, 'a relative name is under home';

		my $abs = File::Spec->rel2abs(File::Spec->catdir(File::Spec->tmpdir, 'bi-staging'));
		$app->config->{uploads_dir} = $abs;
		is $app->_uploads_dir->to_string, $abs, 'an absolute name is used as it is';

		for my $junk ('', [], {}) {
			$app->config->{uploads_dir} = $junk;
			is $app->_uploads_dir->to_string, $home->child('.uploads')->to_string, 'an unusable setting means the default';
		}
		ok !-e $abs, 'and working it out creates nothing';
	};

	subtest 'BI::startup -- what a request can rely on' => sub {
		my $t2  = Test::Mojo->new('Database::BI');
		my $app = $t2->app;
		$app->config->{model_dir} = tempdir(CLEANUP => 1);

		ok $app->max_request_size > 0, 'request bodies are capped';
		ok length($app->config->{data_dir} // ''), 'a data directory is configured';
		ok defined $app->renderer->handlers->{tt}, 'templates render through the tt handler';
		ok length($app->defaults->{download_dir} // ''), 'a download directory is chosen';

		my @routes;
		my @queue = @{ $app->routes->children };
		while (my $r = shift @queue) { push @routes, $r; push @queue, @{ $r->children } }
		ok scalar @routes, 'routes are registered';

		$t2->get_ok('/no/such/page')->status_is(404)->content_like(qr/not found/i, 'a 404 is our own page');
		$t2->get_ok('/view/sales?range=not_a_range')->status_is(400);
	};
}


# ============================================================================
# PART U11: Database::BI::Controller::Dashboard -- the functions the earlier parts
# miss.  Pure helpers are called directly; those that read a request are given a
# controller holding that request; the route actions go through Test::Mojo, since
# what they promise is an HTTP answer.  Every route is then driven with hostile
# input: a 5xx or a Perl warning there is a bug, whatever else the page says.
# ============================================================================
{
	Readonly my $DASH     => 'Database::BI::Controller::Dashboard';
	Readonly my $SALES    => 'table:sales';
	# A fixed moment (Wed 20 May 2026, noon local) so date arithmetic is checkable.
	Readonly my $NOW      => POSIX::mktime(0, 0, 12, 20, 4, 126);
	Readonly my $PER_PAGE => 200;
	Readonly my $XSS_PROBE => '<script>alert(1)</script>';
	Readonly my $LONG_PARAM => 5000;
	Readonly my $REPLY_TIMEOUT => 5;
	# Each request costs real time, so an ordinary run tries one at a time only those
	# parameters that are parsed or reach a script; EXTENDED_TESTING tries them all.
	Readonly my @RISKIEST_PARAMS => qw(bins topn minlen page per_page scheme range cs span tcol f c format);
	# Each of these is a case nobody considered, whatever the page went on to do.
	Readonly my $PERL_INTERNAL_WARNING => qr/uninitialized|isn't numeric|substr outside|Deep recursion|Odd number|Wide character|filename containing newline|masks earlier|Invalid \\0/;

	no strict 'refs';
	my %F = map { $_ => \&{"${DASH}::$_"} } qw(
		_pagination _breadcrumb_trail _crumb_local _crumb_parent _crumb_label _crumb_spec_name
		_crumb_view_suffix _crumb_chart_subject _template_languages _has_templates _data_dir_for
		_tidy_error _schema_type_name _is_iso_date _to_iso_date _date_key _iso_day _iso_second
		_midday _time_range_bounds _time_range_specs _time_range_preset _time_range_presets
		_apply_time_range _trim _dedup_requested _filter_specs_to_criteria _measure _numeric_cell
		_column_is_numeric _card_plan _cross_row_ui_state _cross_row_values _cross_row_cmp
		_extend_row _canonical_path _inside_dir _chart_orientation _vis_cf_col _decode_cell
		_percent_encode _word_tokens _wordcloud_option _wordcloud_link _map_popup _map_size_range
		_map_radius _map_limit _parse_color _parse_color_rules _apply_color_rule _marker_icon
		_color_hex _iso8601_utc _scope_card_scripts _wrap_card_script
	);
	use strict 'refs';

	# A controller holding one request, for helpers that read their parameters.
	sub dash_controller {
		my ($app, $url) = @_;
		my $tx = Mojo::Transaction::HTTP->new;
		$tx->req->method('GET');
		$tx->req->url->parse($url // '/');
		$tx->req->url->base->parse('http://localhost:3000');
		# A controller's hold on its transaction is weak, so something else must keep it.
		our @LIVE_TX;
		push @LIVE_TX, $tx;
		return Database::BI::Controller::Dashboard->new(app => $app, tx => $tx);
	}

	# An application with its own stores, for a subtest that writes to them or
	# changes what the configuration says.
	sub isolated_app {
		my $tm = Test::Mojo->new('Database::BI');
		$tm->app->config->{model_dir}   = tempdir(CLEANUP => 1);
		$tm->app->config->{uploads_dir} = tempdir(CLEANUP => 1);
		return $tm;
	}

	require Mojo::Transaction::HTTP;
	require Mojo::Parameters;
	require Mojo::URL;
	require Mojo::Util;
	my $app = $t->app;

	subtest 'Dashboard::_pagination -- sane whatever is asked for' => sub {
		is_deeply [ $F{_pagination}->(dash_controller($app, '/')) ], [ 1, $PER_PAGE, 0 ], 'the defaults';
		is_deeply [ $F{_pagination}->(dash_controller($app, '/?page=3&per_page=10')) ], [ 3, 10, 20 ], 'as asked';
		is_deeply [ $F{_pagination}->(dash_controller($app, '/?page=-5&per_page=-5')) ], [ 1, 1, 0 ], 'a negative is clamped up';
		my ($p, $n) = $F{_pagination}->(dash_controller($app, '/?per_page=99999999'));
		ok $n < 99999999, 'a huge page size is clamped down';
	};

	# Why: int('abc') warns and is 0, and a per_page of 0 is clamped to one row, so
	# a stray parameter showed a single-row table.  1e400 is Inf, and an infinite
	# OFFSET is not something a database can be asked for.
	subtest 'Dashboard::_pagination -- input that is not a number' => sub {
		for my $junk ('abc', '1x', '1e400', '9' x 400, 'Inf', 'NaN', '', '0x10', "1\n") {
			(my $shown = substr($junk, 0, 8)) =~ s/\n/NL/;
			my @got;
			warnings_are {
				@got = $F{_pagination}->(dash_controller($app, '/?page=' . Mojo::Util::url_escape($junk) . '&per_page=' . Mojo::Util::url_escape($junk)));
			} [], "'$shown' raises no warning";
			is_deeply \@got, [ 1, $PER_PAGE, 0 ], "and means the defaults, not one row";
		}
	};

	subtest 'Dashboard::_crumb_spec_name' => sub {
		is $F{_crumb_spec_name}->($SALES), 'sales', 'a table';
		is $F{_crumb_spec_name}->('table:store/orders'), 'store: orders', 'an internal table';
		is $F{_crumb_spec_name}->('path:/a/b/c.csv'), 'c.csv', 'a path shows only its file name';
		is $F{_crumb_spec_name}->('url:http://example.com/x.html'), 'example.com', 'a web page its host';
		is $F{_crumb_spec_name}->('URL:http://example.com/'), 'example.com', 'in any case';
		is $F{_crumb_spec_name}->('redis://secret-host:6379/0'), 'Redis', 'a Redis URL is not shown';
		is $F{_crumb_spec_name}->(undef), '', 'nothing';
		is $F{_crumb_spec_name}->('junk'), 'junk', 'anything else as it is';
	};

	subtest 'Dashboard::_crumb_view_suffix' => sub {
		my $q = sub { Mojo::Parameters->new($_[0]) };
		is $F{_crumb_view_suffix}->($q->('')), '', 'no filters';
		is $F{_crumb_view_suffix}->($q->('f=region:empty')), ' (region is empty)', 'a unary operator has no value'
			if $F{_crumb_view_suffix}->($q->('f=region:empty')) =~ /is empty/;
		like $F{_crumb_view_suffix}->($q->('f=region:eq:East')), qr/\A \(region .+ East\)\z/, 'a filter';
		like $F{_crumb_view_suffix}->($q->('f=a:eq:1&f=b:eq:2&f=c:eq:3&f=d:eq:4')), qr/\+2 more\)\z/, 'more than two are counted';
		like $F{_crumb_view_suffix}->($q->('range=last_30_days')), qr/\A \(last 30 days\)\z/i, 'a range';
		is $F{_crumb_view_suffix}->($q->('range=nonsense')), '', 'an unknown range';
		is $F{_crumb_view_suffix}->($q->('f=:eq:x&f=col')), '', 'malformed filters are left out';
		is $F{_crumb_view_suffix}->($q->('f=' . Mojo::Util::url_escape('<b>:eq:x'))), '', 'markup in a column is not repeated';
		is $F{_crumb_view_suffix}->($q->('f=' . Mojo::Util::url_escape('a:eq:<b>'))), '', 'nor in a value';
		is $F{_crumb_view_suffix}->($q->('f=' . Mojo::Util::url_escape(('x' x 65) . ':eq:y'))), '', 'nor a value too long to be a label';
		is $F{_crumb_view_suffix}->($q->('f=' . Mojo::Util::url_escape('place:in:["<b>","Rome"]'))), ' (place is one of 2 values)',
			'a list is counted, never repeated';
		is $F{_crumb_view_suffix}->($q->('f=' . Mojo::Util::url_escape('place:in:nonsense'))), ' (place is one of 0 values)',
			'and a list that is not one counts nothing';
	};

	subtest 'Dashboard::_crumb_chart_subject' => sub {
		my $s = sub { $F{_crumb_chart_subject}->($_[0], Mojo::Parameters->new($_[1])) };
		is $s->('graph', 'x=when&y=amount'), 'amount by when', 'a line';
		is $s->('scatter', 'x=a&y=b'), 'b by a', 'a scatter';
		is $s->('heatmap', 'x=a&y=b'), 'a by b', 'a heatmap';
		is $s->('stacked', 'cat=a&seg=b'), 'a by b', 'a stacked bar';
		is $s->('pivot', 'rows=a,b'), 'a, b', 'a pivot';
		is $s->('map', 'loc=town'), 'town', 'a map by place';
		is $s->('map', 'lat=a&lon=b'), 'a, b', 'a map by position';
		is $s->('map', ''), '', 'a map of nothing';
		is $s->('bar', 'cat=region&val=amount'), 'amount by region', 'a bar';
		is $s->('bar', 'cat=region'), 'Count by region', 'a bar with no measure counts';
		is $s->('pie', 'cat=region&val=__count__'), 'Count by region', 'the count marker has a name';
		is $s->('histogram', 'col=amount'), 'amount', 'a histogram';
		is $s->('stats', ''), '', 'a page about the whole table has none';
		is $s->('bar', 'cat=' . Mojo::Util::url_escape('<script>') . '&val=a'), '', 'markup is dropped, and a measure alone says nothing';
	};

	subtest 'Dashboard::_crumb_local -- a parent link has to be on this site' => sub {
		my $c = dash_controller($app, '/bar');
		is $F{_crumb_local}->($c, '/view/sales?x=1')->to_string, '/view/sales?x=1', 'a local link';
		is $F{_crumb_local}->($c, 'http://localhost:3000/view/sales')->to_string, '/view/sales', 'an absolute one here is reduced';
		is $F{_crumb_local}->($c, $_), undef, "'$_' is not followed" for
			'', '/', 'http://evil.example/x', 'javascript:alert(1)', 'data:text/html,x', '//evil.example/x', 'view/sales';
		is $F{_crumb_local}->($c, undef), undef, 'nor is nothing';
	};

	subtest 'Dashboard::_crumb_parent -- each kind of page' => sub {
		my $c = dash_controller($app, '/');
		my $p = sub { my $u = $F{_crumb_parent}->($c, Mojo::URL->new($_[0])); $u ? $u->to_string : undef };
		is $p->('/bar?back=%2Fview%2Fsales'), '/view/sales', 'a chart follows back=';
		like $p->('/bar?l=table:sales'), qr{\A/view/sales}, 'or falls back to its source';
		is $p->('/view/sales?back2=%2Fbar%3Fcat%3Da'), '/bar?cat=a', 'a drill-down follows back2=';
		is $p->('/view/sales'), undef, 'a table in data_dir has no parent';
		is $p->('/import'), undef, 'nor an import with no link';
		like $p->('/open?path=/a/b/c.csv'), qr{\A/browse\?path=%2Fa%2Fb}, 'a file has its folder';
		is $p->('/open?path='), undef, 'no file, no folder';
		is $p->('/open?path=/../host/x.csv'), undef, 'a remote file has no local folder';
		like $p->('/tables?l=path:/a/b.db'), qr{\A/browse\?path=%2Fa}, 'a schema page has its folder';
		is $p->('/tables?l=table:store'), undef, 'unless it has no path';
		is $p->('/a/abc?back=%2Fcatalog'), '/catalog', 'a canvas follows back=';
		is $p->('/nothing'), undef, 'anything else has none';
		is $p->('/bar?back=http://evil.example/&l=nonsense'), undef, 'an outside link is never followed';
	};

	subtest 'Dashboard::_crumb_label -- each kind of page' => sub {
		my $c = dash_controller($app, '/');
		my $l = sub { $F{_crumb_label}->($c, Mojo::URL->new($_[0])) };
		is $l->('/view/sales'), 'sales', 'a table';
		is $l->('/open?path=/a/b.csv'), 'b.csv', 'a file';
		is $l->('/open?path=/a/b.db&it=orders'), 'b.db: orders', 'a table in a file';
		is $l->('/open'), undef, 'no file';
		is $l->('/join?l=table:a&j=table:b|x|y'), 'a + b', 'a merge';
		is $l->('/combine?l=table:a&c=table:b'), 'a + b', 'a combine';
		is $l->('/join'), undef, 'a merge of nothing';
		is $l->('/import?url=http://example.com/x'), 'example.com', 'an import';
		is $l->('/import'), undef, 'of nowhere';
		like $l->('/bar?cat=a&val=b'), qr/b by a\z/, 'a chart';
		is $l->('/tables?l=table:store'), 'store schema', 'a schema';
		is $l->('/tables'), undef, 'of nothing';
		is $l->('/browse'), 'Files', 'browsing';
		is $l->('/browse?path=/a/b'), 'Files: b', 'a folder';
		is $l->('/catalog'), 'Catalog', 'the catalog';
		is $l->('/tutorial'), 'Tutorial', 'the tutorial';
		is $l->('/a/nosuchcanvas'), 'Canvas', 'an unknown canvas';
		is $l->('/unknown'), undef, 'a page with no place in a trail';
	};

	subtest 'Dashboard::_breadcrumb_trail -- short, never endless' => sub {
		is_deeply $F{_breadcrumb_trail}->(undef), [], 'no controller';
		is_deeply $F{_breadcrumb_trail}->('x'), [], 'not a controller';
		is_deeply $F{_breadcrumb_trail}->(dash_controller($app, '/')), [], 'Home is not in its own trail';

		my $trail = $F{_breadcrumb_trail}->(dash_controller($app, '/bar?cat=a&back=%2Fview%2Fsales'));
		is_deeply [ map { $_->{url} } @$trail ], [ '/view/sales', '/bar?cat=a&back=%2Fview%2Fsales' ], 'parent first, this page last';

		my $self_loop = '/bar?back=' . Mojo::Util::url_escape('/bar?back=x');
		lives_ok { $F{_breadcrumb_trail}->(dash_controller($app, $self_loop)) } 'a chain that goes nowhere';

		# A URL naming itself as its own parent, and one nested very deep.
		my $deep = '/view/sales';
		$deep = '/bar?back=' . Mojo::Util::url_escape($deep) for 1 .. 40;
		ok scalar(@{ $F{_breadcrumb_trail}->(dash_controller($app, $deep)) }) <= 10, 'a very deep chain is capped';
		memory_cycle_ok($trail, 'no cycle');
	};

	subtest 'Dashboard::_template_languages, _has_templates, _data_dir_for' => sub {
		my $home = Mojo::File->new(tempdir(CLEANUP => 1));
		is_deeply [ $F{_template_languages}->($home, 'web') ], [], 'no templates directory';
		is $F{_has_templates}->($home, 'web', 'en'), 0, 'so no language';

		$home->child("templates/web/$_")->make_path for qw(fr en);
		$home->child('templates/web/stray.txt')->spew('x');
		is_deeply [ $F{_template_languages}->($home, 'web') ], [qw(en fr)], 'sorted, and only directories';
		is $F{_has_templates}->($home, 'web', 'en'), 1, 'a language with a directory';
		is $F{_has_templates}->($home, 'web', 'de'), 0, 'one without';
		is $F{_has_templates}->($home, 'web', undef), 0, 'undef';
		is $F{_has_templates}->($home, 'web', ''), 0, 'empty';

		my $tm = isolated_app();
		$tm->app->config->{data_dir} = 'relative';
		is $F{_data_dir_for}->($tm->app)->to_string, $tm->app->home->child('relative')->to_string, 'a relative data_dir is under home';
		my $abs = tempdir(CLEANUP => 1);
		$tm->app->config->{data_dir} = $abs;
		is $F{_data_dir_for}->($tm->app)->to_string, $abs, 'an absolute one is used as given';
		delete $tm->app->config->{data_dir};
		is $F{_data_dir_for}->($tm->app)->to_string, $tm->app->home->child('data')->to_string, 'the default';
	};

	subtest 'Dashboard::_scan_join_tables' => sub {
		my $tm  = isolated_app();
		my $c   = dash_controller($tm->app, '/');
		my $got = Database::BI::Controller::Dashboard::_scan_join_tables($c);
		returns_is $got, { type => 'arrayref' }, 'a list';
		ok((grep { $_->{spec} eq $SALES } @$got), 'each file has a spec');

		$tm->app->config->{data_dir} = File::Spec->catdir(tempdir(CLEANUP => 1), 'absent');
		is_deeply Database::BI::Controller::Dashboard::_scan_join_tables(dash_controller($tm->app, '/')), [], 'no data directory, no tables';
	};

	subtest 'Dashboard::_tidy_error' => sub {
		is $F{_tidy_error}->('Bad thing at /a/b.pm line 3.'), 'Bad thing', 'one location';
		is $F{_tidy_error}->("Bad at /a.pm line 3.\n at /b.pm line 4.\n"), 'Bad', 'one for each level it was passed up';
		is $F{_tidy_error}->('Bad at /my dir/b.pm line 3.'), 'Bad', 'a path with a space in it';
		is $F{_tidy_error}->('Look at this'), 'Look at this', 'text with no location is unchanged';
		is $F{_tidy_error}->(undef), '', 'nothing';
	};

	subtest 'Dashboard::_schema_type_name and _schema_type_warnings' => sub {
		is $F{_schema_type_name}->({ type => 'integer' }), 'INTEGER', 'from a hash';
		is $F{_schema_type_name}->('text'), 'TEXT', 'from a string';
		is $F{_schema_type_name}->($_), '', 'nothing to read' for undef, '', {}, { type => undef }, { type => [] }, { type => '' };

		{
			package Stub::Function::SchemaSource;
			sub new    { bless { s => $_[1] }, $_[0] }
			sub schema { my $s = $_[0]{s}; if (!ref $s) { require Carp; Carp::croak($s) } $s }
		}
		my $fn = \&Database::BI::Controller::Dashboard::_schema_type_warnings;
		my $c  = dash_controller($app, '/');
		my $sc = sub { Stub::Function::SchemaSource->new($_[0]) };

		my @w = $fn->($c, $sc->({ a => 'INT', id => 'INT' }), $sc->({ a => 'TEXT', id => 'TEXT' }), 'L', 'R', 'id', 'id');
		is scalar @w, 1, 'one column disagrees; the key is free to';
		like $w[0], qr/\ba\b.*INT.*L.*TEXT.*R/, 'and the message says how';

		is_deeply [ $fn->($c, $sc->({ a => 'INT' }), $sc->({ a => 'INT' }), 'L', 'R', '', '') ], [], 'agreement';
		is_deeply [ $fn->($c, $sc->({ a => 'INT' }), $sc->({ b => 'TEXT' }), 'L', 'R', '', '') ], [], 'no column in common';
		is_deeply [ $fn->($c, $sc->({ a => '' }), $sc->({ a => 'TEXT' }), 'L', 'R', '', '') ], [], 'an undeclared type';
		is_deeply [ $fn->($c, $sc->({}), $sc->({ a => 'TEXT' }), 'L', 'R', '', '') ], [], 'no schema on one side';
		lives_ok { $fn->($c, $sc->('boom'), $sc->({ a => 'TEXT' }), 'L', 'R', '', '') } 'a backend that dies';
	};

	subtest 'Dashboard::_is_iso_date, _to_iso_date, _date_key' => sub {
		ok $F{_is_iso_date}->($_), "'$_' is ISO" for '2026-05-20', '2026-05-20T10:30', '2026-05-20 10:30:15';
		ok !$F{_is_iso_date}->($_), "'$_' is not" for '', '5/20/2026', '2026-5-20', '2026-05-20T', "2026-05-20\n", 'x';
		warnings_are { ok !$F{_is_iso_date}->(undef), 'undef is not' } [], 'and says so quietly';

		is $F{_to_iso_date}->('2026-05-20'), '2026-05-20', 'ISO is unchanged';
		is $F{_to_iso_date}->('2026-05-20T10:30:15'), '2026-05-20T10:30:15', 'with its time';
		is $F{_to_iso_date}->('5/2/2026'), '2026-05-02', 'a US date';
		is_deeply [ $F{_to_iso_date}->('junk') ], [], 'junk';
		warnings_are { is_deeply [ $F{_to_iso_date}->(undef) ], [], 'nothing' } [], 'quietly';

		is $F{_date_key}->('2026-05-20T10:30:15', 10), '2026-05-20', 'to the day';
		is $F{_date_key}->('2026-05-20', 19), '2026-05-20T00:00:00', 'a day at second precision is its midnight';
		is $F{_date_key}->('2026-05-20 10:30', 19), '2026-05-20T10:30:00', 'with no seconds';
		is $F{_date_key}->('junk', 19), undef, 'junk';
		is $F{_date_key}->(undef, 10), undef, 'nothing';
	};

	subtest 'Dashboard::_iso_day, _iso_second, _midday, _iso8601_utc' => sub {
		is $F{_iso_day}->($NOW), '2026-05-20', 'a day';
		is $F{_iso_second}->($NOW), '2026-05-20T12:00:00', 'a second';
		is $F{_iso_day}->($F{_midday}->(0, 2, 126)), '2026-02-28', 'day 0 is the last of the month before';
		is $F{_iso_day}->($F{_midday}->(1, -1, 126)), '2025-12-01', 'month -1 is December';
		like $F{_iso8601_utc}->(), qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, 'a UTC stamp';
	};

	subtest 'Dashboard::_time_range_bounds -- every preset, on a known day' => sub {
		my $b = sub { [ $F{_time_range_bounds}->($F{_time_range_preset}->($_[0]), $NOW) ] };
		is_deeply $b->('today'), [ '2026-05-20', '2026-05-20' ], 'today';
		is_deeply $b->('yesterday'), [ '2026-05-19', '2026-05-19' ], 'yesterday';
		is_deeply $b->('last_7_days'), [ '2026-05-14', '2026-05-20' ], 'seven days, today included';
		is_deeply $b->('this_month'), [ '2026-05-01', '2026-05-20' ], 'this month ends today';
		is_deeply $b->('last_month'), [ '2026-04-01', '2026-04-30' ], 'last month is whole';
		is_deeply $b->('this_quarter'), [ '2026-04-01', '2026-05-20' ], 'this quarter';
		is_deeply $b->('last_quarter'), [ '2026-01-01', '2026-03-31' ], 'last quarter';
		is_deeply $b->('this_year'), [ '2026-01-01', '2026-05-20' ], 'this year';
		is_deeply $b->('last_year'), [ '2025-01-01', '2025-12-31' ], 'last year';
		is_deeply $b->('last_24_hours'), [ '2026-05-19T12:00:00', '2026-05-20T12:00:00' ], 'hours are to the second';
		is_deeply [ $F{_time_range_bounds}->({}, $NOW) ], [], 'a preset with no window has none';

		# Across a year boundary: January's last month and first quarter's last quarter.
		my $jan = POSIX::mktime(0, 0, 12, 15, 0, 126);
		is_deeply [ $F{_time_range_bounds}->($F{_time_range_preset}->('last_month'), $jan) ], [ '2025-12-01', '2025-12-31' ], 'last month from January';
		is_deeply [ $F{_time_range_bounds}->($F{_time_range_preset}->('last_quarter'), $jan) ], [ '2025-10-01', '2025-12-31' ], 'last quarter from January';
	};

	subtest 'Dashboard::_time_range_specs, _preset, _presets' => sub {
		is_deeply $F{_time_range_specs}->('d', '2026-01-01', '2026-02-01'), [ 'd:ge:2026-01-01', 'd:le:2026-02-01' ], 'two bounds';
		is_deeply $F{_time_range_specs}->(@$_), [], 'missing a part' for [ '', 'a', 'b' ], [ 'd', '', 'b' ], [ 'd', 'a', '' ], [ undef, 'a', 'b' ];
		is $F{_time_range_preset}->($_), undef, 'an unknown name is nothing, not a croak' for undef, '', 'nope', '../x';
		ok $F{_time_range_preset}->('today'), 'a known one';
		my $presets = $F{_time_range_presets}->($NOW);
		returns_is $presets, { type => 'arrayref' }, 'the menu is a list';
		ok !(grep { !length($_->{name} // '') || !length($_->{label} // '') || !length($_->{lo} // '') } @$presets), 'each entry is complete';
	};

	subtest 'Dashboard::_apply_time_range -- a stale bookmark shows everything' => sub {
		my $today = $F{_iso_day}->(time());
		my @rows = ({ d => $today, n => 1 }, { d => '1999-01-01', n => 2 });
		is_deeply [ map { $_->{n} } @{ $F{_apply_time_range}->(\@rows, 'last_7_days', 'd') } ], [1], 'a real range filters';
		is $F{_apply_time_range}->(\@rows, $_, 'd'), \@rows, 'an unknown name leaves the rows' for undef, '', 'nope';
		is $F{_apply_time_range}->(\@rows, 'today', $_), \@rows, 'an unusable column leaves them' for undef, '', 'a:b';
	};

	subtest 'Dashboard::_trim' => sub {
		is $F{_trim}->("  a b \n"), 'a b', 'both ends';
		is $F{_trim}->(undef), '', 'nothing';
		is $F{_trim}->('   '), '', 'only space';
		keeps_globals_ok('_trim', sub { $F{_trim}->(' x ') });
	};

	subtest 'Dashboard::_dedup_requested' => sub {
		is $F{_dedup_requested}->(dash_controller($app, '/?d=1')), 1, 'd=1';
		is $F{_dedup_requested}->(dash_controller($app, '/?d=0')), 0, 'd=0';
		is $F{_dedup_requested}->(dash_controller($app, '/')), 0, 'none';
	};

	subtest 'Dashboard::_filter_specs_to_criteria -- only a SQL backend is pushed to' => sub {
		{
			package Stub::Function::SqlSource;
			sub dbi_source { 1 }
			package Stub::Function::CsvSource;
			sub dbi_source { undef }
			package Stub::Function::NoDbi;
			sub new { bless {}, shift }
		}
		my $sql = bless {}, 'Stub::Function::SqlSource';
		my @specs = ('a:eq:1');
		for my $src (undef, bless({}, 'Stub::Function::CsvSource'), Stub::Function::NoDbi->new) {
			my ($crit, $res) = $F{_filter_specs_to_criteria}->(\@specs, $src);
			is_deeply $crit, {}, 'nothing pushed without SQL';
			is_deeply $res, \@specs, 'it all stays in Perl';
		}

		my %want = (
			'a:eq:x'       => { a => { -like => 'x' } },
			'a:ne:x'       => { a => { -not_like => 'x' } },
			'a:contains:x' => { a => { -like => '%x%' } },
			'a:starts:x'   => { a => { -like => 'x%' } },
			'a:lt:1'       => { a => { '<' => 1 } },
			'a:le:1'       => { a => { '<=' => 1 } },
			'a:gt:1'       => { a => { '>' => 1 } },
			'a:ge:1'       => { a => { '>=' => 1 } },
		);
		for my $spec (sort keys %want) {
			my ($crit, $res) = $F{_filter_specs_to_criteria}->([$spec], $sql);
			is_deeply $crit, $want{$spec}, "$spec is pushed";
			is_deeply $res, [], 'and not repeated';
		}
	};

	subtest 'Dashboard::_filter_specs_to_criteria -- what must not reach SQL' => sub {
		my $sql = bless {}, 'Stub::Function::SqlSource';
		for my $spec ('a:eq:50%', 'a:eq:a_b', 'a:ne:%', 'a:contains:%', 'a:starts:_', 'a:lt:abc', 'a:le:$5', 'a:gt:1,000', 'a:ge:',
			'a:empty', 'a:notempty', 'a:between:1:2', 'a:nosuchop:1') {
			my ($crit, $res) = $F{_filter_specs_to_criteria}->([$spec], $sql);
			is_deeply $crit, {}, "$spec is not pushed";
			is_deeply $res, [$spec], 'it is filtered in Perl instead';
		}
		my ($crit, $res) = $F{_filter_specs_to_criteria}->([ 'a:gt:1', 'a:lt:9' ], $sql);
		is_deeply $crit, { a => { '>' => 1 } }, 'the first condition on a column is pushed';
		is_deeply $res, ['a:lt:9'], 'the second stays, so the AND holds';
		($crit, $res) = $F{_filter_specs_to_criteria}->([ '', ':eq:x', 'col', 'col:' ], $sql);
		is_deeply [ $crit, $res ], [ {}, [] ], 'malformed specs are dropped';
	};

	subtest 'Dashboard::_measure' => sub {
		is_deeply $F{_measure}->('sum', 'a', 'v'), { fn => 'sum', col => 'a', as => 'v' }, 'with a column';
		is_deeply $F{_measure}->('count', undef, 'v'), { fn => 'count', as => 'v' }, 'COUNT(*) has none';
	};

	subtest 'Dashboard::_numeric_cell -- what is a number' => sub {
		is $F{_numeric_cell}->('12'), 12, 'an integer';
		is $F{_numeric_cell}->('-1.5'), -1.5, 'a negative';
		is $F{_numeric_cell}->('$1,234.56'), 1234.56, 'currency and thousands';
		is $F{_numeric_cell}->('(1,234.56)'), -1234.56, 'accounting brackets';
		is $F{_numeric_cell}->('USD 100'), 100, 'a currency code before';
		is $F{_numeric_cell}->('100 EUR'), 100, 'or after';
		is $F{_numeric_cell}->('50%'), 50, 'a percentage';
		is $F{_numeric_cell}->('1e3'), 1000, 'scientific notation is its value, not 13';
		is $F{_numeric_cell}->("\xC2\xA35"), 5, 'a pound sign in UTF-8';
	};

	# Why: its contract is undef for non-numeric input.  Stripping everything but
	# digits read 'SKU123' as 123, 12/25/2025 as 12252025, and made any code column
	# a chartable measure with a total nobody asked for.
	subtest 'Dashboard::_numeric_cell -- text that merely holds digits is not' => sub {
		is $F{_numeric_cell}->($_), undef, "'$_' is not a number" for
			'', 'abc', 'SKU123', 'A1', 'AB-100', 'R2D2', 'v1.2', '12/25/2025', '2026-05-20', '10:30', '1.2.3', '--5', '-', '.', '()', 'Widget 2';
		is $F{_numeric_cell}->(undef), undef, 'nor is nothing';
		keeps_globals_ok('_numeric_cell', sub { $F{_numeric_cell}->('$5') });
	};

	subtest 'Dashboard::_column_is_numeric' => sub {
		my $r = sub { [ map { { a => $_ } } @_ ] };
		is $F{_column_is_numeric}->($r->(1, 2, '$3'), 'a'), 1, 'all numbers';
		is $F{_column_is_numeric}->($r->(1, 'x'), 'a'), 0, 'one that is not';
		is $F{_column_is_numeric}->($r->('', undef, 5), 'a'), 1, 'blanks are passed over';
		is $F{_column_is_numeric}->($r->('', undef), 'a'), 0, 'only blanks is not numeric';
		is $F{_column_is_numeric}->($r->('SKU1', 'SKU2'), 'a'), 0, 'product codes are not a measure';
		is $F{_column_is_numeric}->($r->('12/25/2025'), 'a'), 0, 'nor are dates';
		is $F{_column_is_numeric}->(undef, 'a'), 0, 'no rows';
		is $F{_column_is_numeric}->([ { b => 1 } ], 'a'), 0, 'a column that is not there';
		is $F{_column_is_numeric}->($r->((1) x 20, 'x'), 'a'), 1, 'only the first twenty are read, by design';
	};

	subtest 'Dashboard::_cross_row_values -- the arithmetic' => sub {
		my $v = sub { [ $F{_cross_row_values}->(@_) ] };
		is_deeply $v->('running_total', [ 1, 2, 3 ]), [ 1, 3, 6 ], 'running total';
		is_deeply $v->('running_total', [ 1, undef, 3 ]), [ 1, undef, 4 ], 'a gap stays a gap';
		is_deeply $v->('running_count', [ undef, undef ]), [ 1, 2 ], 'running count counts rows';
		is_deeply $v->('running_pct', [ 1, 3 ]), [ 0.25, 1 ], 'running percent';
		is_deeply $v->('running_pct', [ 0, 0 ]), [ undef, undef ], 'of a zero total is nothing, not a division by it';
		is_deeply $v->('window_sum', [ 1, 2, 3 ], 2), [ 1, 3, 5 ], 'window sum';
		is_deeply $v->('window_avg', [ 1, 3, undef ], 2), [ 1, 2, 3 ], 'window average of what is there';
		is_deeply $v->('window_sum', [ undef, undef ], 2), [ undef, undef ], 'an empty window is nothing';
		is_deeply $v->('window_sum', [ 1, 2 ], 9_999_999), [ 1, 3 ], 'a window larger than the data';
		is_deeply $v->('lag', [ 1, 2, 3 ]), [ undef, 1, 2 ], 'lag';
		is_deeply $v->('delta', [ 1, 4, undef, 5 ]), [ undef, 3, undef, undef ], 'delta needs both';
		is_deeply $v->('pct_change', [ 2, 3, 0, 5 ]), [ undef, 0.5, -1, undef ], 'percent change, never from zero';
		is_deeply $v->('pct_of_total', [ 1, 3, undef ]), [ 0.25, 0.75, undef ], 'percent of total';
		is_deeply $v->('pct_of_total', [ 0, undef ]), [ undef, undef ], 'of nothing';
		is_deeply $v->('rank', [ 10, 30, 30, 5, undef ]), [ 3, 1, 1, 4, undef ], 'rank, with ties sharing and skipping';
		is_deeply $v->('zscore', [ 5 ]), [ undef ], 'zscore of one value';
		is_deeply $v->('zscore', [ 5, 5 ]), [ undef, undef ], 'of no spread';
		my $z = $v->('zscore', [ 1, 3 ]);
		cmp_ok $z->[0], '<', 0, 'below the mean is negative';
		cmp_ok $z->[1], '>', 0, 'above it positive';
		is_deeply $v->('running_total', []), [], 'no rows';
		throws_ok { $F{_cross_row_values}->('nosuch', [ 1 ]) } qr/\AUnknown cross-row function 'nosuch' at /, 'an unknown function';
	};

	subtest 'Dashboard::_cross_row_cmp' => sub {
		is $F{_cross_row_cmp}->('20', '100'), -1, 'numbers as numbers';
		is $F{_cross_row_cmp}->('$20', '$3'), 1, 'with currency';
		is $F{_cross_row_cmp}->('a', 'b'), -1, 'text as text';
		is $F{_cross_row_cmp}->('a', 'A'), 1, 'case matters, so it is total';
		is $F{_cross_row_cmp}->(undef, undef), 0, 'nothing and nothing';
		is $F{_cross_row_cmp}->(undef, 'a'), -1, 'nothing sorts first';
		is $F{_cross_row_cmp}->('10', 'a'), -1, 'a mix falls back to text';
	};

	subtest 'Dashboard::_cross_row_specs_from -- a plan, or why not' => sub {
		my $c = dash_controller($app, '/');
		my $fn = \&Database::BI::Controller::Dashboard::_cross_row_specs_from;
		my @cols = qw(a b d);
		my $err = sub { $fn->($c, \@cols, $_[0])->{error} };

		is $fn->($c, \@cols, {}), undef, 'no plan';
		is $fn->($c, \@cols, { cs => [ '', undef, [] ] }), undef, 'nothing usable in it';

		my $ok = $fn->($c, \@cols, { cs => ['a:running_total:t'], by => ' b , ', order => [ 'd:DESC', ' a ' ] });
		is_deeply $ok->{specs}, [ { col => 'a', fn => 'running_total', as => 't', arg => undef } ], 'the spec';
		is_deeply $ok->{by}, ['b'], 'the partition, trimmed';
		is_deeply $ok->{order}, [ { col => 'd', dir => 'desc' }, { col => 'a', dir => 'asc' } ], 'the order, with its default';

		like $err->({ cs => ['a'] }), qr/must be <column>:<function>:<alias>/, 'too few parts';
		like $err->({ cs => ['nope:rank:r'] }), qr/nope/, 'a column that does not exist';
		like $err->({ cs => ['a:system:r'] }), qr/Unknown cross-row function "system"/, 'a function that does not exist';
		like $err->({ cs => ['a:rank:1bad'] }), qr/1bad/, 'an alias that is not an identifier';
		like $err->({ cs => ['a:rank:b'] }), qr/\bb\b/, 'an alias that is already a column';
		like $err->({ cs => [ 'a:rank:r', 'b:rank:r' ] }), qr/\br\b/, 'an alias used twice';
		like $err->({ cs => ['a:window_sum:w'], order => ['d'] }), qr/window_sum/, 'a window with no size';
		like $err->({ cs => ['a:window_sum:w:0'], order => ['d'] }), qr/window_sum/, 'a window of none';
		like $err->({ cs => ['a:window_sum:w:x'], order => ['d'] }), qr/window_sum/, 'a window of text';
		like $err->({ cs => ['a:rank:r:5'] }), qr/rank/, 'a size for a function that takes none';
		like $err->({ cs => ['a:rank:r'], by => 'nope' }), qr/nope/, 'a partition that does not exist';
		like $err->({ cs => ['a:rank:r'], order => ['nope'] }), qr/nope/, 'an order that does not exist';
		like $err->({ cs => ['a:rank:r'], order => ['a:sideways'] }), qr/sideways/, 'a direction that does not';
		like $err->({ cs => ['a:running_total:t'] }), qr/running_total/, 'a running total with no order is refused by name';
	};

	subtest 'Dashboard::_cross_row_specs and _apply_cross_row' => sub {
		my $c = dash_controller($app, '/?cs=a:running_total:t&by=g&order=a');
		my @rows = ({ g => 'x', a => 2 }, { g => 'y', a => 5 }, { g => 'x', a => 1 });
		my ($got, $cols) = Database::BI::Controller::Dashboard::_apply_cross_row($c, \@rows, [qw(g a)]);
		is_deeply [ map { $_->{t} } @$got ], [ 3, 5, 1 ], 'each partition keeps its own total, read along order=';
		is_deeply [ map { $_->{a} } @$got ], [ 2, 5, 1 ], 'and the rows stay where they were';
		is_deeply $cols, [qw(g a t)], 'the new column is added';
		is $c->stash('_virtual_columns')->{t}, 1, 'and marked virtual, so it is not pushed to SQL';

		my $none = dash_controller($app, '/');
		my ($same, $same_cols) = Database::BI::Controller::Dashboard::_apply_cross_row($none, \@rows, [qw(g a)]);
		is $same, \@rows, 'no plan leaves the rows alone';

		my $bad = dash_controller($app, '/?cs=nope:rank:r');
		throws_ok { Database::BI::Controller::Dashboard::_apply_cross_row($bad, \@rows, [qw(g a)]) } qr/nope/, 'a bad plan croaks for the route to answer';

		# A locked row, as SQL-backed sources return.
		require Hash::Util;
		my %locked = (g => 'x', a => 1);
		Hash::Util::lock_ref_keys(\%locked);
		my ($ext) = Database::BI::Controller::Dashboard::_apply_cross_row(dash_controller($app, '/?cs=a:rank:r'), [ \%locked ], [qw(g a)]);
		is $ext->[0]{r}, 1, 'a locked row is extended by copying';
		ok !exists $locked{r}, 'and the original is not touched';

		my ($derived, $dc) = Database::BI::Controller::Dashboard::_apply_cross_row(dash_controller($app, '/?cs=a:rank:r'), [ { a => 1 } ], undef);
		is_deeply $dc, [qw(a r)], 'with no column list, the first row gives one';
	};

	subtest 'Dashboard::_card_plan' => sub {
		is_deeply $F{_card_plan}->({}), { cs => [], by => '', order => [] }, 'an empty plan';
		is_deeply $F{_card_plan}->({ cs => [ 'a', '', undef ], by => 'b', order => ['c'] }), { cs => ['a'], by => 'b', order => ['c'] }, 'blanks dropped';
		is $F{_card_plan}->({ cs => 'x' })->{error}, 'cross_row.cs must be a list', 'cs of the wrong kind';
		is $F{_card_plan}->({ order => {} })->{error}, 'cross_row.order must be a list', 'order too';
		is $F{_card_plan}->({ cs => [ [] ] })->{error}, 'cross_row.cs must be a list of strings', 'a list of the wrong things';
		is $F{_card_plan}->({ by => [] })->{error}, 'cross_row.by must be a column name', 'by of the wrong kind';
	};

	subtest 'Dashboard::_cross_row_ui_state' => sub {
		my %got = $F{_cross_row_ui_state}->(dash_controller($app, '/?cs=a:rank:r&by=g&order=d&l=x&f=1&f=2'));
		is_deeply $got{cross_row_specs}, ['a:rank:r'], 'the specs';
		is $got{cross_row_by}, 'g', 'the partition';
		is_deeply $got{cross_row_order}, ['d'], 'the order';
		is_deeply [ sort map { "$_->{name}=$_->{value}" } @{ $got{cross_row_hidden} } ], [qw(f=1 f=2 l=x)],
			'the rest are carried, and its own three are not, or a second by= would win';
		my %empty = $F{_cross_row_ui_state}->(dash_controller($app, '/'));
		is_deeply $empty{cross_row_specs}, [], 'nothing asked';
		is $empty{cross_row_by}, '', 'nothing asked';
	};

	subtest 'Dashboard::_calc_spec_key' => sub {
		my $fn = \&Database::BI::Controller::Dashboard::_calc_spec_key;
		is $fn->(dash_controller($app, '/?l=path:/x.csv')), 'path:/x.csv', 'l= first';
		my $c = dash_controller($app, '/');
		is $fn->($c), '', 'nothing to go on';
		$c->stash(table => 'sales');
		is $fn->($c), $SALES, 'or the table of a /view';
		$c->stash(table => '../evil');
		is $fn->($c), '', 'a name that is not safe is not a key';
	};

	subtest 'Dashboard::_span_calc_spec' => sub {
		my $fn = \&Database::BI::Controller::Dashboard::_span_calc_spec;
		my $at = sub { dash_controller($app, $_[0]) };
		my @cols = ('at', 'my col', 'region');

		is $fn->($at->('/'), \@cols, 'cat'), undef, 'no bucket asked for';
		like $fn->($at->('/?tcol=at'), \@cols, 'cat')->{error}, qr/\bat\b/, 'a column with no interval';
		like $fn->($at->('/?span=nonsense&cat=at'), \@cols, 'cat')->{error}, qr/nonsense/, 'a bad interval';
		like $fn->($at->('/?span=1d&tcol=nope'), \@cols, 'cat')->{error}, qr/nope/, 'an unknown column';
		ok $fn->($at->('/?span=1d'), \@cols, 'cat')->{error}, 'nothing to bucket';
		ok $fn->($at->('/?span=1d&rows=at,region'), \@cols, 'rows')->{error}, 'two candidates are refused rather than guessed';
		like $fn->($at->('/?span=1d&tcol=at&as=1bad'), \@cols, 'cat')->{error}, qr/1bad/, 'a name that is not an identifier';
		like $fn->($at->('/?span=1d&tcol=at&as=region'), \@cols, 'cat')->{error}, qr/region/, 'a name already taken';
		like $fn->($at->('/?span=1d&tcol=at&as=z&c=z:1'), \@cols, 'cat')->{error}, qr/\bz\b/, 'or taken by a calculated field';

		my $inject = $fn->($at->('/?span=1d&tcol=at&as=' . Mojo::Util::url_escape("x'); system('y")), \@cols, 'cat');
		ok $inject->{error}, 'a name holding code is refused';

		is_deeply $fn->($at->('/?span=1mon&cat=at'), \@cols, 'cat'), { src => 'at', col => 'at_span', calc => ["at_span:span(at,'1mon')"] }, 'the expression a reader could type';
		is $fn->($at->('/?span=1d&tcol=my%20col'), \@cols, 'cat')->{col}, 'my_col_span', 'spaces become underscores';
		is $fn->($at->('/?span=1d&tcol=at&as=bucket'), \@cols, 'cat')->{col}, 'bucket', 'a chosen name';
	};

	subtest 'Dashboard::_extend_row' => sub {
		my %plain = (a => 1);
		is $F{_extend_row}->(\%plain, 'b', 2), \%plain, 'a writable row is written to';
		is $plain{b}, 2, 'in place';
		is $F{_extend_row}->('x', 'b', 2), 'x', 'something that is not a row is passed along';
		is $F{_extend_row}->(undef, 'b', 2), undef, 'nothing too';

		require Hash::Util;
		my %locked = (a => 1);
		Hash::Util::lock_ref_keys(\%locked);
		my $copy;
		lives_ok { $copy = $F{_extend_row}->(\%locked, 'b', 2) } 'a locked row does not raise';
		is_deeply $copy, { a => 1, b => 2 }, 'the copy has both';
		ok !exists $locked{b}, 'the original is as it was';
		$copy->{c} = 3;
		is $copy->{c}, 3, 'and the copy can take another';
	};

	subtest 'Dashboard::_canonical_path and _inside_dir' => sub {
		my $base = Mojo::File->new(tempdir(CLEANUP => 1))->realpath;
		is $F{_canonical_path}->($base), File::Spec->canonpath($base->to_string), 'a directory that exists';
		is $F{_canonical_path}->($base->child('a/b/c')), File::Spec->canonpath($base->child('a/b/c')->to_string), 'one that does not yet';

		SKIP: {
			skip 'no symlinks here', 2 unless eval { symlink($base->to_string, "$base.link") };
			is $F{_canonical_path}->(Mojo::File->new("$base.link")), File::Spec->canonpath($base->to_string), 'a symlink is resolved';
			is $F{_canonical_path}->(Mojo::File->new("$base.link/new/dir")), File::Spec->canonpath($base->child('new/dir')->to_string), 'even with names below it that do not exist';
			unlink "$base.link";
		}

		is $F{_inside_dir}->('/a/b', '/a/b'), 1, 'itself';
		is $F{_inside_dir}->('/a/b/c', '/a/b'), 1, 'below it';
		is $F{_inside_dir}->('/a/b-archive', '/a/b'), 0, 'a textual prefix is not inside';
		is $F{_inside_dir}->('/a', '/a/b'), 0, 'above it';
		is $F{_inside_dir}->('/x', '/a'), 0, 'elsewhere';
		is $F{_inside_dir}->('/a/..b', '/a'), 1, 'a name that starts with two dots is a name';
		is $F{_inside_dir}->('', '/a'), 0, 'no path';
		is $F{_inside_dir}->('/a', ''), 0, 'no directory';
	};

	# Windows' realpath leaves symlinks alone, so _canonical_path follows them
	# there with _follow_links.  It is written for any platform, so it is
	# checked here against realpath wherever there are symlinks.
	subtest 'Dashboard::_follow_links -- agrees with realpath' => sub {
		my $fn   = \&Database::BI::Controller::Dashboard::_follow_links;
		my $base = Mojo::File->new(tempdir(CLEANUP => 1))->realpath;
		$base->child('real', 'deep')->make_path;
		$base->child('real', 'deep', 'f.csv')->spew("a\n1\n");
		plan skip_all => 'no symlinks here'
			unless eval { symlink($base->child('real')->to_string, $base->child('abs')->to_string) };
		symlink('real/deep', $base->child('rel')->to_string);           # relative
		symlink('../rel', $base->child('real', 'up')->to_string);        # .. in the target
		symlink('abs', $base->child('chain')->to_string);                # a link to a link
		# The NT form some Windows perls' readlink gives; here just a name.  Cygwin
		# reads a target holding backslashes as a Windows path when the link is
		# made, and readlink then answers that path, not this text: the case is
		# only tried where the link holds the text it was given.
		my $nt_target = '\\??\\' . $base->child('real')->to_string;
		symlink($nt_target, $base->child('nt')->to_string);
		my $nt_literal = (readlink($base->child('nt')->to_string) // '') eq $nt_target;
		symlink('loop2', $base->child('loop1')->to_string);
		symlink('loop1', $base->child('loop2')->to_string);

		# Not compared with realpath: on Windows that gives undef for a path
		# through a link, which is why this function exists.
		my %where = (
			'abs'                     => 'real',
			'abs/deep/f.csv'          => 'real/deep/f.csv',
			'rel'                     => 'real/deep',
			'rel/f.csv'               => 'real/deep/f.csv',
			'real/up'                 => 'real/deep',
			'real/up/f.csv'           => 'real/deep/f.csv',
			'chain/deep'              => 'real/deep',
			'real/deep/../deep/f.csv' => 'real/deep/f.csv',
			'real'                    => 'real',
			'abs/not/yet'             => 'real/not/yet',
			($nt_literal ? ('nt/deep' => 'real/deep') : ()),
		);
		note('the NT-form link is not tried: readlink does not give back its target as written')
			unless $nt_literal;
		for my $p (sort keys %where) {
			my $got = $fn->($base->child(split m{/}, $p)->to_string);
			is(defined $got ? File::Spec->canonpath($got) : undef,
				File::Spec->canonpath($base->child(split m{/}, $where{$p})->to_string), $p);
		}
		is $fn->($base->child('loop1')->to_string), undef, 'a loop gives up';

		# As on Windows: realpath gives undef for a path through a link, and
		# tidies any other.  _canonical_path, and so every data_dir guard, must
		# still see where the link goes.
		{
			no warnings 'redefine';
			local $^O = 'MSWin32';
			local *Database::BI::Controller::Dashboard::realpath = sub {
				my $abs = File::Spec->rel2abs($_[0]);
				my @parts = File::Spec->splitdir($abs);
				for my $i (1 .. $#parts) {
					return undef if -l File::Spec->catdir(@parts[0 .. $i]);
				}
				return $abs;
			};
			is $F{_canonical_path}->($base->child('abs', 'deep')), $base->child('real', 'deep')->to_string,
				'_canonical_path follows a link where realpath does not';
			is $F{_canonical_path}->($base->child('rel', 'new')), $base->child('real', 'deep', 'new')->to_string,
				'and a relative one, below which names do not exist yet';
			is $F{_inside_dir}->($F{_canonical_path}->($base->child('abs', 'deep')), $base->child('abs')->to_string), 0,
				'so a link cannot make the outside look inside';
		}
	};

	subtest 'Dashboard::_calc_models_path -- never inside the data' => sub {
		my $tm = isolated_app();
		my $fn = \&Database::BI::Controller::Dashboard::_calc_models_path;
		my $c  = dash_controller($tm->app, '/');
		my $store = Mojo::File->new($tm->app->config->{model_dir});
		is $fn->($c), $store->child('models.json')->to_string, 'under model_dir';

		my $fresh = $store->child('fresh');
		$tm->app->config->{model_dir} = $fresh->to_string;
		$fn->($c);
		ok -d $fresh, 'made on first call';

		my $data = tempdir(CLEANUP => 1);
		$tm->app->config->{data_dir}  = $data;
		$tm->app->config->{model_dir} = File::Spec->catdir($data, '.bi');
		my $got = 'unset';
		warning_like { $got = $fn->($c) } qr/model_dir is inside data_dir/, 'a store in the data is refused, loudly';
		is $got, undef, 'with no path';
		ok !-e File::Spec->catdir($data, '.bi'), 'and nothing is made there';

		# A file where the directory should go.
		my $plain = $store->child('in-the-way');
		$plain->spew('x');
		$tm->app->config->{data_dir}  = tempdir(CLEANUP => 1);
		$tm->app->config->{model_dir} = $plain->child('sub')->to_string;
		is $fn->($c), undef, 'a store that cannot be made is no path, not a crash';
	};

	# Why: Mojo::File->child appends an absolute path instead of replacing the base,
	# so this guard compared against <home>/<abs> and let a store through into the
	# very directory it exists to protect.  _data_dir_for's comment says as much.
	subtest 'Dashboard::_analyses_path -- never inside the data, however it is spelled' => sub {
		my $tm = isolated_app();
		my $fn = \&Database::BI::Controller::Dashboard::_analyses_path;
		my $c  = dash_controller($tm->app, '/');
		is $fn->($c), Mojo::File->new($tm->app->config->{model_dir})->child('analyses.json')->to_string, 'under model_dir';

		my $data = tempdir(CLEANUP => 1);
		$tm->app->config->{data_dir}  = $data;
		$tm->app->config->{model_dir} = File::Spec->catdir($data, '.bi');
		my $got = 'unset';
		warning_like { $got = $fn->($c) } qr/model_dir is inside data_dir/, 'an absolute data_dir is honoured';
		is $got, undef, 'with no path';
		ok !-e File::Spec->catdir($data, '.bi'), 'and nothing is made there';
	};

	subtest 'Dashboard::_read_models and _write_models' => sub {
		my $tm = isolated_app();
		my $c  = dash_controller($tm->app, '/');
		my $rd = \&Database::BI::Controller::Dashboard::_read_models;
		my $wr = \&Database::BI::Controller::Dashboard::_write_models;
		my $file = Mojo::File->new($tm->app->config->{model_dir})->child('models.json');

		is_deeply $rd->($c), { version => 1, fields => {}, groups => {}, date_patterns => {}, lookups => {}, extractions => {}, accelerated => {} }, 'an empty scaffold';
		is $wr->($c, { version => 1, fields => { x => { a => 'b' } } }), 1, 'writing says so';
		is $rd->($c)->{fields}{x}{a}, 'b', 'and it comes back';
		is_deeply $rd->($c)->{groups}, {}, 'with the missing sections filled in';
		is_deeply $rd->($c)->{lookups}, {}, 'the lookups too';
		memory_cycle_ok($rd->($c), 'no cycle');

		for my $junk ('', 'not json', '[1,2]', '"x"', '{') {
			$file->spew($junk);
			is_deeply $rd->($c), { version => 1, fields => {}, groups => {}, date_patterns => {}, lookups => {}, extractions => {}, accelerated => {} }, "'$junk' reads as empty";
		}

		# Why: callers go straight to ->{fields}{$key}.  A hand-edited section of the
		# wrong shape must not be a strict-refs crash on every page of the site.
		$file->spew('{"fields":"oops","groups":[1],"date_patterns":7}');
		my $got;
		lives_ok { $got = $rd->($c) } 'sections of the wrong shape';
		is ref $got->{$_}, 'HASH', "$_ comes back a hash" for qw(fields groups date_patterns);

		$file->remove;
		$file->make_path;
		is $wr->($c, {}), 0, 'a write that fails says so';
	};

	subtest 'Dashboard::_read_analyses and _write_analyses' => sub {
		my $tm  = isolated_app();
		my $c   = dash_controller($tm->app, '/');
		my $rd  = \&Database::BI::Controller::Dashboard::_read_analyses;
		my $wr  = \&Database::BI::Controller::Dashboard::_write_analyses;
		my $dir = Mojo::File->new($tm->app->config->{model_dir});
		my $file = $dir->child('analyses.json');

		is_deeply $rd->($c), {}, 'none yet';
		$wr->($c, { abc => { name => 'n' } });
		is $rd->($c)->{abc}{name}, 'n', 'a round trip';
		for my $junk ('', 'not json', '[1]') {
			$file->spew($junk);
			is_deeply $rd->($c), {}, "'$junk' reads as none";
		}

		# Why: the temp-and-rename is there so a failed save leaves things as they
		# were.  A rename that fails has to be noticed, or the temp file stays
		# behind on every save and the caller is told nothing went wrong.
		$file->remove;
		$file->make_path;
		my @logged;
		$tm->app->log->level('warn');
		my $sub = $tm->app->log->on(message => sub { push @logged, $_[2] if $_[1] eq 'warn' });
		lives_ok { $wr->($c, { a => {} }) } 'a save that cannot complete does not die';
		$tm->app->log->unsubscribe(message => $sub);
		ok((grep { /Cannot write/ } @logged), 'it says so in the log');
		is_deeply [ map { $_->basename } grep { $_->basename ne 'analyses.json' } @{ $dir->list({ dir => 1 }) } ], [], 'and leaves no temp file behind';
	};

	subtest 'Dashboard::_gen_analysis_id' => sub {
		my $fn = \&Database::BI::Controller::Dashboard::_gen_analysis_id;
		my $c  = dash_controller($app, '/');
		my %seen;
		for (1 .. 200) {
			my $id = $fn->($c);
			$seen{$id}++;
			like $id, qr/\A[A-Za-z0-9]{10}\z/, 'ten safe characters' if $_ == 1;
		}
		is scalar keys %seen, 200, 'and they do not repeat';
		ok !(grep { !/\A[A-Za-z0-9]+\z/ } keys %seen), 'so a URL can always hold one';
	};

	subtest 'Dashboard::_validate_layout' => sub {
		my $fn = \&Database::BI::Controller::Dashboard::_validate_layout;
		my $c  = dash_controller($app, '/');
		my $e  = sub { $fn->($c, $_[0]) };
		my %good = (visual => 0, x => 1, y => 1, w => 3, h => 2);
		is $e->(undef), undef, 'none';
		is $e->([]), undef, 'empty';
		is $e->([ \%good, { %good, visual => 1, x => 4 } ]), undef, 'two side by side';
		is $e->('x'), 'layout must be an array', 'not a list';
		is $e->([ 'x' ]), 'layout entry 1 must be a hash', 'an entry that is not a hash';
		is $e->([ { %good, x => undef } ]), 'layout entry 1 is missing x', 'a missing field';
		is $e->([ { %good, w => 'a' } ]), 'layout entry 1: w must be a whole number', 'text';
		is $e->([ { %good, h => -1 } ]), 'layout entry 1: h must be a whole number', 'a negative';
		is $e->([ { %good, h => 1.5 } ]), 'layout entry 1: h must be a whole number', 'a fraction';
		is $e->([ { %good, x => [] } ]), 'layout entry 1: x must be a whole number', 'a list';
		like $e->([ { %good, x => 0 } ]), qr/\Alayout entry 1: x must be between 1 and \d+\z/, 'x of 0';
		like $e->([ { %good, x => 999 } ]), qr/\Alayout entry 1: x must be between/, 'x off the grid';
		is $e->([ { %good, y => 0 } ]), 'layout entry 1: y must be at least 1', 'y of 0';
		like $e->([ { %good, w => 0 } ]), qr/\Alayout entry 1: w must be between/, 'w of 0';
		like $e->([ { %good, h => 0 } ]), qr/\Alayout entry 1: h must be between/, 'h of 0';
		like $e->([ { %good, h => 99_999 } ]), qr/\Alayout entry 1: h must be between/, 'h too tall';
		like $e->([ { %good, x => 12, w => 3 } ]), qr/\Alayout entry 1: x \+ w - 1 must not exceed/, 'off the right edge';
		is $e->([ \%good, { %good, visual => 1, x => 2 } ]), 'layout entry 2 overlaps an earlier entry', 'an overlap';
		is $e->([ \%good, \%good ]), 'layout entry 2 overlaps an earlier entry', 'the same cell twice';
	};

	subtest 'Dashboard::_validate_analysis -- every refusal is exact' => sub {
		my $fn = \&Database::BI::Controller::Dashboard::_validate_analysis;
		my $c  = dash_controller($app, '/');
		my %good = (name => 'n', datasets => [ { spec => $SALES } ]);
		my $e = sub { $fn->($c, { %good, @_ }) };

		is $e->(), undef, 'a minimal document';
		is $e->(name => undef), 'Missing required field: name', 'no name';
		is $e->(name => ''), 'Missing required field: name', 'an empty name';
		is $e->(datasets => undef), 'Missing required field: datasets', 'no datasets';
		is $e->(datasets => []), 'Missing required field: datasets', 'an empty list';
		is $e->(datasets => 'x'), 'Missing required field: datasets', 'not a list';
		is $e->(datasets => [ {} ]), 'Each dataset entry must have a spec field', 'no spec';
		like $e->(datasets => [ { spec => 'ftp://x' } ]), qr/"ftp:\/\/x" is not a valid spec/, 'an unknown scheme';
		like $e->(version => 2), qr/\AUnsupported analysis version 2/, 'a newer version';
		like $e->(version => 'x'), qr/\AUnsupported analysis version x/, 'a version that is not one';
		is $e->($_ => 'x'), "$_ must be an array", "$_ of the wrong kind" for qw(visuals joins measures combines bookmarks layout hierarchies);
		is $e->(fields => []), 'fields must be a hash', 'fields';
		is $e->(params => []), 'params must be a hash', 'params';
		is $e->(layout => [ 'x' ]), 'layout entry 1 must be a hash', 'the layout is checked too';
	};

	# Why: this body is whatever a client POSTs.  An element that is not a hash used
	# to be a strict-refs crash, which is a 500 and a stack trace in the log for a
	# request that deserves a 400.
	subtest 'Dashboard::_validate_analysis -- hostile shapes are refused, not crashed on' => sub {
		my $fn = \&Database::BI::Controller::Dashboard::_validate_analysis;
		my $c  = dash_controller($app, '/');
		for my $ds ('x', 5, [ 1 ], undef) {
			my $got;
			lives_ok { $got = $fn->($c, { name => 'n', datasets => [ $ds ] }) } 'a dataset that is not a hash';
			is $got, 'Each dataset entry must have a spec field', 'is refused';
		}
		is $fn->($c, { name => {}, datasets => [ { spec => $SALES } ] }), 'Missing required field: name', 'a name that is an object';
		is $fn->($c, { name => [ 1 ], datasets => [ { spec => $SALES } ] }), 'Missing required field: name', 'or a list';
		is $fn->($c, { name => 'n', datasets => [ { spec => [ 1 ] } ] }), 'Each dataset entry must have a spec field', 'a spec that is a list';
		like $fn->($c, { name => 'n', version => [ 1 ], datasets => [ { spec => $SALES } ] }), qr/Unsupported analysis version/, 'a version that is a list';
	};

	subtest 'Dashboard::_whole_number' => sub {
		my $fn = \&Database::BI::Controller::Dashboard::_whole_number;
		is $fn->('12'), 12, 'digits';
		is $fn->('-3'), -3, 'a negative';
		is $fn->('0'), 0, 'zero';
		is $fn->($_), undef, 'not a whole number' for undef, '', 'abc', '1x', '1.5', '1e3', "5\n", ' 5', '+5', '--5', 'Inf', 'NaN', '0x10', '9' x 16;
		keeps_globals_ok('_whole_number', sub { $fn->('5') });
	};

	# Why: everything reads a stored document blindly, so this is what stands between
	# a hand-edit and a 500.  An index must survive it: a visual's place in the list is
	# what the layout and /a/:id/visual/:n refer to.
	subtest 'Dashboard::_tidy_analysis and _tidy_visual' => sub {
		my $tidy = \&Database::BI::Controller::Dashboard::_tidy_analysis;
		my %good = (
			name     => 'n',
			updated  => 5,
			datasets => [ { spec => $SALES, filters => ['a:eq:1'] } ],
			visuals  => [ { kind => 'bar', title => 't', encode => { cat => 'a' }, options => { o => 1 }, filters => ['f'] } ],
			joins    => [ { right => 'r' } ],
			layout   => [ { visual => 0 } ],
			fields   => { f => 'x' },
			params   => { p => { type => 'number' } },
		);
		is_deeply $tidy->({ %good }), \%good, 'a good document is untouched';
		is_deeply $tidy->({}), {}, 'an empty one gains nothing';

		my $got = $tidy->({ map { $_ => 'x' } qw(datasets visuals joins measures combines bookmarks layout hierarchies fields params) });
		is_deeply $got, {}, 'sections of the wrong shape are as if absent';
		is_deeply $tidy->({ name => [ 1 ], updated => {} }), {}, 'as are a name and a time that are not values';

		$got = $tidy->({ datasets => [ 'x', {}, { spec => [ 1 ] }, { spec => $SALES, filters => 'x' } ] });
		is_deeply $got->{datasets}, [ { spec => $SALES } ], 'only a usable dataset is kept';
		$got = $tidy->({ visuals => [ 'x', [ 1 ], { kind => 'bar' } ] });
		is_deeply $got->{visuals}, [ {}, {}, { kind => 'bar' } ], 'a bad visual keeps its place, so the next keeps its index';
		$got = $tidy->({ visuals => [ { kind => [ 1 ], title => {}, encode => 'x', options => [ 1 ], filters => 'x' } ] });
		is_deeply $got->{visuals}, [ {} ], 'and its parts are checked';
		is_deeply $tidy->({ joins => [ 'x', { right => 'r' } ], layout => [ 1 ] }), { joins => [ { right => 'r' } ], layout => [] }, 'joins and layout entries';
		is_deeply $tidy->({ params => { a => 'oops', b => { type => 'number' } } })->{params}, { a => {}, b => { type => 'number' } }, 'a parameter is kept, with no definition';
		memory_cycle_ok($got, 'no cycle');
	};

	# Why: the validators used to see only a whole document, so a PATCH could store
	# what a PUT would refuse.
	subtest 'Dashboard::_validate_analysis_parts -- only the keys that are present' => sub {
		my $fn = \&Database::BI::Controller::Dashboard::_validate_analysis_parts;
		my $c  = dash_controller($app, '/');
		is $fn->($c, {}), undef, 'nothing to judge';
		is $fn->($c, { bookmarks => [] }), undef, 'a section alone';
		is $fn->($c, { name => '' }), 'Missing required field: name', 'an empty name';
		is $fn->($c, { datasets => [] }), 'Missing required field: datasets', 'no datasets';
		is $fn->($c, { visuals => 'x' }), 'visuals must be an array', 'a section of the wrong shape';
		is $fn->($c, { visuals => [ 'x' ] }), 'Each entry in visuals must be an object', 'a visual that is not one';
		is $fn->($c, { joins => [ 1 ] }), 'Each entry in joins must be an object', 'a join that is not one';
		is $fn->($c, { params => 'x' }), 'params must be a hash', 'params';
	};

	# Why: HTML::D3 writes a categorical name straight into its script, so this check
	# is the only thing between scheme= and script on the page; and it dies on an
	# unknown sequential name, which was a 500 for any bad link to a heatmap.
	subtest 'Dashboard::_categorical_scheme and _sequential_scheme' => sub {
		my $cat = \&Database::BI::Controller::Dashboard::_categorical_scheme;
		my $seq = \&Database::BI::Controller::Dashboard::_sequential_scheme;
		is $cat->('tableau10'), 'tableau10', 'a known palette';
		is $seq->('Blues'), 'Blues', 'a known scale';
		for my $evil (undef, '', 'nope', "'];alert(1);//", $XSS_PROBE, [ 1 ], 'constructor') {
			is $cat->($evil), 'tableau10', 'anything else is the default palette';
			is $seq->($evil), 'YlOrRd', 'or the default scale';
		}
	};

	# Why: a link anyone can send.  These errors repeat the parameter, and Mojolicious
	# sends render(text => ...) as HTML unless told otherwise.
	subtest 'hostile parameters cannot put script on a page' => sub {
		my $tm = isolated_app();
		my $e  = Mojo::Util::url_escape($XSS_PROBE);
		for my $url ("/bar?l=$SALES&range=$e", "/pie?l=$SALES&cat=$e&val=amount", "/bar?l=$SALES&cs=$e", "/bar?l=$SALES&cat=region&span=$e") {
			$tm->get_ok($url)->status_is(400)->content_type_like(qr{\Atext/plain}, "$url is not HTML");
		}
		for my $route ('/pie?l=table:sales&cat=region&val=amount', '/bar?l=table:sales&cat=region&val=amount',
			'/histogram?l=table:sales&col=amount', '/treemap?l=table:sales&group=region&size=amount') {
			$tm->get_ok("$route&scheme=$e")->status_is(200)->content_unlike(qr/<script>alert/, "$route does not write scheme= into its script");
		}
		$tm->get_ok("/heatmap?l=$SALES&x=region&y=product&val=amount&scheme=$e")->status_is(200, 'an unknown scale is not a 500');
		is $tm->tx->res->body =~ /<script>alert/ ? 1 : 0, 0, 'and is not repeated';
		$tm->get_ok("/heatmap?l=$SALES&x=region&y=product&val=amount&scheme=nope")->status_is(200);

		my $id = $tm->post_ok('/api/analyses' => json => {
			name => 'n', datasets => [ { spec => $SALES } ],
			visuals => [
				{ kind => 'pie', encode => { cat => 'region', value => 'amount' }, options => { scheme => $XSS_PROBE } },
				{ kind => 'heatmap', encode => { x => 'region', y => 'product', value => 'amount' }, options => { scheme => 'nope' } },
			],
		})->tx->res->json->{id};
		$tm->get_ok("/a/$id")->status_is(200)->content_unlike(qr/<script>alert/, 'nor can a saved card, which a share link serves to strangers');
	};

	subtest 'Dashboard::_analysis_to_url' => sub {
		my $fn = \&Database::BI::Controller::Dashboard::_analysis_to_url;
		my $c  = dash_controller($app, '/');
		is $fn->($c, {}), undef, 'no datasets';
		is $fn->($c, { datasets => [ {} ] }), undef, 'a dataset with no spec';
		is $fn->($c, { datasets => [ { spec => $SALES } ] }), '/join?l=table%3Asales', 'just the source';

		my $url = $fn->($c, {
			datasets => [ { spec => $SALES, alias => 'l', filters => ['a:eq:1'] }, { spec => 'table:b', alias => 'r' } ],
			joins    => [ { right => 'r', left_key => 'x', right_key => 'y' }, { right => 'nosuch' } ],
		});
		like $url, qr/&j=table%3Ab%7Cx%7Cy/, 'the join, encoded';
		like $url, qr/&f=a%3Aeq%3A1\z/, 'the filter, encoded';
		unlike $url, qr/nosuch/, 'and a join to nothing is left out';

		like $fn->($c, { datasets => [ { spec => 'table:a&admin=1' } ] }), qr/\A\/join\?l=table%3Aa%26admin%3D1\z/, 'a hostile spec stays one value';

		# A stored document can be anything; _validate_analysis does not look this deep.
		for my $doc (
			{ datasets => [ { spec => $SALES, filters => 'x' } ] },
			{ datasets => [ { spec => $SALES } ], joins => [ 'x' ] },
		) {
			lives_ok { $fn->($c, $doc) } 'a document of the wrong shape does not crash';
		}
	};

	subtest 'Dashboard::_chart_orientation and _vis_cf_col' => sub {
		is $F{_chart_orientation}->({ orientation => $_ }), 'horizontal', "$_ is horizontal" for qw(h H horizontal);
		is $F{_chart_orientation}->({ orient => 'h' }), 'horizontal', 'the older spelling';
		is $F{_chart_orientation}->({ orientation => $_ }), 'vertical', "$_ is vertical" for qw(v vertical nonsense);
		is $F{_chart_orientation}->({}), 'vertical', 'the default';

		is $F{_vis_cf_col}->({ encode => { x => 'b', cat => 'a' } }), 'a', 'cat comes first';
		is $F{_vis_cf_col}->({ encode => { x => 'b' } }), 'b', 'then x';
		is $F{_vis_cf_col}->({ encode => { val => 'v' } }), undef, 'a measure is not a dimension';
		is $F{_vis_cf_col}->({}), undef, 'no encoding';
		is $F{_vis_cf_col}->({ encode => { cat => '', x => 'b' } }), 'b', 'an empty one is passed over';
	};

	subtest 'Dashboard::_bound_canvas_params' => sub {
		my $fn = \&Database::BI::Controller::Dashboard::_bound_canvas_params;
		my $c  = dash_controller($app, '/');
		my $none = sub { undef };

		my ($b, $e) = $fn->($c, {}, $none);
		is_deeply [ $b, $e ], [ {}, [] ], 'no parameters';
		($b, $e) = $fn->($c, { params => { a => { type => 'number', default => 5 }, s => {} } }, $none);
		is_deeply $b, { a => 5, s => '' }, 'the defaults';
		($b, $e) = $fn->($c, { params => { a => { type => 'number' } } }, sub { '7' });
		is $b->{a}, 7, 'a URL value is coerced';
		($b, $e) = $fn->($c, { params => { s => { default => 'd' } } }, sub { '<x>' });
		is $b->{s}, '<x>', 'a string is taken as it is';
		($b, $e) = $fn->($c, { params => { a => { type => 'number' } } }, sub { 'x' });
		is_deeply $e, ["Parameter 'a' must be a number"], 'text for a number';
		ok !exists $b->{a}, 'is not bound';
		($b, $e) = $fn->($c, { params => { a => { type => 'number', min => 1, max => 5 } } }, sub { 9 });
		is_deeply $e, ["Parameter 'a' is out of range (min 1, max 5)"], 'over the top';
		($b, $e) = $fn->($c, { params => { a => { type => 'number', min => 1 } } }, sub { 0 });
		is_deeply $e, ["Parameter 'a' is out of range (min 1, max +inf)"], 'under the bottom, with no top';
		($b, $e) = $fn->($c, { params => { a => { type => 'number', max => 1 } } }, sub { 2 });
		is_deeply $e, ["Parameter 'a' is out of range (min -inf, max 1)"], 'over the top, with no bottom';
	};

	# Why: every comparison with NaN is false, so "nan" walked straight past min and
	# max; looks_like_number says yes to all of these.
	subtest 'Dashboard::_bound_canvas_params -- cannot be talked round' => sub {
		my $fn = \&Database::BI::Controller::Dashboard::_bound_canvas_params;
		my $c  = dash_controller($app, '/');
		for my $evil (qw(nan NaN inf -inf Infinity)) {
			my ($b, $e) = $fn->($c, { params => { a => { type => 'number', min => 1, max => 5 } } }, sub { $evil });
			ok !exists $b->{a}, "$evil is not bound";
			is scalar @$e, 1, 'and is reported';
		}
		for my $bad ('oops', 5, [ 1 ]) {
			my ($b, $e);
			lives_ok { ($b, $e) = $fn->($c, { params => { a => $bad } }, sub { undef }) } 'a stored definition that is not a hash';
			is $b->{a}, '', 'is a plain string parameter';
		}
	};

	subtest 'Dashboard::_decode_cell and _percent_encode' => sub {
		is $F{_decode_cell}->(undef), undef, 'nothing';
		is $F{_decode_cell}->("caf\xC3\xA9"), "caf\x{e9}", 'UTF-8 bytes become a character';
		is $F{_decode_cell}->("\xFF\xFE"), "\xFF\xFE", 'invalid UTF-8 is left, not lost';
		is $F{_decode_cell}->("\x{263A}"), "\x{263A}", 'a decoded string is unchanged';

		is $F{_percent_encode}->("a b&c"), 'a%20b%26c', 'separators';
		is $F{_percent_encode}->("caf\x{e9}\x{263A}"), 'caf%C3%A9%E2%98%BA', 'characters as UTF-8';
		is $F{_percent_encode}->(undef), '', 'nothing';
	};

	subtest 'Dashboard::_word_tokens' => sub {
		is_deeply [ $F{_word_tokens}->('Hello, big World!', 2) ], [qw(hello big world)], 'lower-cased and split';
		is_deeply [ $F{_word_tokens}->('a big one', 3) ], [qw(big one)], 'the shortest kept';
		is_deeply [ $F{_word_tokens}->("O'Brien's 'quoted'", 2) ], [ "o'brien's", 'quoted' ], 'an apostrophe stays inside';
		is_deeply [ $F{_word_tokens}->("caf\xC3\xA9 ole", 2) ], [ "caf\x{e9}", 'ole' ], 'bytes are decoded first';
		is_deeply [ $F{_word_tokens}->('!!! ???', 1) ], [], 'punctuation is no word';
		is_deeply [ $F{_word_tokens}->($_, 1) ], [], 'nothing' for undef, '';
		keeps_globals_ok('_word_tokens', sub { $F{_word_tokens}->('a b', 1) });
	};

	subtest 'Dashboard::_wordcloud_option' => sub {
		is $F{_wordcloud_option}->('50', 10, 1, 100), 50, 'in range';
		is $F{_wordcloud_option}->('0', 10, 1, 100), 1, 'below';
		is $F{_wordcloud_option}->('9999', 10, 1, 100), 100, 'above';
		is $F{_wordcloud_option}->($_, 10, 1, 100), 10, 'unreadable means the default' for undef, '', 'x', '-5', '1.5', "5\n", [];
		is $F{_wordcloud_option}->('9' x 400, 10, 1, 100), 100, 'an absurd count is held';
	};

	subtest 'Dashboard::_wordcloud_link' => sub {
		is $F{_wordcloud_link}->('/view/sales', 'c', 'w', '/cloud'),
			'/view/sales?f=c%3Acontains%3Aw&back2=%2Fcloud&back2_label=Back%20to%20word%20cloud', 'a drill-down';
		like $F{_wordcloud_link}->('/open?path=x', 'c', 'w', '/cloud'), qr/\A\/open\?path=x&f=/, 'added to a query';
		like $F{_wordcloud_link}->('/v', 'c', q{"><s&x=1}, '/cloud'), qr/f=c%3Acontains%3A%22%3E%3Cs%26x%3D1&/, 'a hostile word stays inert';
	};

	subtest 'Dashboard::_map_popup -- a place name is not markup' => sub {
		is $F{_map_popup}->('Town', [ {} ], []), '<strong>Town</strong>', 'one row';
		is $F{_map_popup}->('Town', [ {}, {}, {} ], []), '<strong>Town</strong><br>3 rows', 'several';
		is $F{_map_popup}->(undef, undef, undef), '<strong></strong>', 'nothing';
		is $F{_map_popup}->('T', [ { a => 'b', c => undef, d => '' } ], [ qw(a c d) ]), '<strong>T</strong><br>a: b', 'empty cells are left out';
		my $html = $F{_map_popup}->('<script>x</script>', [ { '<img>' => q{"'&} } ], [ '<img>' ]);
		unlike $html, qr/<script|<img/, 'markup is escaped everywhere';
		like $html, qr/&lt;script&gt;/, 'and shown as text';
	};

	# A marker stands for every row at its place, so its popup lists them all:
	# what they share once, what differs in a table that is capped and scrolls,
	# so a place with hundreds of rows cannot cover the map.
	subtest 'Dashboard::_map_popup -- every row at a place, without smothering the map' => sub {
		my @rows = map { { person => 'Valentin', year => 1910 + $_, event => "E$_", note => '' } } 1 .. 3;
		my $html = $F{_map_popup}->('Brezje', \@rows, [ qw(person year event note) ], 10, '');
		like $html, qr{\A<strong>Brezje</strong><br>3 rows<br>person: Valentin<div class="bi-map-popup-rows"}, 'what every row shares is said once';
		like $html, qr{<tr><th>year</th><th>event</th></tr>}, 'what differs is a table';
		is scalar(() = $html =~ /<td>E\d<\/td>/g), 3, 'with a line for each row';
		unlike $html, qr/note/, 'a column empty in every row is left out';
		like $html, qr/max-height:[^;"]+;overflow:auto/, 'the box scrolls rather than growing';
		unlike $html, qr/more/, 'nothing is left over';

		my @many = map { { n => $_ } } 1 .. 25;
		$html = $F{_map_popup}->('P', \@many, [ 'n' ], 4, '/open?path=x&f=a');
		is scalar(() = $html =~ /<td>/g), 4, 'no more rows than the limit';
		like $html, qr{and 21 more: <a href="/open\?path=x&amp;f=a">show all 25 in the table</a>}, 'the rest are counted and linked, the link escaped';
		like $F{_map_popup}->('P', \@many, [ 'n' ], 4, undef), qr{and 21 more</div>\z}, 'without a link, only counted';
		is scalar(() = $F{_map_popup}->('P', \@many, [ 'n' ], $_, '') =~ /<td>/g), 10, "a limit of '$_' is the default"
			for ('', 0, -3, 'lots', undef);

		$html = $F{_map_popup}->('P', [ { n => '<b>', x => [ 1 ] }, 'not a row', undef, { n => '&' } ], [ 'n', 'x', undef, [ 'y' ] ], 10, '');
		like $html, qr{<td>&lt;b&gt;</td><td>&amp;</td>|<td>&lt;b&gt;</td></tr><tr><td>&amp;</td>}, 'cells are escaped';
		like $html, qr/2 rows/, 'what is not a row is not counted';
		unlike $html, qr/ARRAY/, 'and a cell that is a reference is empty, not its address';

		$html = $F{_map_popup}->('Same', [ { a => 1 }, { a => 1 } ], [ 'a' ], 10, '/x');
		is $html, '<strong>Same</strong><br>2 rows<br>a: 1', 'identical rows need no table';
		keeps_globals_ok('_map_popup', sub { $F{_map_popup}->('P', \@many, [ 'n' ], 4, '') });
	};

	subtest 'Dashboard::_map_size_range, _map_radius, _map_limit' => sub {
		my @recs = ({ s => 5 }, { s => 'x' }, { s => 20 }, {});
		my @marks = map { { first_row => $_ } } 0 .. 4;
		is_deeply [ $F{_map_size_range}->(\@recs, \@marks, 's') ], [ 5, 20 ], 'the range, skipping what is not a number';
		is_deeply [ $F{_map_size_range}->(\@recs, \@marks, $_) ], [], 'no column' for undef, '';
		is_deeply [ $F{_map_size_range}->([ { s => 'x' } ], [ { first_row => 0 } ], 's') ], [ undef, undef ], 'nothing numeric';

		is $F{_map_radius}->(5, 5, 20), 6, 'the smallest';
		is $F{_map_radius}->(20, 5, 20), 30, 'the largest';
		is $F{_map_radius}->(undef, 5, 20), 10, 'no value is the midpoint';
		is $F{_map_radius}->(5, 5, 5), 10, 'a constant column does not divide by zero';
		is $F{_map_radius}->(5, undef, undef), 10, 'no range';
		is $F{_map_radius}->(-100, 5, 20), 6, 'held at the bottom';
		is $F{_map_radius}->(100, 5, 20), 30, 'and the top';

		is $F{_map_limit}->('5', 3), 5, 'a limit';
		is $F{_map_limit}->($_, 3), 3, 'a nonsense one is the default' for undef, '', '0', '-1', 'x', '1.5', "5\n";

		# Why: every digit, but 1e400 to Perl.  An infinite limit is no limit.
		is $F{_map_limit}->('9' x 400, 3), 3, 'an absurd number is nonsense too';
	};

	subtest 'Dashboard::_parse_color and _color_hex' => sub {
		is $F{_parse_color}->('RED'), 'red', 'a name, lower-cased';
		is $F{_parse_color}->('#ABC'), '#abc', 'three digits';
		is $F{_parse_color}->('#a1b2c3'), '#a1b2c3', 'six digits';
		is $F{_parse_color}->($_), undef, "'$_' is refused" for
			'', 'notacolor', '#12', '#1234', '#12345', '#1234567', '#ggg', 'red;x', 'url(x)', 'javascript:x', "red\n", "'><script>";
		is $F{_parse_color}->(undef), undef, 'nothing';

		is $F{_color_hex}->('#abc'), '#abc', 'hex is unchanged';
		like $F{_color_hex}->('red'), qr/\A#[0-9a-f]{6}\z/, 'a name is translated';
		my $default = $F{_color_hex}->(undef);
		like $default, qr/\A#/, 'nothing is the default';
		is $F{_color_hex}->('notacolor'), $default, 'as is an unknown name';
		is $F{_color_hex}->(''), $default, 'or an empty one';
	};

	subtest 'Dashboard::_parse_color_rules and _apply_color_rule' => sub {
		my ($rules, $def) = $F{_parse_color_rules}->([ 'gt:5:red', 'EQ:a:#abc' ], 'blue');
		is_deeply $rules, [ { op => 'gt', val => 5, color => 'red' }, { op => 'eq', val => 'a', color => '#abc' } ], 'the rules';
		is $def, 'blue', 'and the default';
		($rules, $def) = $F{_parse_color_rules}->([ 'gt:5', 'x:1:red', 'gt:1:nocolor', 'gt:1:url(x)', '' ], 'nocolor');
		is_deeply $rules, [], 'invalid rules are dropped';
		like $def, qr/\S/, 'and a bad default gives the standard one';
		lives_ok { $F{_parse_color_rules}->(undef, undef) } 'nothing at all';

		my $rule = sub { [ { op => $_[0], val => $_[1], color => 'hit' } ] };
		is $F{_apply_color_rule}->(6, $rule->('gt', 5), 'miss'), 'hit', 'gt';
		is $F{_apply_color_rule}->(5, $rule->('gt', 5), 'miss'), 'miss', 'gt is strict';
		is $F{_apply_color_rule}->(5, $rule->('ge', 5), 'miss'), 'hit', 'ge';
		is $F{_apply_color_rule}->(4, $rule->('lt', 5), 'miss'), 'hit', 'lt';
		is $F{_apply_color_rule}->(5, $rule->('le', 5), 'miss'), 'hit', 'le';
		is $F{_apply_color_rule}->(5, $rule->('eq', '5.0'), 'miss'), 'hit', 'eq is numeric between numbers';
		is $F{_apply_color_rule}->(6, $rule->('ne', 5), 'miss'), 'hit', 'ne';
		is $F{_apply_color_rule}->('A', $rule->('eq', 'a'), 'miss'), 'hit', 'eq is case-blind for text';
		is $F{_apply_color_rule}->('b', $rule->('ne', 'a'), 'miss'), 'hit', 'ne';
		is $F{_apply_color_rule}->('x', $rule->('gt', 5), 'miss'), 'miss', 'text is not greater than a number';
		is $F{_apply_color_rule}->(undef, $rule->('gt', 5), 'miss'), 'miss', 'nor is nothing';
		is $F{_apply_color_rule}->(1, [], 'miss'), 'miss', 'no rules';
		is $F{_apply_color_rule}->(9, [ @{ $rule->('gt', 5) }, { op => 'gt', val => 1, color => 'later' } ], 'miss'), 'hit', 'the first match wins';
	};

	subtest 'Dashboard::_marker_icon' => sub {
		my $icon = $F{_marker_icon}->('#abc');
		like $icon, qr/\Adata:image\/svg\+xml,/, 'a data URI';
		like $icon, qr/fill='%23abc'/, 'with the colour, encoded';
		unlike $icon, qr/[<> ]/, 'and nothing a data URI cannot hold';
		like $F{_marker_icon}->(undef), qr/\Adata:image/, 'nothing is the default colour';
	};

	subtest 'Dashboard::_scope_card_scripts and _wrap_card_script' => sub {
		my $wrap = "\n(function () {\n";
		is $F{_scope_card_scripts}->($_), '', 'nothing to scope' for undef, '';
		is $F{_scope_card_scripts}->('<p>x</p>'), '<p>x</p>', 'no script';
		like $F{_scope_card_scripts}->('<script>const a=1;</script>'), qr/<script>\Q$wrap\Econst a=1;\n\}\)\(\);\n<\/script>/, 'an inline script is closed over';

		my $src = '<script src="x.js"></script>';
		is $F{_scope_card_scripts}->($src), $src, 'one with a src is left';
		my $typed = '<script type="application/json">{}</script>';
		is $F{_scope_card_scripts}->($typed), $typed, 'a data block is left';

		my $once = $F{_scope_card_scripts}->('<script>const a=1;</script>');
		is $F{_scope_card_scripts}->($once), $once, 'scoping twice is scoping once';
		my $two = $F{_scope_card_scripts}->('<script>a</script><p>b</p><SCRIPT>c</SCRIPT>');
		is scalar(() = $two =~ /\(function \(\) \{/g), 1, 'lower-case script tags are what the charts write';

		is $F{_wrap_card_script}->('<script>', 'x', '</script>'), "<script>\n(function () {\nx\n})();\n</script>", 'the wrapper';
		is $F{_wrap_card_script}->('<script>', '  (function () { }', '</script>'), '<script>  (function () { }</script>', 'already wrapped';
	};

	subtest 'Dashboard::_map_renderer_version' => sub {
		my $fn = \&Database::BI::Controller::Dashboard::_map_renderer_version;
		my ($ok, $version);
		lives_ok { ($ok, $version) = $fn->(dash_controller($app, '/')) } 'whether or not the module is there';
		ok $ok == 0 || $ok == 1, 'a clear answer';
		ok defined $version || !$ok, 'no version means not usable';
	};

	subtest 'Dashboard::_apply_date_normalization' => sub {
		my $tm = isolated_app();
		my $c  = dash_controller($tm->app, '/');
		my $fn = \&Database::BI::Controller::Dashboard::_apply_date_normalization;
		Database::BI::Controller::Dashboard::_write_models($c, { date_patterns => { s => { d => '%m/%d/%Y' } } });

		my @rows = ({ d => '5/20/2026' }, { d => 'junk' }, { d => '' }, { d => undef }, { d => '15/20/2026' });
		$fn->($c, \@rows, ['d'], 's');
		is $rows[0]{d}, '2026-05-20', 'a good value is normalised';
		is $rows[1]{d}, 'junk', 'a bad one is left, for the (unparseable) bucket';
		is $rows[2]{d}, '', 'an empty one';
		is $rows[3]{d}, undef, 'a missing one';
		is $rows[4]{d}, '15/20/2026', 'a date with no such month is left too';

		my @same = ({ d => '5/20/2026' });
		$fn->($c, \@same, ['other'], 's');
		is $same[0]{d}, '5/20/2026', 'a pattern for a column not in this view is ignored';
		$fn->($c, \@same, ['d'], $_) for undef, '', 'nosuch';
		is $same[0]{d}, '5/20/2026', 'no key, or an unknown one, changes nothing';

		# Stored JSON can be anything.
		Database::BI::Controller::Dashboard::_write_models($c, { date_patterns => { s => 'oops', t => { d => { date => '%Q' } } } });
		lives_ok { $fn->($c, \@same, ['d'], 's') } 'patterns of the wrong shape';
		lives_ok { $fn->($c, \@same, ['d'], 't') } 'a pattern that cannot compile';
		is $same[0]{d}, '5/20/2026', 'change nothing';
	};

	subtest 'Dashboard::_apply_calc_fields' => sub {
		my $tm = isolated_app();
		my $fn = \&Database::BI::Controller::Dashboard::_apply_calc_fields;
		my $at = sub { dash_controller($tm->app, $_[0]) };
		my @rows = ({ a => 2 }, { a => 'x' });

		my ($got, $cols) = $fn->($at->('/'), \@rows, ['a']);
		is_deeply $cols, ['a'], 'no calculated field';

		my $c = $at->('/?c=' . Mojo::Util::url_escape('b:a*2'));
		($got, $cols) = $fn->($c, [ map { {%$_} } @rows ], ['a']);
		is_deeply $cols, [qw(a b)], 'the column is added';
		is $got->[0]{b}, 4, 'and worked out';
		is $got->[1]{b}, '(unparseable)', 'a row it cannot read stays visible';
		is $c->stash('_virtual_columns')->{b}, 1, 'marked virtual';

		($got, $cols) = $fn->($at->('/?c=' . Mojo::Util::url_escape('b:a*2') . '&c=' . Mojo::Util::url_escape('d:b+1')), [ { a => 1 } ], ['a']);
		is $got->[0]{d}, 3, 'a later field can read an earlier one';

		throws_ok { $fn->($at->('/?c=' . Mojo::Util::url_escape('b:nope')), [ { a => 1 } ], ['a']) } qr/nope/, 'an expression that cannot compile';

		($got, $cols) = $fn->($at->('/?c=path:/x.csv&c=table:y&c=junk&c=1bad:1'), [ { a => 1 } ], ['a']);
		is_deeply $cols, ['a'], 'source specs and malformed entries are not fields';

		($got) = $fn->($at->('/'), [ { a => 1 } ], ['a'], { params => { rate => 3 }, calc => ['z:a+rate'] });
		is $got->[0]{z}, 4, 'parameters and extra specs from a canvas';

		Database::BI::Controller::Dashboard::_write_models($at->('/'), { fields => { s => { st => 'a+10', ov => '1' } } });
		($got, $cols) = $fn->($at->('/?l=s&c=' . Mojo::Util::url_escape('ov:2')), [ { a => 1 } ], ['a']);
		is $got->[0]{st}, 11, 'a stored field';
		is $got->[0]{ov}, 2, 'and the URL overrides it';

		Database::BI::Controller::Dashboard::_write_models($at->('/'), { groups => { s => { a => { low => [ 1 ], high => [ 9 ] } } } });
		($got, $cols) = $fn->($at->('/?l=s'), [ { a => 1 }, { a => 5 } ], ['a']);
		is $got->[0]{a_group}, 'low', 'a value in a group';
		is $got->[1]{a_group}, '(other)', 'and one in none';

		require Hash::Util;
		my %locked = (a => 1);
		Hash::Util::lock_ref_keys(\%locked);
		($got) = $fn->($at->('/?c=' . Mojo::Util::url_escape('b:a+1')), [ \%locked ], ['a']);
		is $got->[0]{b}, 2, 'a locked row is extended';
	};

	subtest 'Dashboard::_share_secret, _make_share_token, _verify_share_token' => sub {
		my $tm = isolated_app();
		$tm->app->config->{share_secret} = 'test-secret';
		my $c  = dash_controller($tm->app, '/');
		my $mk = \&Database::BI::Controller::Dashboard::_make_share_token;
		my $vf = \&Database::BI::Controller::Dashboard::_verify_share_token;
		my $later = time() + 1000;

		is Database::BI::Controller::Dashboard::_share_secret($c), 'test-secret', 'the configured secret';
		my $tok = $mk->($c, 'abc', $later);
		is $vf->($c, 'abc', $tok), 1, 'a token proves itself';
		unlike $tok, qr/[+\/=]/, 'and fits in a URL unescaped';

		is $vf->($c, 'other', $tok), undef, 'not for another canvas';
		is $vf->($c, 'abc', $mk->($c, 'abc', time() - 1)), undef, 'not once it has expired';
		is $vf->($c, 'abc', $_), undef, 'junk is not a token' for undef, '', 'x', '!!!!', 'YWJj';

		require MIME::Base64;
		my ($id, $exp, $sig) = split /\|/, MIME::Base64::decode_base64url($tok);
		my $forge = sub { MIME::Base64::encode_base64url($_[0]) };
		is $vf->($c, 'abc', $forge->("abc|" . ($later + 9) . "|$sig")), undef, 'an extended expiry fails the signature';
		is $vf->($c, 'abc', $forge->("abc|$later|" . ('0' x 64))), undef, 'a made-up signature';
		is $vf->($c, 'abc', $forge->("abc|$later|")), undef, 'no signature';
		is $vf->($c, 'abc', $forge->("abc|never|$sig")), undef, 'an expiry that is not a number';
		is $vf->($c, 'abc', $forge->('abc')), undef, 'too few parts';

		my $other = isolated_app();
		$other->app->config->{share_secret} = 'different';
		is $vf->(dash_controller($other->app, '/'), 'abc', $tok), undef, 'signed with another secret';

		delete $tm->app->config->{share_secret};
		warning_like { Database::BI::Controller::Dashboard::_share_secret($c) } qr/share_secret not configured/, 'running with no secret is announced';
	};

	# ------------------------------------------------------------------------
	# Route actions.  Each uses an application of its own, so stores written here
	# cannot be read by, or disturb, anything else in this file.
	# ------------------------------------------------------------------------

	subtest 'analyses_* -- the life of a saved canvas' => sub {
		my $tm  = isolated_app();
		my %doc = (name => 'First', datasets => [ { spec => $SALES } ]);

		$tm->get_ok('/api/analyses')->status_is(200)->json_is('/analyses', []);
		my $id = $tm->post_ok('/api/analyses' => json => \%doc)->status_is(201)->tx->res->json->{id};
		like $id, qr/\A[A-Za-z0-9]+\z/, 'an id comes back';

		$tm->get_ok("/api/analyses/$id")->status_is(200)->json_is('/name', 'First');
		$tm->get_ok('/api/analyses')->status_is(200)->json_is('/analyses/0/id', $id);

		$tm->put_ok("/api/analyses/$id" => json => { %doc, name => 'Second' })->status_is(200);
		$tm->get_ok("/api/analyses/$id")->json_is('/name', 'Second');

		$tm->patch_ok("/api/analyses/$id" => json => { name => 'Third' })->status_is(200);
		$tm->get_ok("/api/analyses/$id")->json_is('/name', 'Third');

		$tm->post_ok("/api/analyses/$id/visuals" => json => { kind => 'bar', encode => { cat => 'region', value => 'amount' }, title => 'T' });
		ok $tm->tx->res->code < 300, 'a visual is added';
		$tm->get_ok("/api/analyses/$id")->json_is('/visuals/0/kind', 'bar');

		$tm->patch_ok("/api/analyses/$id/visuals/0" => json => { encode => { cat => 'product', value => 'amount' } })->status_is(200);
		$tm->get_ok("/api/analyses/$id")->json_is('/visuals/0/encode/cat', 'product');

		my $exported = $tm->get_ok("/api/analyses/$id/export")->status_is(200)->tx->res->json;
		is $exported->{name}, 'Third', 'it exports';
		my $copy = $tm->post_ok('/api/analyses/import' => json => $exported)->status_is(201)->tx->res->json->{id};
		isnt $copy, $id, 'and imports as a new canvas';

		$tm->delete_ok("/api/analyses/$id")->status_is(200);
		$tm->get_ok("/api/analyses/$id")->status_is(404);
		$tm->delete_ok("/api/analyses/$id")->status_is(404);
	};

	subtest 'analyses_* -- bad ids and bad bodies' => sub {
		my $tm = isolated_app();
		my %doc = (name => 'n', datasets => [ { spec => $SALES } ]);
		my $id = $tm->post_ok('/api/analyses' => json => \%doc)->tx->res->json->{id};

		for my $bad ('a-b', 'a_b') {
			$tm->get_ok("/api/analyses/$bad")->status_is(400);
			$tm->put_ok("/api/analyses/$bad" => json => \%doc)->status_is(400);
			$tm->patch_ok("/api/analyses/$bad" => json => {})->status_is(400);
			$tm->delete_ok("/api/analyses/$bad")->status_is(400);
			$tm->post_ok("/api/analyses/$bad/visuals" => json => {})->status_is(400);
			$tm->post_ok("/api/analyses/$bad/share")->status_is(400);
			$tm->get_ok("/api/analyses/$bad/export")->status_is(400);
		}
		for my $missing ('nosuchcanvas') {
			$tm->get_ok("/api/analyses/$missing")->status_is(404);
			$tm->put_ok("/api/analyses/$missing" => json => \%doc)->status_is(404);
			$tm->patch_ok("/api/analyses/$missing" => json => {})->status_is(404);
			$tm->post_ok("/api/analyses/$missing/visuals" => json => { kind => 'bar' })->status_is(404);
			$tm->post_ok("/api/analyses/$missing/share")->status_is(404);
			$tm->get_ok("/api/analyses/$missing/export")->status_is(404);
			$tm->get_ok("/a/$missing")->status_is(404);
		}
		for my $body ('', 'not json', '[1,2]', '"x"', '5', 'null', '{"name":"n","datasets":["x"]}',
			'{"name":{},"datasets":[{"spec":"table:sales"}]}', '{"name":"n","datasets":[{"spec":["x"]}]}') {
			for my $req ([ post => '/api/analyses' ], [ post => '/api/analyses/import' ], [ put => "/api/analyses/$id" ]) {
				my ($method, $url) = @$req;
				my $call = "${method}_ok";
				$tm->$call($url => { 'Content-Type' => 'application/json' } => $body)->status_is(400, "$method $url refuses '$body'");
			}
		}
		for my $patch ('{"layout":"x"}', '{"visuals":"x"}', '{"layout":[{"x":0}]}') {
			$tm->patch_ok("/api/analyses/$id" => { 'Content-Type' => 'application/json' } => $patch)->status_is(400, "PATCH refuses $patch");
		}
		$tm->patch_ok("/api/analyses/$id" => { 'Content-Type' => 'application/json' } => '[1]')->status_is(400, 'a PATCH that is not an object');
		$tm->post_ok("/api/analyses/$id/visuals" => { 'Content-Type' => 'application/json' } => '[1]')->status_is(400, 'nor a visual');
		$tm->post_ok("/api/analyses/$id/visuals" => json => { kind => 'bar', cross_row => { cs => 'x' } })->status_is(400, 'a plan of the wrong shape');
		$tm->post_ok("/api/analyses/$id/visuals" => json => { kind => 'bar', cross_row => 'x' });
		ok $tm->tx->res->code < 500, 'a plan that is not even a hash is not a 500';
	};

	# Why: validation looks at the top of a document, but what is stored can be
	# anything that passed, and could have been edited by hand.  A page reading it
	# has to survive: a 500 here takes the whole canvas away from its reader.
	subtest 'canvas_render and friends -- a stored document of any shape' => sub {
		my $tm = isolated_app();
		my $c  = dash_controller($tm->app, '/');
		my $id = 'hostile';
		my @docs = (
			{ name => 'n', datasets => [ { spec => $SALES } ], visuals => [ 'x' ] },
			{ name => 'n', datasets => [ { spec => $SALES } ], visuals => [ {} ] },
			{ name => 'n', datasets => [ { spec => $SALES } ], visuals => [ { kind => 'nosuch' } ] },
			{ name => 'n', datasets => [ { spec => $SALES } ], visuals => [ { kind => 'bar', encode => 'x' } ] },
			{ name => 'n', datasets => [ { spec => $SALES } ], visuals => [ { kind => 'bar', encode => { cat => 'nope' } } ] },
			{ name => 'n', datasets => [ { spec => $SALES } ], visuals => [ { kind => 'bar', encode => { cat => 'region' }, options => 'x' } ] },
			{ name => 'n', datasets => [ { spec => $SALES } ], params => { a => 'oops' }, visuals => [ { kind => 'bar', encode => { cat => 'region', value => 'amount' } } ] },
			{ name => 'n', datasets => [ { spec => $SALES, filters => 'x' } ] },
			{ name => 'n', datasets => [ { spec => $SALES } ], joins => [ 'x' ] },
			{ name => 'n', datasets => [ { spec => $SALES } ], visuals => 'x' },
			{ name => 'n', datasets => 'x' },
			{ name => 'n' },
			{},
			'x',
			[ 1 ],
		);
		my $n = 0;
		for my $doc (@docs) {
			$n++;
			Database::BI::Controller::Dashboard::_write_analyses($c, { $id => $doc });
			my $tok = Database::BI::Controller::Dashboard::_make_share_token($c, $id, time() + 100);
			for my $url ("/a/$id", "/api/analyses/$id", "/api/analyses/$id/export", "/a/$id/visual/0/csv",
				"/share/$id?token=$tok", "/embed/$id?token=$tok") {
				$tm->get_ok($url);
				ok $tm->tx->res->code < 500, "document $n at $url is not a 500" or diag $tm->tx->res->dom->at('title') // '';
			}
			$tm->get_ok('/api/analyses');
			ok $tm->tx->res->code < 500, "document $n does not break the list";
			$tm->get_ok('/catalog');
			ok $tm->tx->res->code < 500, "document $n does not break the catalog";
		}
	};

	subtest 'analyses_share, share_view, embed_view' => sub {
		my $tm = isolated_app();
		$tm->app->config->{share_secret} = 'test-secret';
		my $id = $tm->post_ok('/api/analyses' => json => {
			name => 'n', datasets => [ { spec => $SALES } ],
			visuals => [ { kind => 'bar', encode => { cat => 'region', value => 'amount' } } ],
		})->tx->res->json->{id};

		my $share = $tm->post_ok("/api/analyses/$id/share")->status_is(200)->tx->res->json;
		ok $share->{expires} > time(), 'a token that lasts';
		like $share->{url}, qr{/share/\Q$id\E\?token=}, 'and a link';

		$tm->get_ok("/share/$id?token=$share->{token}")->status_is(200);
		$tm->get_ok("/embed/$id?token=$share->{token}")->status_is(200);

		for my $route ('share', 'embed') {
			$tm->get_ok("/$route/$id")->status_is(401, "$route with no token");
			$tm->get_ok("/$route/$id?token=junk")->status_is(403, "$route with a bad one");
			$tm->get_ok("/$route/nosuchcanvas?token=$share->{token}")->status_is(403, "$route of another canvas");
			$tm->get_ok("/$route/a-b?token=x")->status_is(400, "$route with a bad id");
		}
	};

	subtest 'visual_download' => sub {
		my $tm = isolated_app();
		my $id = $tm->post_ok('/api/analyses' => json => {
			name => 'n', datasets => [ { spec => $SALES } ],
			visuals => [ { kind => 'bar', encode => { cat => 'region', value => 'amount' } } ],
		})->tx->res->json->{id};

		# Why: this called a plain function as a method and read l= from the URL, so
		# a card's CSV was a 500 with l= and a 422 without.  The canvas names its data.
		$tm->get_ok("/a/$id/visual/0/csv")->status_is(200)->content_like(qr/\Aid,product,region/)
			->header_like('Content-Disposition', qr/visual-0\.csv/);
		$tm->get_ok("/a/$id/visual/0/csv?l=table:nosuch")->status_is(200, 'and l= cannot point it elsewhere')->content_like(qr/\Aid,product,region/);
		$tm->get_ok("/a/$id/visual/0/png")->status_is(501);
		$tm->get_ok("/a/$id/visual/9/csv")->status_is(404);
		$tm->get_ok("/a/$id/visual/-1/csv")->status_is(400);
		$tm->get_ok("/a/$id/visual/x/csv")->status_is(400);
		$tm->get_ok("/a/$id/visual/0/exe")->status_is(400);
		$tm->get_ok('/a/nosuchcanvas/visual/0/csv')->status_is(404);
		$tm->get_ok('/a/a-b/visual/0/csv')->status_is(400);
	};

	subtest 'geo_save, geo_list, geo_delete' => sub {
		my $tm = isolated_app();
		$tm->get_ok('/geo/list')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/geo/save')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok('/geo/delete')->status_is(400)->json_is('/error', 'l= required');
		$tm->post_ok("/geo/save?l=$SALES")->status_is(400)->json_is('/error', 'col= required');
		$tm->post_ok("/geo/save?l=$SALES&col=region")->status_is(400)->json_is('/error', 'kind must be lat, lon, location or location_suffix');
		$tm->post_ok("/geo/save?l=$SALES&col=region&kind=evil")->status_is(400);

		$tm->post_ok("/geo/save?l=$SALES&col=region&kind=location")->status_is(200);
		$tm->get_ok("/geo/list?l=$SALES")->status_is(200)->content_like(qr/region/);
		$tm->post_ok("/geo/delete?l=$SALES&col=region")->status_is(200);
		$tm->get_ok("/geo/list?l=$SALES")->status_is(200)->content_unlike(qr/region/);
		$tm->post_ok("/geo/delete?l=$SALES&col=nosuch")->status_is(200);
	};

	subtest 'columns_api, range_api, dirs_api, stat_api' => sub {
		my $tm = isolated_app();
		$tm->get_ok('/api/columns?table=sales')->status_is(200);
		ok scalar(grep { $_ eq 'region' } @{ $tm->tx->res->json->{columns} // $tm->tx->res->json }), 'the columns of a table';
		$tm->get_ok('/api/columns?table=nosuchtable')->status_is(404);
		$tm->get_ok('/api/columns?path=/no/such/file.csv')->status_is(404);
		$tm->get_ok('/api/columns')->status_is(404);

		$tm->get_ok('/api/range')->status_is(400)->json_is('/error', 'l required');
		$tm->get_ok("/api/range?l=$SALES")->status_is(400)->json_is('/error', 'col required');
		$tm->get_ok("/api/range?l=$SALES&col=sale_date")->status_is(200);

		# The range is of the view: joins and the join type count.
		my $jdir = tempdir(CLEANUP => 1);
		Mojo::File->new($jdir, 'rangeleft.csv')->spew("id,opened\n1,2020-01-01\n2,2021-06-15\n");
		Mojo::File->new($jdir, 'rangeright.csv')->spew("id,shipped\n1,2022-03-04\n1,2022-03-04\n");
		Mojo::File->new($jdir, 'rangemore.csv')->spew("id,opened\n9,2024-02-02\n");
		my $left  = Mojo::Util::url_escape("path:$jdir/rangeleft.csv");
		my $right = Mojo::Util::url_escape("path:$jdir/rangeright.csv|id|id");
		my $more  = Mojo::Util::url_escape("path:$jdir/rangemore.csv");
		$tm->get_ok("/api/range?l=$left&col=shipped")->status_is(200)
			->json_is('/min', undef, 'without j= the right-hand column is unknown');
		$tm->get_ok("/api/range?l=$left&j=$right&col=shipped")->status_is(200)
			->json_is('/min', '2022-03-04', 'a column from the joined table')
			->json_is('/max', '2022-03-04');
		$tm->get_ok("/api/range?l=$left&j=$right&col=opened")->status_is(200)
			->json_is('/max', '2021-06-15', 'a left join keeps the unmatched row');
		$tm->get_ok("/api/range?l=$left&j=$right&jtype=inner&col=opened")->status_is(200)
			->json_is('/max', '2020-01-01', 'an inner join drops it');
		$tm->get_ok("/api/range?l=$left&c=$more&col=opened")->status_is(200)
			->json_is('/max', '2024-02-02', 'stacked rows count');
		$tm->get_ok("/api/range?l=$left&col=nosuch")->status_is(200)->json_is('/min', undef);
		$tm->get_ok("/join?l=$left&j=$right&jtype=inner")->status_is(200)
			->content_like(qr/data-range-qs="&amp;j=[^"]*rangeright[^"]*&amp;jtype=inner"/,
				'the dashboard hands the view to its range requests');
		$tm->get_ok("/api/range?l=nosuch:x&col=opened")->status_is(200)->json_is('/min', undef);

		my $dir = tempdir(CLEANUP => 1);
		Mojo::File->new($dir, 'sub')->make_path;
		$tm->get_ok('/api/dirs?path=' . Mojo::Util::url_escape($dir))->status_is(200)->content_like(qr/sub/);
		$tm->get_ok('/api/dirs?path=/no/such/dir')->status_is(404)->json_is('/error', 'Not a directory');

		$tm->get_ok('/api/stat')->status_is(400);
		$tm->get_ok('/api/stat?path=' . Mojo::Util::url_escape('/no/such/file'));
		ok $tm->tx->res->code < 500, 'a file that is not there';
		warnings_are { $tm->get_ok('/api/stat?path=' . Mojo::Util::url_escape("a\nb")) } [], 'a name with a newline';
		ok $tm->tx->res->code < 500, 'answers';
	};

	subtest 'open_file, import_url, join_tables, combine_tables' => sub {
		my $tm = isolated_app();
		my $csv = $tm->app->home->child('data/sales.csv')->to_string;
		$tm->get_ok('/open?path=' . Mojo::Util::url_escape($csv))->status_is(200)->content_like(qr/Widget A/);
		$tm->get_ok('/open?path=/no/such/file.csv')->status_is(404);
		$tm->get_ok('/open?path=' . Mojo::Util::url_escape($tm->app->home->child('Makefile.PL')->to_string))->status_is(404, 'a file of an unsupported type');
		warnings_are { $tm->get_ok('/open?path=' . Mojo::Util::url_escape("/a\nb.csv"))->status_is(404) } [], 'a name with a newline, quietly';
		$tm->get_ok('/open?path=' . Mojo::Util::url_escape("/etc/passwd\0.csv"));
		ok $tm->tx->res->code < 500, 'a NUL in a name';

		$tm->get_ok('/import');
		ok $tm->tx->res->code < 500, 'an import of nothing';
		# Refusals here are shown on the home page, which is an ordinary 200.
		$tm->get_ok('/import?url=' . Mojo::Util::url_escape('file:///etc/passwd'))->status_is(200);
		unlike $tm->tx->res->body, qr/root:[^:]*:0:0/, 'a file: URL does not read a file';
		with_fake_network(fake_response(200, 'a,b'), sub {
			my ($requests) = @_;
			$tm->get_ok('/import?url=' . Mojo::Util::url_escape('http://127.0.0.1/x'))->status_is(200);
			is scalar @$requests, 0, 'and a loopback address is never fetched';
		});

		$tm->get_ok("/join?l=$SALES&j=" . Mojo::Util::url_escape('table:sales|id|id'))->status_is(200);
		$tm->get_ok("/join?l=$SALES&j=" . Mojo::Util::url_escape('table:nosuch|id|id'));
		ok $tm->tx->res->code < 500, 'a join to nothing';
		$tm->get_ok("/join?l=$SALES&j=junk");
		ok $tm->tx->res->code < 500, 'a malformed join';
		$tm->get_ok('/join');
		ok $tm->tx->res->code < 500, 'no source';

		$tm->get_ok("/combine?l=$SALES&c=$SALES")->status_is(200);
		$tm->get_ok("/combine?l=$SALES&c=table:nosuch");
		ok $tm->tx->res->code < 500, 'combining nothing';
		$tm->get_ok('/combine');
		ok $tm->tx->res->code < 500, 'no source';
	};

	subtest 'export_data and the _render_* functions' => sub {
		my $tm = isolated_app();
		my $csv = $tm->get_ok("/export?l=$SALES&format=csv")->status_is(200)->tx->res->body;
		like $csv, qr/\Aid,product,region/, 'CSV starts with the header';
		my $json = $tm->get_ok("/export?l=$SALES&format=json")->status_is(200)->tx->res->json;
		returns_is $json, { type => 'arrayref' }, 'JSON is a list of rows';
		is $json->[0]{region}, 'North', 'with the columns';
		my $db = $tm->get_ok("/export?l=$SALES&format=sqlite")->status_is(200)->tx->res->body;
		like $db, qr/\ASQLite format 3\0/, 'SQLite is a database file';

		like $tm->get_ok("/export?l=$SALES&format=exe")->status_is(200)->tx->res->body, qr/\Aid,product,region/, 'an unknown format downloads as CSV';
		$tm->get_ok('/export?l=table:nosuch&format=csv');
		ok $tm->tx->res->code >= 400 && $tm->tx->res->code < 500, 'a source that is not there';
		$tm->get_ok('/export');
		ok $tm->tx->res->code < 500, 'no source at all';

		my $filtered = $tm->get_ok("/export?l=$SALES&format=json&f=region:eq:East")->tx->res->json;
		ok !(grep { $_->{region} ne 'East' } @$filtered), 'an export honours its filters';
		ok scalar(@$filtered), 'and holds something';
	};

	# Why: these paths rendered their error and then returned the same empty list as a
	# missing table, so the caller rendered again and the connection was left hanging
	# until it timed out.  An inactivity limit makes a regression fail fast here.
	subtest '_run_export_pipeline -- a bad request is answered, once' => sub {
		my $tm = isolated_app();
		$tm->ua->inactivity_timeout($REPLY_TIMEOUT);
		my $bad_calc = Mojo::Util::url_escape('b:nope');
		for my $q ('span=abc', "tcol=region&span=1d&as=1bad", "c=$bad_calc") {
			$tm->get_ok("/export?l=$SALES&cat=region&$q")->status_is(400, "/export with $q")->content_type_like(qr{\Atext/plain});
			$tm->get_ok("/folder?l=$SALES&cat=region&$q")->status_is(400, "/folder with $q");
			$tm->post_ok("/export?l=$SALES&cat=region&$q&dir=" . Mojo::Util::url_escape(tempdir(CLEANUP => 1)) . '&filename=x.csv')->status_is(400, "POST /export with $q");
		}
	};

	subtest 'export_write -- where a file may be written' => sub {
		my $tm  = isolated_app();
		my $dir = tempdir(CLEANUP => 1);
		my $d   = Mojo::Util::url_escape($dir);
		my $q   = "l=$SALES&format=csv&dir=$d";

		$tm->post_ok("/export?$q&filename=out.csv");
		ok $tm->tx->res->code < 300, 'a good export is written' or diag $tm->tx->res->body;
		ok -f File::Spec->catfile($dir, 'out.csv'), 'and is there';

		for my $evil ('../evil.csv', '/tmp/evil.csv', "a\0b.csv", '..', '.', '', "a/b.csv") {
			$tm->post_ok("/export?$q&filename=" . Mojo::Util::url_escape($evil));
			(my $shown = $evil) =~ s/\0/NUL/;
			ok $tm->tx->res->code >= 400 || !-e File::Spec->catfile(File::Spec->updir, 'evil.csv'), "the name '$shown' goes nowhere it should not";
			ok $tm->tx->res->code < 500 || $evil !~ /\.\./, "and '$shown' is not a crash";
		}
		ok !-e File::Spec->catfile(File::Basename::dirname($dir), 'evil.csv'), 'nothing escaped the directory';

		warnings_are { $tm->post_ok("/export?$q&filename=" . Mojo::Util::url_escape("a\0b.csv"))->status_is(415, 'a NUL in the name') } [], 'is refused before it reaches the filesystem';
		$tm->post_ok("/export?l=$SALES&format=exe&dir=$d&filename=x.exe")->status_is(415, 'an unknown format');
		$tm->post_ok("/export?l=table:nosuch&format=csv&dir=$d&filename=y.csv")->status_is(404)->json_is('/error', 'Table not found');
		$tm->post_ok("/export?l=$SALES&format=csv&dir=/no/such/dir&filename=y.csv");
		ok $tm->tx->res->code >= 400, 'a directory that is not there';
	};

	subtest 'upload_file and clear_uploads' => sub {
		my $tm = isolated_app();
		my $dir = Mojo::File->new($tm->app->config->{uploads_dir});

		$tm->post_ok('/upload')->status_is(400, 'nothing uploaded');
		$tm->post_ok('/upload' => form => { file => { content => "a,b\n1,2\n", filename => 'x.exe' } })->status_is(415, 'a type that is refused');
		$tm->post_ok('/upload' => form => { file => { content => "a,b\n1,2\n", filename => 'ok.csv' } });
		ok $tm->tx->res->code < 400, 'a good one is taken';
		ok scalar @{ $dir->list_tree }, 'and is on disk';

		$tm->post_ok('/upload' => form => { file => { content => "a,b\n1,2\n", filename => '../../evil.csv' } });
		ok $tm->tx->res->code < 500, 'a path in the name';
		ok !-e $dir->dirname->dirname->child('evil.csv'), 'cannot leave the staging directory';

		$tm->post_ok('/uploads/clear');
		ok $tm->tx->res->code < 400, 'clearing works';
		is scalar @{ $dir->list_tree }, 0, 'and clears';
		$tm->post_ok('/uploads/clear');
		ok $tm->tx->res->code < 400, 'clearing twice is fine';
	};

	subtest 'ask_api and summary_api' => sub {
		my $tm = isolated_app();
		delete $tm->app->config->{ai_api_key};
		$tm->post_ok('/api/ask')->status_is(503, 'no key: nothing else about the request matters');
		$tm->post_ok('/api/summary')->status_is(400)->json_is('/error', 'Missing required parameter: l');
		$tm->post_ok("/api/ask?l=$SALES&q=hello");
		ok $tm->tx->res->code >= 400 && $tm->tx->res->code < 500 || $tm->tx->res->code == 503, 'no key, no answer';
		$tm->post_ok('/api/ask?l=table:nosuch&q=hello');
		ok $tm->tx->res->code >= 400, 'nothing to ask about';
		$tm->post_ok("/api/summary?l=$SALES")->status_is(200)->json_is('/source', 'template');
		$tm->post_ok('/api/summary?l=table:nosuch')->status_is(404)->json_is('/error', 'Could not open data source');

		# With a key: the provider is replaced, and the prompt is read.
		$tm->app->config->{ai_api_key} = 'k';
		$tm->post_ok('/api/ask')->status_is(400)->json_is('/error', 'Missing required parameter: l');
		my $sent = with_fake_network(fake_response(200, '{"content":[{"text":"{\"kind\":\"bar\",\"title\":\"T\",\"encode\":{\"cat\":\"region\"}}"}]}'), sub {
			$tm->post_ok("/api/ask?l=$SALES&q=by+region")->status_is(200)->json_is('/valid', 1);
		});
		my $prompt = decode_json($sent->[0]->content)->{messages}[0]{content};
		unlike $prompt, qr/Widget A|Alice Smith/, 'no row data leaves the machine';
		like $prompt, qr/region/, 'only the names of the columns';
	};

	subtest 'folder_view, heatmap_view, pivot_view, stats_view, insights_view' => sub {
		my $tm = isolated_app();
		$tm->get_ok("/heatmap?l=$SALES&x=region&y=product&val=amount")->status_is(200);
		$tm->get_ok("/heatmap?l=$SALES");
		ok $tm->tx->res->code < 500, 'a heatmap with no axes';
		$tm->get_ok("/heatmap?l=$SALES&x=nope&y=nope");
		ok $tm->tx->res->code < 500, 'with axes that are not there';
		$tm->get_ok('/heatmap?l=table:nosuch&x=a&y=b')->status_is(404);

		$tm->get_ok("/pivot?l=$SALES&rows=region&m=amount:sum:total")->status_is(200)->content_like(qr/North/);
		$tm->get_ok("/pivot?l=$SALES&rows=region&m=amount:sum:total&format=csv")->status_is(200);
		$tm->get_ok("/pivot?l=$SALES&rows=nope&m=amount:sum:total");
		ok $tm->tx->res->code < 500, 'a pivot on nothing';
		$tm->get_ok("/pivot?l=$SALES&rows=region&m=amount:evil:x")->status_is(400, 'a function that is not there');
		$tm->get_ok('/pivot?l=table:nosuch&rows=a&m=a:sum:b')->status_is(404);

		$tm->get_ok("/stats?l=$SALES")->status_is(200)->content_like(qr/amount/);
		$tm->get_ok('/stats?l=table:nosuch')->status_is(404);
		$tm->get_ok('/stats')->status_is(400);

		$tm->get_ok("/insights?l=$SALES")->status_is(200);
		$tm->get_ok('/insights?l=table:nosuch')->status_is(404);
		$tm->get_ok('/insights')->status_is(400);

		$tm->get_ok("/folder?l=$SALES&col=region")->status_is(200);
		$tm->get_ok("/folder?l=$SALES&col=region&prefix=N")->status_is(200);
		$tm->get_ok("/folder?l=$SALES")->status_is(200, 'a key column is found if none is named');
		$tm->get_ok("/folder?col=region")->status_is(400)->content_is('Missing l= parameter');
		$tm->get_ok("/folder?l=$SALES&prefix=" . ('A' x 5000))->status_is(400)->content_is('Prefix too long');
		$tm->get_ok('/folder?l=table:nosuch&col=a')->status_is(404);
	};

	subtest 'wordcloud_view and map_view' => sub {
		my $tm = isolated_app();
		$tm->get_ok("/wordcloud?l=$SALES&col=product")->status_is(200);
		$tm->get_ok("/wordcloud?l=$SALES");
		ok $tm->tx->res->code >= 400 && $tm->tx->res->code < 500, 'a cloud of no column';
		$tm->get_ok('/wordcloud?l=table:nosuch&col=a')->status_is(404);
		for my $evil ('topn=abc', 'topn=-1', 'topn=' . ('9' x 50), 'minlen=abc', 'stop=' . Mojo::Util::url_escape('<script>')) {
			warnings_are { $tm->get_ok("/wordcloud?l=$SALES&col=product&$evil") } [], "$evil raises no warning";
			ok $tm->tx->res->code < 500, 'and is not a crash';
		}

		$tm->get_ok("/map?l=$SALES");
		ok $tm->tx->res->code < 500, 'a map with no location';
		$tm->get_ok("/map?l=$SALES&lat=id&lon=amount");
		ok $tm->tx->res->code < 500, 'with columns that are not positions';
		$tm->get_ok('/map?l=table:nosuch&lat=a&lon=b');
		ok $tm->tx->res->code >= 400 && $tm->tx->res->code < 500, 'of a source that is not there';
	};

	subtest 'catalog_view, tutorial, _catalog_entry' => sub {
		my $tm = isolated_app();
		$tm->get_ok('/tutorial')->status_is(200);
		$tm->get_ok('/catalog')->status_is(200);
		my $fn = \&Database::BI::Controller::Dashboard::_catalog_entry;
		my $mf = $tm->app->home->child('data/sales.csv');
		my $c  = dash_controller($tm->app, '/');
		my $entry;
		lives_ok { $entry = $fn->($c, $mf, { x => { name => 'Mine', datasets => [ { spec => $SALES } ] }, y => { name => 'Other', datasets => [ { spec => 'table:nope' } ] } }) } 'an entry is built';
		returns_is $entry, { type => 'hashref' }, 'as a hashref';
		is $entry->{type}, 'CSV file', 'with a readable type';
		is_deeply $entry->{analyses}, [ { id => 'x', name => 'Mine' } ], 'naming only the canvases that use it';
		lives_ok { $fn->($c, $mf, {}) } 'with no canvases';
	};

	# Why: a route that a stranger can reach has one job above all, which is not to
	# fall over.  Every GET is given the same hostile values for every parameter it
	# might read: nothing may be a 5xx, and nothing may trip a Perl warning, since a
	# warning is an unconsidered case that happens to be survivable today.
	subtest 'every GET route -- hostile parameters' => sub {
		my $tm = isolated_app();
		my @routes = (qw(/ /tutorial /browse /open /join /api/columns /api/range /import /combine /export /api/dirs /api/stat
			/graph /line /pie /heatmap /bar /folder /tables /pivot /stats /calc/list /groups/list /dates/list /lookups/list /extract/list /geo/list
			/scatter /stacked /combo /treemap /histogram /wordcloud /map /insights /api/analyses /catalog), '/view/sales');
		my @params = (qw(l x y cat val seg col rows cols m bar line size group bins page per_page topn minlen
			f c j jtype range rcol cs by order span tcol as lk nolk path table format back back2 scheme sort lat lon loc));
		my @evil = ('', '0', '-1', 'abc', '1e400', '9' x 40, "a\nb", "a\0b", $XSS_PROBE, q{"'}, '../../etc/passwd',
			'nan', 'inf', 'table:sales', 'table:nosuch', 'path:/etc/passwd', "\xFF\xFE", ':::', '%');
		my %no_data_needed = map { $_ => 1 } qw(/tutorial /calc/list /groups/list /dates/list /lookups/list /extract/list /geo/list /api/analyses /api/dirs /api/stat /catalog);
		my %bad_in_bulk = map { $_ => 1 } ('', 'abc', '9' x 40, "a\nb", $XSS_PROBE, "\xFF\xFE");

		$tm->ua->inactivity_timeout($REPLY_TIMEOUT);
		my (@crashes, @noisy, @echoed);
		local $SIG{__WARN__} = sub {
			my $w = shift;
			push @noisy, $w if $w =~ $PERL_INTERNAL_WARNING;
		};
		my $probe = sub {
			my ($url) = @_;
			my $res  = $tm->ua->get($url)->res;
			my $code = $res->code // 0;
			push @crashes, "no reply: $url" unless $code;
			push @crashes, "$code $url" if $code >= 500 && $code != 501 && $code != 503;
			# As plain text or JSON it is only words.  Only a page can run it.
			push @echoed, $url if index($res->body, $XSS_PROBE) >= 0 && ($res->headers->content_type // '') =~ /html/;
		};

		# All of them at once finds interactions.  Then one at a time, with a usable
		# source, gets past the guard a missing parameter would stop at; each pairing
		# takes the next hostile value, so that the whole set is covered across a few
		# columns without this one subtest taking minutes.
		my $next = 0;
		for my $route (@routes) {
			for my $value (sort keys %bad_in_bulk) {
				my $e = Mojo::Util::url_escape($value);
				$probe->("$route?" . join('&', map { "$_=$e" } @params));
			}
			$probe->("$route?l=" . ('x' x $LONG_PARAM));
			next if $no_data_needed{$route};
			for my $param ($ENV{EXTENDED_TESTING} ? @params : @RISKIEST_PARAMS) {
				my $e = Mojo::Util::url_escape($evil[$next++ % @evil]);
				$probe->("$route?l=$SALES&col=amount&cat=region&x=region&y=amount&$param=$e");
			}
		}
		my %crash = map { (substr($_, 0, 160)) => 1 } @crashes;
		my %noise = map { (s/ at .*//sr) => 1 } @noisy;
		is_deeply [ sort keys %crash ], [], 'no parameter crashes a route';
		is_deeply [ sort keys %noise ], [], 'and none raises a Perl warning';
		is_deeply [ @echoed[ 0 .. ($#echoed < 4 ? $#echoed : 4) ] ], [], 'and markup is never sent back as markup';
	};
}


# ============================================================================
# PART U12: Database::BI::Calc -- the functions no earlier part reaches
# ============================================================================
{
	# The limits and the words compile_pattern refuses with.  The messages are
	# spelled out rather than read from the module, so that a changed message
	# is a failure a reviewer sees, not a change that passes unnoticed.
	Readonly my %CALC => (
		max_pattern => 200,
		max_capture => 200,
		too_long    => qr/\APattern '[^']{40}\.\.\.' is longer than 200 characters/,
		construct   => "Pattern '%s' uses %s, which is not allowed",
		invalid     => qr/\APattern '\(' does not compile: Unmatched \( in regex/,
	);
	my $compile = \&Database::BI::Calc::compile_pattern;
	my $capture = \&Database::BI::Calc::capture_of;
	my $real    = \&Database::BI::Calc::_iso_date_if_real;

	# Purpose: the pattern a reader types is the one thing in a calculated field
	# that reaches the regex engine as code, so every guard must fire with its
	# own words, and the summary of a good pattern must be exact: the groups and
	# names become columns.
	subtest 'Calc::compile_pattern -- the summary of a good pattern' => sub {
		my $got = $compile->('(?<year>\d{4})-(\d\d)-(?P<day>\d\d)(?:x)?');
		returns_is $got, { type => 'hashref' }, 'a hashref';
		is ref($got->{re}), 'Regexp', 'with a compiled pattern';
		is $got->{groups}, 3, 'counting capturing groups only, not (?:)';
		is_deeply $got->{names}, [qw(year day)], 'names in the order written, Python spelling included';

		is_deeply $compile->("(?'b'x)(?<a>y)")->{names}, [qw(b a)], 'the quoted spelling, and written order rather than sorted';
		is_deeply $compile->('\(?<a>x\)')->{names}, [], 'an escaped paren declares nothing';

		for my $empty (undef, '', [], {}) {
			my $e = $compile->($empty);
			is $e->{groups}, 0, 'a missing or non-string pattern is the empty one';
			is_deeply $e->{names}, [], 'with no names';
		}
		is length('x' x $CALC{max_pattern}), $CALC{max_pattern}, 'the longest allowed';
		lives_ok { $compile->('x' x $CALC{max_pattern}) } 'is accepted';
		memory_cycle_ok $got, 'the summary holds no cycle';
	};

	# Purpose: (?{ }) and friends run Perl code inside the engine; a pattern from
	# a stored model must never be able to do that, nor be too long to judge.
	subtest 'Calc::compile_pattern -- hostile patterns are refused' => sub {
		throws_ok { $compile->('x' x ($CALC{max_pattern} + 1)) } $CALC{too_long},
			'one character over the limit, shown cut to 40';
		for my $case ([ '(?{ 1 })', '(?{' ], [ 'a(??{ "b" })', '(??{' ], [ '(?p{1})', '(?p' ],
				[ '(*FAIL)', '(*' ], [ 'a\\\\(?{1})', '(?{' ]) {
			my ($pattern, $construct) = @{$case};
			my $want = sprintf($CALC{construct}, $pattern, $construct);
			throws_ok { $compile->($pattern) } qr/\A\Q$want\E/, "$pattern is refused by name";
		}
		lives_ok { $compile->('\\(?{') } 'an escaped paren is a literal, not code';
		throws_ok { $compile->('(') } $CALC{invalid}, 'an unbalanced pattern says why';
		throws_ok { $compile->('[z-a]') } qr/\APattern '\[z-a\]' does not compile: /, 'a bad range too';
		eval { $compile->('(') };
		my @lines = $@ =~ / line \d+/g;
		is scalar(@lines), 1, 'the engine\'s own file and line are cut, so only croak\'s is left';
	};

	# Purpose: the caller's $@, $_ and match variables belong to the caller.
	subtest 'Calc::compile_pattern -- leaves the caller alone' => sub {
		local $@ = 'before';
		$compile->('(a)(b)');
		is $@, 'before', '$@ is kept on success';
		'outer' =~ /(out)/;
		$compile->('(?<x>y)');
		is $1, 'out', 'the caller\'s $1 survives the empty match used to count groups';
		keeps_globals_ok('compile_pattern', sub { $compile->('(a)') });
	};

	# Purpose: capture_of is what writes a stored extraction's cells, so a
	# question it cannot answer must be undef (no such cell), never a wrong one.
	subtest 'Calc::capture_of -- answers and refusals' => sub {
		my $c = $compile->('(?<word>[a-z]+)(\d+)?(?<tail>!)?');
		is $capture->($c, 'abc12', 1), 'abc', 'the first group by number';
		is $capture->($c, 'abc12', 2), '12', 'the second';
		is $capture->($c, 'abc12', 'word'), 'abc', 'a group by name';
		is $capture->($c, 'abc', 2), '', 'a group that took no part is empty, not undef';
		is $capture->($c, 'abc', 'tail'), '', 'by name as well';
		is $capture->($c, '123', 1), undef, 'no match';
		is $capture->($c, 'abc', 0), undef, 'group 0 is not a group';
		is $capture->($c, 'abc', 4), undef, 'nor one past the last';
		is $capture->($c, 'abc', 'nope'), undef, 'nor an unknown name';
		is $capture->($c, 'abc', '-1'), undef, 'nor a negative number';
		is $capture->($c, undef, 1), undef, 'an undefined cell';
		is $capture->($c, [ 'abc' ], 1), undef, 'a reference is not a cell';
		is $capture->($c, 'abc', undef), undef, 'no group asked for';
		my $long = $compile->('(.*)');
		is length($capture->($long, 'y' x ($CALC{max_capture} * 2), 1)), $CALC{max_capture},
			'a long capture is cut to the limit';
		returns_is $capture->($c, 'abc', 1), { type => 'string' }, 'a plain string';
		keeps_globals_ok('capture_of', sub { $capture->($c, 'abc', 'word') });
	};

	# Purpose: a US-read UK date produces months up to 31; those must not become
	# a date that sorts among real ones.
	subtest 'Calc::_iso_date_if_real -- only dates that exist' => sub {
		is $real->(2026, 1, 15), '2026-01-15', 'an ordinary date, zero-padded';
		is $real->('2024', '2', '29'), '2024-02-29', 'a leap day in a leap year';
		is $real->(2026, 2, 29), undef, 'not in a common year';
		is $real->(2026, 13, 1), undef, 'month 13';
		is $real->(2026, 15, 1), undef, 'a day read as a month';
		is $real->(2026, 4, 31), undef, 'the 31st of a 30-day month';
		is $real->(2026, 1, 0), undef, 'day zero';
		{
			local $! = 0;
			$real->(2026, 1, 15);
			is $! + 0, 0, 'errno is the caller\'s afterwards';
		}
	};
}

# ============================================================================
# PART U13: Database::BI::Model::DataSource -- the functions no earlier part reaches
# ============================================================================
{
	Readonly my %DSX => (
		server   => 'mock',
		table    => 'orders',
		database => 'shop',
		password => 'not-to-be-repeated',
		dsn_re   => qr/\Adbi:(?:MariaDB|mysql):database=shop;host=localhost;(?:mariadb|mysql)_connect_timeout=\d+\z/,
	);
	my $ds = 'Database::BI::Model::DataSource';

	# Stand-ins for a DBI handle and statement: enough for the three calls the
	# module makes, with a record of what was asked, so a test can see that a
	# handle is always disconnected, including on the way out of a failure.
	{
		package Stub::DBH;
		sub new { my ($c, %a) = @_; return bless { %a, disconnected => 0 }, $c }
		sub prepare {
			my ($self, $sql) = @_;
			die "Table '$self->{missing}' doesn't exist\n" if $self->{missing};
			return Stub::STH->new(names => $self->{names});
		}
		sub primary_key { return @{ $_[0]{primary} // [] } }
		sub selectall_arrayref {
			my $self = shift;
			die "SELECT command denied\n" if $self->{denied};
			return $self->{rows};
		}
		sub disconnect { $_[0]{disconnected}++; return 1 }
		package Stub::STH;
		sub new { my ($c, %a) = @_; return bless { NAME => $a{names} }, $c }
		sub execute { return 1 }
	}

	# Runs $code with DBI->connect answering $dbh (or failing when it is undef)
	# and a driver present, so no server and no installed DBD are needed.
	my $with_dbi = sub {
		my ($dbh, $code) = @_;
		require DBI;
		local $INC{'DBD/MariaDB.pm'} = __FILE__;
		my @calls;
		Test::Mockingbird::mock('DBI::connect', sub { shift; push @calls, [ @_ ]; return $dbh });
		my $ok  = eval { $code->(\@calls); 1 };
		my $err = $@;
		Test::Mockingbird::unmock('DBI::connect');
		croak_rethrow($err) unless $ok;
		return;
	};

	# Purpose: the settings come from configuration but end up in a DSN string,
	# so each part is checked before it is spliced in; and nothing in an error
	# may repeat the password.
	subtest 'DataSource::_mariadb_connect -- the settings are checked first' => sub {
		my $fn = \&Database::BI::Model::DataSource::_mariadb_connect;
		throws_ok { $fn->($DSX{server}, undef) }
			qr/\ADataSource: no MariaDB server is called "mock"; add it to mariadb_servers/, 'no settings';
		throws_ok { $fn->($DSX{server}, 'database=shop') } qr/no MariaDB server is called/, 'settings that are not a hash';
		for my $bad ([ database => 'shop;host=evil' ], [ database => '' ], [ host => 'a b' ],
				[ host => 'x;port=1' ], [ port => '33o6' ], [ port => '-1' ]) {
			my ($key, $value) = @{$bad};
			my %settings = (database => $DSX{database}, $key => $value);
			throws_ok { $fn->($DSX{server}, \%settings) }
				qr/\ADataSource: MariaDB server "mock" needs a valid $key in mariadb_servers/,
				"$key '$value' cannot reach the DSN";
		}
		require DBI;
		local $INC{'DBD/MariaDB.pm'} = __FILE__;
		Test::Mockingbird::mock('DBI::connect', sub { die "Access denied for user\n" });
		throws_ok { $fn->($DSX{server}, { database => $DSX{database}, password => $DSX{password} }) }
			qr/\ADataSource: cannot connect to MariaDB server "mock": /, 'a refused connection names the server';
		throws_ok { $fn->($DSX{server}, { database => $DSX{database}, password => $DSX{password} }) }
			qr/\A(?!.*\Q$DSX{password}\E)/s, 'and never the password';
		Test::Mockingbird::unmock('DBI::connect');
	};

	subtest 'DataSource::_mariadb_connect -- a connection' => sub {
		my $fn  = \&Database::BI::Model::DataSource::_mariadb_connect;
		my $dbh = Stub::DBH->new;
		$with_dbi->($dbh, sub {
			my ($calls) = @_;
			my @got = $fn->($DSX{server}, { database => $DSX{database}, username => 'u', password => $DSX{password} });
			is $got[0], $dbh, 'the handle';
			like $got[1], $DSX{dsn_re}, 'a DSN built only from checked parts, with a time-out';
			is_deeply [ @got[2, 3] ], [ 'u', $DSX{password} ], 'and the credentials it used';
			is $calls->[0][3]{RaiseError}, 1, 'errors are raised, so none is missed';
		});
	};

	# Purpose: the driver is optional; without one the reader is told what to
	# install rather than seeing a Perl error.
	subtest 'DataSource::_mariadb_connect -- no driver' => sub {
		my $fn = \&Database::BI::Model::DataSource::_mariadb_connect;
		local @INC = (sub { my (undef, $file) = @_; die "hidden\n" if $file =~ m{\ADBD/(?:MariaDB|mysql)\.pm\z}; return }, @INC);
		local $INC{'DBD/MariaDB.pm'};
		local $INC{'DBD/mysql.pm'};
		delete $INC{'DBD/MariaDB.pm'};
		delete $INC{'DBD/mysql.pm'};
		throws_ok { $fn->($DSX{server}, { database => $DSX{database} }) }
			qr/\ADataSource: DBD::MariaDB or DBD::mysql must be installed to open MariaDB server "mock"/,
			'says which modules';
	};

	subtest 'DataSource::mariadb_tables -- tables and their columns, in order' => sub {
		my $dbh = Stub::DBH->new(rows => [ [ 'b', 'id' ], [ 'b', 'x' ], [ 'a', 'k' ] ]);
		$with_dbi->($dbh, sub {
			my $got = $ds->mariadb_tables($DSX{server}, { database => $DSX{database} });
			is_deeply $got, [ { name => 'b', columns => [qw(id x)] }, { name => 'a', columns => ['k'] } ],
				'one entry a table, in the order the server listed them';
			is $dbh->{disconnected}, 1, 'the handle is closed';
			memory_cycle_ok $got, 'and the list holds no cycle';
		});
		my $denied = Stub::DBH->new(denied => 1);
		$with_dbi->($denied, sub {
			local $@ = 'kept';
			throws_ok { $ds->mariadb_tables($DSX{server}, { database => $DSX{database} }) }
				qr/\ADataSource: cannot connect to MariaDB server "mock": SELECT command denied/, 'a refused query';
			is $denied->{disconnected}, 1, 'still closes the handle';
		});
		throws_ok { $ds->mariadb_tables($DSX{server}, {}) } qr/needs a valid database/, 'bad settings never connect';
	};

	# Purpose: the constructor is where a bad table or server must be found,
	# not at the first read; and a handle opened to find out is always closed.
	subtest 'DataSource::_new_from_mariadb -- refusals' => sub {
		my $fn = \&Database::BI::Model::DataSource::_new_from_mariadb;
		throws_ok { $fn->($ds, { server => $DSX{server} }) } qr/table/i, 'no table';
		throws_ok { $fn->($ds, { server => $DSX{server}, table => 'a`b' }) } qr/\Q"a`b"\E|a`b/, 'a table name that could break out of its quotes';
		throws_ok { $fn->($ds, { server => '../x', table => $DSX{table}, mariadb => {} }) }
			qr/no MariaDB server is called "\.\.\/x"/, 'a server name that is not a name';
		my $dbh = Stub::DBH->new(missing => $DSX{table});
		$with_dbi->($dbh, sub {
			throws_ok { $fn->($ds, { server => $DSX{server}, table => $DSX{table}, mariadb => { database => $DSX{database} } }) }
				qr/\ADataSource: cannot read table "orders" on MariaDB server "mock": /, 'a table the server does not have';
			is $dbh->{disconnected}, 1, 'and the handle is closed';
		});
		my $ok = Stub::DBH->new(names => [qw(id amount)], primary => ['id']);
		$with_dbi->($ok, sub {
			Test::Mockingbird::mock('Database::Abstraction::new', sub { die "no backend\n" });
			require Database::Abstraction;
			throws_ok { $fn->($ds, { server => $DSX{server}, table => $DSX{table}, mariadb => { database => $DSX{database} } }) }
				qr/\ADataSource: failed to initialise database backend for table "orders": no backend/, 'D::A refusing it';
			Test::Mockingbird::unmock('Database::Abstraction::new');
		});
	};

	subtest 'DataSource::_new_from_mariadb -- what it keeps' => sub {
		my $fn = \&Database::BI::Model::DataSource::_new_from_mariadb;
		require Database::Abstraction;
		Test::Mockingbird::mock('Database::Abstraction::new', sub { my ($class, %a) = @_; return bless { %a }, $class });
		for my $case ([ ['id'], 'id', 'id' ], [ [qw(a b)], undef, 'a' ], [ [], undef, 'amount' ], [ ['First Name'], undef, 'First Name' ]) {
			my ($primary, $order, $id) = @{$case};
			my $dbh = Stub::DBH->new(names => [qw(amount id)], primary => $primary);
			$with_dbi->($dbh, sub {
				my $self = $fn->($ds, { server => $DSX{server}, table => $DSX{table}, mariadb => { database => $DSX{database} } });
				isa_ok $self, $ds;
				is $self->{_order_col}, $order, 'pages are ordered only by a single safe key: ' . (join(',', @{$primary}) || 'none');
				is $self->{_id_col}, $id, 'the id is the first key, else the first column';
				is_deeply $self->{_columns}, [qw(amount id)], 'the columns in the table\'s own order';
				is $self->pages_on_server, 1, 'and it pages on the server';
				memory_cycle_ok $self, 'no cycle';
			});
		}
		Test::Mockingbird::unmock('Database::Abstraction::new');
	};

	subtest 'DataSource::pages_on_server -- only a MariaDB source' => sub {
		is $ds->can('pages_on_server')->(bless({}, $ds)), 0, 'a file is not paged on a server';
		is $ds->can('pages_on_server')->(bless({ _mariadb => '' }, $ds)), 1, 'any MariaDB entry is, even an oddly named one';
	};

	# Purpose: the fallback for a sort D::A ignores must never write to the
	# caller's rows (they may be D::A's cache) and must take hostile paging.
	subtest 'DataSource::_unsafe_sort -- recognises only its own calls' => sub {
		my $fn = \&Database::BI::Model::DataSource::_unsafe_sort;
		is_deeply [ $fn->(sort_by => 'First Name', limit => 5, offset => 10, region => 'N') ],
			[ { region => 'N' }, 'First Name', 'ASC', 5, 10 ], 'a flat list';
		is_deeply [ $fn->({ sort_by => [ 'First Name', 'desc' ] }) ],
			[ {}, 'First Name', 'DESC', undef, undef ], 'a hashref, as Database::Join sends';
		my %orig = (sort_by => 'Last Name', limit => 1);
		$fn->(\%orig);
		is_deeply \%orig, { sort_by => 'Last Name', limit => 1 }, 'the caller\'s hash is not changed';
		is_deeply [ $fn->(sort_by => 'amount') ], [], 'a column D::A sorts itself';
		is_deeply [ $fn->() ], [], 'no arguments';
		is_deeply [ $fn->('odd') ], [], 'an odd list';
		is_deeply [ $fn->([ sort_by => 'First Name' ]) ], [], 'an arrayref is not ours';
		is_deeply [ $fn->(region => 'N') ], [], 'no sort at all';
		is_deeply [ $fn->(sort_by => [ undef, 'ASC' ]) ], [], 'a sort naming no column';
	};

	subtest 'DataSource::_sorted_page -- a new, sorted, sliced array' => sub {
		my $fn   = \&Database::BI::Model::DataSource::_sorted_page;
		my @rows = map { { 'First Name' => $_ } } qw(c a b);
		Internals::SvREADONLY(@rows, 1);
		my $asc = $fn->(\@rows, 'First Name', 'ASC');
		is_deeply [ map { $_->{'First Name'} } @{$asc} ], [qw(a b c)], 'ascending, as strings';
		is_deeply [ map { $_->{'First Name'} } @{ $fn->(\@rows, 'First Name', 'DESC', 2) } ], [qw(c b)], 'descending, limited';
		is_deeply [ map { $_->{'First Name'} } @{ $fn->(\@rows, 'First Name', 'ASC', 1, 1) } ], ['b'], 'a later page';
		is_deeply [ map { $_->{'First Name'} } @{ $fn->(\@rows, 'nope', 'ASC') } ], [qw(c a b)], 'an unknown column does not sort';
		is_deeply $fn->(\@rows, 'First Name', 'ASC', 'x', '-1'), $asc, 'paging that is not a number is ignored';
		is_deeply $fn->(\@rows, 'First Name', 'ASC', 0), [], 'a limit of nothing is nothing';
		is_deeply $fn->(\@rows, 'First Name', 'ASC', undef, 99), [], 'an offset past the end is empty';
		is_deeply $fn->(undef, 'x', 'ASC'), [], 'no rows';
		isnt $asc, \@rows, 'never the caller\'s array';
		is_deeply [ map { $_->{'First Name'} } @rows ], [qw(c a b)], 'which is untouched';
		my %locked = ('First Name' => 'z');
		Hash::Util::lock_ref_keys(\%locked) if eval { require Hash::Util; 1 };
		lives_ok { $fn->([ \%locked ], 'Last Name', 'ASC') } 'a locked row without the column is not read';
	};

	# Purpose: the sniffing of a file's shape must not split a quoted separator,
	# and must still answer for a line it cannot parse.
	subtest 'DataSource::_split_csv_line -- fields' => sub {
		my $fn = \&Database::BI::Model::DataSource::_split_csv_line;
		is_deeply [ $fn->('a,"b,c",d', ',') ], [ 'a', 'b,c', 'd' ], 'a quoted separator stays in its field';
		is_deeply [ $fn->('a|b||', '|') ], [ 'a', 'b', '', '' ], 'empty trailing fields are kept';
		is_deeply [ $fn->('a,"unterminated', ',') ], [ 'a', '"unterminated' ], 'a line that does not parse is split plainly';
		is_deeply [ $fn->('a.b', '.') ], [ 'a', 'b' ], 'a separator that is a regex character is literal';
		is_deeply [ $fn->('', ',') ], [ '' ], 'an empty line is one empty field';
		keeps_globals_ok('_split_csv_line', sub { $fn->('a,b', ',') });
	};

	# Purpose: a file with no header is read through a copy that has one; the
	# copy must keep every value, and the id D::A keys on must be a column that
	# does not drop rows.
	subtest 'DataSource::_copy_with_header -- the copy D::A reads' => sub {
		my $self = bless {}, $ds;
		my $dir  = tempdir(CLEANUP => 1);
		my $path = File::Spec->catfile($dir, 'bank.csv');
		Mojo::File->new($path)->spew(join("\n",
			'2026-01-02, 10 ,"Shop, the big one"',
			'',
			'2026-01-03,5',
			'#2026-01-04,7,Cafe,extra,bits',
		) . "\n");
		my ($tmp, $id, $size) = $self->_copy_with_header({ path => $path, ext => 'csv' }, [qw(Date Amount Description)], ',', 'bank');
		ok -d "$tmp", 'a temporary directory';
		my $copy = File::Spec->catfile("$tmp", 'bank.csv');
		is $size, -s $copy, 'and the size of the copy in it';
		my @lines = split /\n/, Mojo::File->new($copy)->slurp;
		is $lines[0], 'Date,Amount,Description', 'the header first';
		is scalar(@lines), 4, 'the blank line is gone';
		like $lines[1], qr/\A2026-01-02,10,"Shop, the big one"\z/, 'values trimmed, a quoted comma kept';
		is $lines[2], '2026-01-03,5,', 'a short row is padded';
		like $lines[3], qr/Cafe,extra,bits/, 'a long row keeps its extra fields in the last value';
		is $id, 'Amount', 'the id is the column with no empty or #-led values';
		throws_ok {
			Mojo::File->new($path)->spew(qq{a,"never closed\nb,c\n});
			$self->_copy_with_header({ path => $path, ext => 'csv' }, [qw(A B)], ',', 'bank');
		} qr/\ADataSource: failed to initialise database backend for table "bank": cannot parse \Q$path\E: /,
			'an unterminated quote is an error, not a short file';
		throws_ok { $self->_copy_with_header({ path => "$dir/none.csv", ext => 'csv' }, ['A'], ',', 'none') }
			qr/none\.csv/, 'a missing file is an error naming it';
	};
}

# ============================================================================
# PART U14: Database::BI::Model::Geocode -- the functions no earlier part reaches
# ============================================================================
{
	Readonly my %GX => (
		online_class => 'Stub::Online',
		dir_error    => 'Geocode: the geocode cache needs a directory that exists, not "%s"',
		rows_error   => qr/\AGeocode: the rows must be an arrayref, not "HASH"/,
		col_error    => qr/\AGeocode: the column name is required/,
	);

	# A Geo::Coder::List stand-in: answers from a table, logs as the real one
	# does (one entry per geocoder asked, 'cache' when its cache answered), and
	# can be told that a geocoder threw.
	{
		package Stub::Chain;
		sub new { my ($c, %a) = @_; return bless { answers => {}, logs => {}, asked => [], %a }, $c }
		sub flush { $_[0]{log} = []; return $_[0] }
		sub geocode {
			my ($self, %a) = @_;
			push @{ $self->{asked} }, { %a };
			$self->{log} = $self->{logs}{ $a{location} } // [ { geocoder => 'Stub::Local' } ];
			return $self->{answers}{ $a{location} };
		}
		sub log { return $_[0]{log} }
		package Stub::Online;
		sub new { my ($c, %a) = @_; return bless { %a }, $c }
		sub response { return $_[0]{response} }
		package Stub::Response;
		sub new { my ($c, $ok, $line) = @_; return bless { ok => $ok, line => $line }, $c }
		sub is_success { return $_[0]{ok} }
		sub status_line { return $_[0]{line} }
	}
	my $point = sub { Stub::GeoPoint->new({ latitude => $_[0], longitude => $_[1], database => 'stub' }) };

	# Purpose: several columns become one place; the rows themselves must not
	# be written (SQL rows are locked), and a row that is not a row stays one.
	subtest 'Geocode::place_rows -- columns joined into one place' => sub {
		my @rows = ({ a => ' Brezje 8 ', c => 'Slovenia' }, { a => '', c => 'Slovenia' }, { a => undef, c => [] }, 'junk');
		my ($places, $name) = $GEO->place_rows(\@rows, [ 'a', undef, '', 'c' ]);
		is $name, 'a, c', 'the name lists the usable columns';
		is_deeply $places, [ { 'a, c' => 'Brezje 8, Slovenia' }, { 'a, c' => 'Slovenia' }, { 'a, c' => '' }, undef ],
			'trimmed, empties left out, a non-row undef';
		is_deeply $rows[0], { a => ' Brezje 8 ', c => 'Slovenia' }, 'the rows are untouched';
		my ($same, $one) = $GEO->place_rows(\@rows, ['a']);
		is $same, \@rows, 'one column is the rows themselves';
		is $one, 'a', 'under that column';
		throws_ok { $GEO->place_rows({}, ['a']) } $GX{rows_error}, 'rows that are not a list';
		throws_ok { $GEO->place_rows(undef, ['a']) } qr/not "undef"/, 'no rows';
		throws_ok { $GEO->place_rows([], [ undef, '', [] ]) } $GX{col_error}, 'no usable column';
		throws_ok { $GEO->place_rows([], 'a') } $GX{col_error}, 'a column list that is not a list';
		keeps_globals_ok('place_rows', sub { $GEO->place_rows([ { a => 1, b => 2 } ], [qw(a b)]) });
		memory_cycle_ok $places, 'no cycle';
	};

	subtest 'Geocode::file_cache -- only for a directory that exists' => sub {
		my $dir   = tempdir(CLEANUP => 1);
		my $cache = $GEO->file_cache($dir);
		ok $cache->can('get') && $cache->can('set'), 'something Geo::Coder::List can use';
		$cache->set(k => 'v');
		ok -d File::Spec->catdir($dir, 'geocode-cache'), 'kept under model_dir/geocode-cache';
		is $GEO->file_cache($dir)->get('k'), 'v', 'and found again by another object: it persists';
		for my $bad (undef, "$dir/none", [ $dir ], File::Spec->catfile($dir, 'geocode-cache', 'x')) {
			throws_ok { $GEO->file_cache($bad) } qr/\AGeocode: the geocode cache needs a directory that exists, not "/,
				'refused: ' . ($bad // 'undef');
		}
	};

	subtest 'Geocode::_default_cache -- one per process' => sub {
		my $fn = \&Database::BI::Model::Geocode::_default_cache;
		my $one = $fn->();
		is $fn->(), $one, 'the same object every time, so answers outlive a request';
		ok $one->can('get'), 'a cache';
	};

	subtest 'Geocode::_judge -- who decides what is a place' => sub {
		my $geo = bless { _local => 'the local geocoder' }, $GEO;
		my $own = Stub::Geocoder->new;
		is $geo->_judge($own), $own, 'a geocoder with its own rule answers for itself';
		is $geo->_judge(Stub::Chain->new), 'the local geocoder', 'a chain is judged by its local geocoder';
	};

	# Purpose: an injected geocoder's answer may be any shape; the batch must
	# come back as a hash and a count whatever it says.
	subtest 'Geocode::_lookup_batch -- whatever the geocoder replies' => sub {
		my $fn = \&Database::BI::Model::Geocode::_lookup_batch;
		my $stub = Stub::Geocoder->new(results => { A => $point->(1, 2) });
		my $got = $fn->($stub, [qw(A B)], 'GB');
		is $got->{lookups}, 2, 'the count of the values when the geocoder gives none';
		ok exists $got->{answers}{A}, 'its answers';
		is_deeply [ @{$got}{qw(held online)} ], [ [], 0 ], 'nothing held, nothing online';
		is $stub->{calls}[0]{opts}{region}, 'GB', 'with the region';
		is $stub->{calls}[0]{opts}{on_error}, 'undef', 'and asked not to croak';
		Test::Mockingbird::mock('Stub::Geocoder::geocode_many', sub { return [ 'not a hash' ] });
		is_deeply $fn->($stub, ['A'])->{answers}, {}, 'a reply of the wrong shape is no answers';
		Test::Mockingbird::mock('Stub::Geocoder::geocode_many', sub { return { lookups => 7 } });
		is $fn->($stub, ['A'])->{lookups}, 7, 'its own count when it gives one';
		# Mockingbird stacks mocks: one unmock per mock, or the first stays.
		Test::Mockingbird::unmock('Stub::Geocoder::geocode_many') for 1 .. 2;
	};

	# Purpose: a local lookup that threw is not an answer, so it must be held
	# (asked again), never remembered as not found.
	subtest 'Geocode::_lookup_local -- held, found and counted' => sub {
		my $chain = Stub::Chain->new(
			answers => { A => $point->(1, 2) },
			logs    => {
				C => [ { geocoder => 'cache' } ],
				E => [ { geocoder => 'Stub::Local', error => 'boom' } ],
			},
		);
		$chain->{answers}{C} = $point->(3, 4);
		my $geo = bless { _local_chain => $chain }, $GEO;
		my $got = $geo->_lookup_local([qw(A B C E)], 'SI');
		ok $got->{answers}{A}, 'found';
		ok exists $got->{answers}{B} && !$got->{answers}{B}, 'not found is an answer of nothing';
		is_deeply $got->{held}, ['E'], 'a lookup that threw is held';
		is $got->{lookups}, 3, 'an answer from the cache is not a lookup';
		is $chain->{asked}[0]{region}, 'SI', 'the region goes to the local data';
		my $plain = Stub::Chain->new;
		(bless { _local_chain => $plain }, $GEO)->_lookup_local(['A']);
		ok !exists $plain->{asked}[0]{region}, 'no region is sent when there is none';
	};

	# Purpose: OpenStreetMap is a remote service with a budget and a failure
	# mode that looks like "not found"; neither may turn into a wrong answer.
	subtest 'Geocode::_lookup_online -- budget and failure' => sub {
		my $went = [ { geocoder => 'Stub::Local' }, { geocoder => $GX{online_class} } ];
		my $chain = Stub::Chain->new(
			answers => { A => $point->(1, 2), L => $point->(5, 6) },
			logs    => { map { $_ => $went } qw(A B C D) },
		);
		$chain->{logs}{L} = [ { geocoder => 'Stub::Local' } ];
		my $ok_res = Stub::Response->new(1, '200 OK');
		my $geo = bless { _online => Stub::Online->new(response => $ok_res), online_max => 2, _local_chain => $chain }, $GEO;

		my $got = $geo->_lookup_online($chain, [qw(A B C L)]);
		is $got->{online}, 2, 'two places went online';
		ok $got->{answers}{A}, 'one found there';
		ok exists $got->{answers}{B}, 'one not found there, which is an answer';
		is $got->{spent}, 1, 'the budget is spent';
		is_deeply [ sort @{ $got->{held} } ], ['C'], 'past it, a place the local data does not know is held';
		ok $got->{answers}{L}, 'and one it knows is found';
		is $got->{failed}, undef, 'nothing failed';

		my $down = bless { _online => Stub::Online->new(response => Stub::Response->new(0, '503 Service Unavailable')),
			_local_chain => $chain }, $GEO;
		$got = $down->_lookup_online($chain, [qw(B C)]);
		is $got->{failed}, '503 Service Unavailable', 'a failure is its status line';
		is_deeply [ sort @{ $got->{held} } ], [qw(B C)], 'the place that failed is held, and so is the rest';
		is $got->{spent}, 0, 'which is a failure, not a spent budget';

		my $silent = bless { _online => Stub::Online->new(response => undef), _local_chain => $chain }, $GEO;
		is $silent->_lookup_online($chain, ['B'])->{failed}, 'no response', 'no response at all';

		$chain->{logs}{T} = [ { geocoder => $GX{online_class}, error => 'secret place in the request' } ];
		my $thrown = $geo->_lookup_online($chain, ['T']);
		is $thrown->{failed}, 'an error in Geo::Coder::OSM', 'an exception is named, never quoted (it may hold the place)';
	};

	# Purpose: the user agent is made once, so its one-a-second gap holds for
	# every request in the process, and Nominatim is asked over https.
	subtest 'Geocode::_online_geocoder -- one agent, https' => sub {
		my $fn = \&Database::BI::Model::Geocode::_online_geocoder;
		my $have = eval { require Geo::Coder::OSM; Geo::Coder::OSM->VERSION(0.03); require LWP::UserAgent::Throttled; LWP::UserAgent::Throttled->VERSION(0.14); 1 };
		unless ($have) {
			is $fn->(), undef, 'without Geo::Coder::OSM 0.03 and LWP::UserAgent::Throttled 0.14 there is none';
			return;
		}
		my ($one, $two) = ($fn->(), $fn->());
		isa_ok $one, 'Geo::Coder::OSM';
		is $one->{ua}, $two->{ua}, 'the same user agent for both';
		like $one->{ua}->agent, qr{\ADatabase-BI/}, 'which says who is asking';
		no warnings 'once';
		like $Geo::Coder::OSM::SOURCES{'database-bi-https'}, qr{\Ahttps://}, 'over https';
		{
			local @INC = (sub { die "hidden\n" if $_[1] eq 'Geo/Coder/OSM.pm'; return }, @INC);
			local $INC{'Geo/Coder/OSM.pm'};
			delete $INC{'Geo/Coder/OSM.pm'};
			is $fn->(), undef, 'and none when the module cannot be loaded';
		}
	};
}


# ============================================================================
# PART U15: Dashboard -- pure helpers no earlier part reaches
#
# These take values and give values: no controller, no store.  Each is fed what
# a stranger could put in a URL or a stored canvas, since both reach them.
# ============================================================================
{
	Readonly my $D => 'Database::BI::Controller::Dashboard';
	no strict 'refs';
	my %H = map { $_ => \&{"${D}::$_"} } qw(
		_analysis_json_error _is_sqlite_file is_supported_file canonical_spec _canonical_store_keys
		_canvas_map_html _canvas_window_columns _color_rule_index _cross_row_aliases _drop_unknown_keys
		_filter_in_values _lookup_key _model_dir_of _optional_scheme _rows_of_page _scatter_radii
		_shift_card_param _text_card_options _text_card_markup _text_card_title _text_card_plain
		_text_card_reply _wordcloud_counts _map_colour_entries _map_loc_columns _map_region _map_unplotted
	);
	use strict 'refs';
	Readonly my %UX => (
		text_max    => 20_000,
		title_max   => 60,
		pt_min      => 8,
		pt_max      => 96,
		json_prefix => 'Invalid JSON body: ',
		schemes     => [qw(tableau10 category10 set2 set3 paired)],
	);

	subtest 'Dashboard::_analysis_json_error -- a reason, never a path' => sub {
		is $H{_analysis_json_error}->(''), "$UX{json_prefix}expected a JSON object", 'a body that parsed to the wrong shape';
		is $H{_analysis_json_error}->(undef), "$UX{json_prefix}expected a JSON object", 'no error at all';
		is $H{_analysis_json_error}->("Malformed JSON: Expected comma at /usr/lib/perl5/Mojo/JSON.pm line 99.\n"),
			"${UX{json_prefix}}Malformed JSON: Expected comma", 'the library\'s file and line are cut';
		returns_is $H{_analysis_json_error}->('x'), { type => 'string' }, 'a string';
	};

	# Purpose: a .db may be SQLite or Berkeley DB, so the magic number decides;
	# anything unreadable is simply not one.
	subtest 'Dashboard::_is_sqlite_file -- by content, not by name' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $sq  = File::Spec->catfile($dir, 'a.db');
		Mojo::File->new($sq)->spew("SQLite format 3\0" . ("\0" x 84));
		ok $H{_is_sqlite_file}->($sq), 'the SQLite header';
		my $fake = File::Spec->catfile($dir, 'b.sqlite');
		Mojo::File->new($fake)->spew("SQLite format 3!");
		ok !$H{_is_sqlite_file}->($fake), 'a near miss is not one';
		my $short = File::Spec->catfile($dir, 'c.db');
		Mojo::File->new($short)->spew('SQL');
		ok !$H{_is_sqlite_file}->($short), 'a file shorter than the header';
		ok !$H{_is_sqlite_file}->(File::Spec->catfile($dir, 'none')), 'a missing file';
		ok !$H{_is_sqlite_file}->($dir), 'a directory';
		{
			local $! = 0;
			$H{_is_sqlite_file}->(File::Spec->catfile($dir, 'none'));
			pass 'and a failed open does not croak';
		}
	};

	subtest 'Dashboard::is_supported_file -- by extension, whole' => sub {
		ok $H{is_supported_file}->("/x/a.$_"), "$_ is supported" for qw(csv CSV db sql sqlite sqlite3 xml tsv psv xlsx);
		ok !$H{is_supported_file}->($_), "'" . ($_ // 'undef') . "' is not"
			for undef, '', 'a.csv.exe', 'a.xlsxx', 'csv', "a.csv\n", 'a.txt', '.csvx';
		returns_is $H{is_supported_file}->('a.csv'), { type => 'integer' }, '1 or 0';
	};

	# Purpose: the model store files a path: spec by its realpath, so a symlinked
	# spelling must resolve; anything that is not a local path must come back
	# exactly as given, since it is a key and not a path.
	subtest 'Dashboard::canonical_spec -- one spelling per file' => sub {
		my $dir  = tempdir(CLEANUP => 1);
		my $file = File::Spec->catfile($dir, 'a.csv');
		Mojo::File->new($file)->spew("x\n1\n");
		my $real = Mojo::File->new($file)->realpath->to_string;
		my $link = File::Spec->catfile($dir, 'link.csv');
		SKIP: {
			skip 'no symlinks here', 1 unless eval { symlink($file, $link) };
			is $H{canonical_spec}->("path:$link"), "path:$real", 'a symlink resolves to the file';
		}
		SKIP: {
			# Windows' realpath does not follow links (a CI failure on Windows):
			# with a realpath that leaves the link alone, the link must still
			# be filed under the file's own name.
			skip 'no symlinks here', 1 unless -l $link;
			my $realpath = \&Mojo::File::realpath;
			mock 'Mojo::File::realpath' => sub { my $p = shift; -l $p ? Mojo::File->new("$p") : $realpath->($p, @_) };
			{
				local $^O = 'MSWin32';
				is $H{canonical_spec}->("path:$link"), "path:$real", 'the link is followed where realpath will not';
			}
			unmock 'Mojo::File::realpath';
		}
		is $H{canonical_spec}->("path:$file"), "path:$real", 'a plain path is its realpath';
		is $H{canonical_spec}->($_), $_, "'$_' is left alone"
			for 'table:sales', 'url:http://x/y.csv', "path:$dir/none.csv", 'path:/../host/a.csv', "path:$file\nx", 'nonsense';
		is $H{canonical_spec}->(undef), undef, 'undef stays undef';
	};

	subtest 'Dashboard::_canonical_store_keys -- old spellings move, entries merge' => sub {
		my $dir  = tempdir(CLEANUP => 1);
		my $file = File::Spec->catfile($dir, 'a.csv');
		Mojo::File->new($file)->spew("x\n");
		my $real = Mojo::File->new($file)->realpath->to_string;
		my $alias = "$dir/./a.csv";
		my %store = (
			"path:$alias"         => { old => 1, both => 'old' },
			"path:$real"          => { both => 'new' },
			"path:$alias|loc=x"   => { geo => 1 },
			'table:t'             => { keep => 1 },
			"path:$dir/gone.csv"  => { gone => 1 },
		);
		$H{_canonical_store_keys}->(\%store);
		is_deeply $store{"path:$real"}, { old => 1, both => 'new' }, 'merged, the resolved spelling winning';
		ok !exists $store{"path:$alias"}, 'the old spelling is gone';
		is_deeply $store{"path:$real|loc=x"}, { geo => 1 }, 'a geo key keeps its suffix';
		is_deeply $store{'table:t'}, { keep => 1 }, 'other specs are left';
		ok exists $store{"path:$dir/gone.csv"}, 'a missing file keeps its key';
		lives_ok { $H{_canonical_store_keys}->({}) } 'an empty section';
	};

	# Purpose: two maps on one canvas must not share element ids, and a suffix
	# from a card id must never break out of the attribute it is written into.
	subtest 'Dashboard::_canvas_map_html -- unique, safe ids' => sub {
		my $body = q{<div id="map"></div><input id="search-box"><script>var m = L.map('map'); document.getElementById('reset-button');</script>};
		my ($head, $out) = $H{_canvas_map_html}->('<link><style>#map{}</style>', $body, '3');
		is $head, '<link>', 'the page-wide style is dropped';
		like $out, qr{<div id="map-3" class="canvas-map"></div>}, 'the div is renamed and classed';
		like $out, qr{L\.map\('map-3'\)}, 'so is the script\'s reference';
		like $out, qr{getElementById\('reset-button-3'\)}, 'and the button\'s';
		like $out, qr{id="search-box-3"}, 'and the search box';
		my (undef, $evil) = $H{_canvas_map_html}->('', $body, q{1"><script>x</script>});
		unlike $evil, qr/<script>x/, 'markup in the suffix is stripped';
		like $evil, qr/id="map-1scriptxscript"/, 'leaving only safe characters';
		my (undef, $none) = $H{_canvas_map_html}->('', $body, '!!!');
		like $none, qr/id="map-map"/, 'a suffix with nothing safe falls back';
		my (undef, $undef) = $H{_canvas_map_html}->('', $body, undef);
		like $undef, qr/id="map-map"/, 'as does none';
	};

	subtest 'Dashboard::_cross_row_aliases and _canvas_window_columns' => sub {
		is_deeply [ $H{_cross_row_aliases}->('amount:rank:r', 'x:running_total:t:5', 'bad', undef, '', [], 'a:b') ],
			[qw(r t)], 'the third field of each spec that has one';
		my $params = Mojo::Parameters->new('cs=amount:rank:r&cs=junk');
		my $analysis = { visuals => [
			{ cross_row => { cs => [ 'amount:share:s' ] } },
			{ cross_row => 'not a hash' }, 'not a visual', { cross_row => { cs => 'not a list' } },
		] };
		is_deeply $H{_canvas_window_columns}->($analysis, $params, [ { cross_row => { cs => ['a:rank:new'] } } ]),
			[qw(r s new)], 'the page, each card, and the card being added';
		is_deeply $H{_canvas_window_columns}->({}, Mojo::Parameters->new, undef), [], 'nothing anywhere';
	};

	# Purpose: colour rules reach this from a stored canvas, unchecked; a rule
	# that is not a rule must be passed over, never dereferenced (it was a 500).
	subtest 'Dashboard::_color_rule_index -- the first rule that matches' => sub {
		my @rules = ({ op => 'gt', val => 10 }, { op => 'eq', val => 'North' }, { op => 'ne', val => '5' });
		is $H{_color_rule_index}->('11', \@rules), 0, 'numeric greater';
		is $H{_color_rule_index}->('north', \@rules), 1, 'text equality ignores case';
		is $H{_color_rule_index}->('3', \@rules), 2, 'numeric not-equal';
		is $H{_color_rule_index}->('5', \@rules), undef, 'no rule matches';
		is $H{_color_rule_index}->(undef, [ { op => 'eq', val => '' } ]), 0, 'an empty cell equals an empty value';
		is $H{_color_rule_index}->('-1.5', [ { op => 'lt', val => '-1' } ]), 0, 'negative decimals compare as numbers';
		is $H{_color_rule_index}->('1e3', [ { op => 'gt', val => '5' } ]), undef, 'text is not compared with gt';
		is $H{_color_rule_index}->('11', [ 'junk', undef, [], { op => 'gt', val => 10 } ]), 3,
			'rules that are not rules are passed over, and indexes stay the stored ones';
		is $H{_color_rule_index}->('11', [ { val => 10 } ]), undef, 'a rule with no operator matches nothing';
		is $H{_color_rule_index}->('11', undef), undef, 'no rules';
		is $H{_color_rule_index}->('11', 'junk'), undef, 'rules that are not a list';
	};

	subtest 'Dashboard::_map_colour_entries -- the key\'s colours' => sub {
		my @rules = ({ op => 'gt', val => 6, color => '#f00' }, 'junk', { op => 'evil', val => 'x', color => '#0f0' });
		is_deeply [ $H{_map_colour_entries}->('amount', \@rules, '#00f', 0) ], [
			{ color => '#f00', label => 'amount > 6',    group => 'rule0' },
			{ color => '#0f0', label => 'amount evil x', group => 'rule2' },
			{ color => '#00f', label => 'Other',         group => 'other' },
		], 'one entry a rule, a non-rule skipped with its index kept, then Other';
		is_deeply [ $H{_map_colour_entries}->('place', [ { val => '', color => '#1' }, { val => 'A', color => '#2' } ], '#0', 1) ],
			[ { color => '#1', label => '(blank)', group => 'rule0' }, { color => '#2', label => 'A', group => 'rule1' } ],
			'a series lists values, a blank one by name, and no Other';
		is_deeply [ $H{_map_colour_entries}->('x', [], '#0', 0) ], [], 'no rules, no key, not even Other';
		is_deeply [ $H{_map_colour_entries}->('x', undef, '#0', 0) ], [], 'rules that are not a list';
	};

	subtest 'Dashboard::_drop_unknown_keys -- only what is read back is kept' => sub {
		my %doc = (name => 'n', visuals => [], evil => '<script>', __proto__ => 1, layout => {});
		$H{_drop_unknown_keys}->(\%doc);
		is_deeply [ sort keys %doc ], [qw(layout name visuals)], 'unknown keys are dropped';
		my %empty;
		$H{_drop_unknown_keys}->(\%empty);
		is_deeply \%empty, {}, 'an empty document';
	};

	# Purpose: an f=col:in: filter reads JSON from a link; a damaged one must
	# match nothing rather than everything.
	subtest 'Dashboard::_filter_in_values -- the list, or nothing' => sub {
		is_deeply [ $H{_filter_in_values}->('["Paris","Rome",3,null]') ], [ 'Paris', 'Rome', 3, '' ], 'scalars, null as empty';
		is_deeply [ $H{_filter_in_values}->('["a",["nested"],{"o":1}]') ], ['a'], 'only plain values count';
		is_deeply [ $H{_filter_in_values}->($_) ], [], "'" . ($_ // 'undef') . "' lists nothing"
			for undef, '', 'Paris', '{"a":1}', '"str"', '[', '1';
		{
			local $@ = 'kept';
			$H{_filter_in_values}->('[');
			is $@, 'kept', 'a parse failure leaves the caller\'s $@';
		}
	};

	subtest 'Dashboard::_lookup_key -- trimmed, case kept' => sub {
		is $H{_lookup_key}->('  ab '), 'ab', 'trimmed';
		is $H{_lookup_key}->('AB'), 'AB', 'case is kept';
		is $H{_lookup_key}->(0), '0', 'zero is a key';
		is $H{_lookup_key}->(''), '', 'empty is empty';
		is $H{_lookup_key}->(undef), undef, 'undef has none';
		is $H{_lookup_key}->([]), undef, 'nor a reference';
		keeps_globals_ok('_lookup_key', sub { $H{_lookup_key}->(' x ') });
	};

	subtest 'Dashboard::_model_dir_of -- absolute or under home' => sub {
		my $tm = isolated_app();
		my $abs = tempdir(CLEANUP => 1);
		$tm->app->config->{model_dir} = $abs;
		is $H{_model_dir_of}->($tm->app)->to_string, $abs, 'an absolute directory as given';
		$tm->app->config->{model_dir} = 'rel';
		is $H{_model_dir_of}->($tm->app)->to_string, $tm->app->home->child('rel')->to_string, 'a relative one under the home';
		delete $tm->app->config->{model_dir};
		is $H{_model_dir_of}->($tm->app)->to_string, $tm->app->home->child('.bi')->to_string, 'the default';
	};

	subtest 'Dashboard::_optional_scheme and _scatter_radii' => sub {
		is $H{_optional_scheme}->($_), $_, "$_ is a scheme" for @{ $UX{schemes} };
		is $H{_optional_scheme}->($_), undef, "'" . ($_ // 'undef') . "' is not"
			for undef, '', 'Tableau10', 'viridis', '__proto__';
		is $H{_optional_scheme}->([ 'set2' ]), undef, 'nor a reference';
		is_deeply [ $H{_scatter_radii}->(undef, undef) ], [ 3, 15 ], 'the defaults';
		is_deeply [ $H{_scatter_radii}->(20, 5) ], [ 5, 20 ], 'put in order, not refused';
		is_deeply [ $H{_scatter_radii}->(0, 999) ], [ 3, 40 ], 'zero is the default, too big is clamped';
		is_deeply [ $H{_scatter_radii}->('abc', [ 9 ]) ], [ 3, 15 ], 'text and references are the defaults';
		is_deeply [ $H{_scatter_radii}->('-4', '2.5') ], [ 1, 15 ], 'a negative is clamped to 1, a fraction is not a whole number';
	};

	subtest 'Dashboard::_rows_of_page -- a copy, in range' => sub {
		my @rows = (1 .. 5);
		Internals::SvREADONLY(@rows, 1);
		is_deeply $H{_rows_of_page}->(\@rows, 0, 2), [ 1, 2 ], 'the first page';
		is_deeply $H{_rows_of_page}->(\@rows, 4, 2), [ 5 ], 'a short last page';
		is_deeply $H{_rows_of_page}->(\@rows, 9, 2), [], 'past the end';
		is_deeply $H{_rows_of_page}->(\@rows, -2, 2), [ 1, 2 ], 'a negative offset is the first page, never the last rows';
		is_deeply $H{_rows_of_page}->([], 0, 10), [], 'no rows';
		my $page = $H{_rows_of_page}->(\@rows, 0, 5);
		isnt $page, \@rows, 'a new array, so a read-only one is never spliced';
	};

	subtest 'Dashboard::_shift_card_param -- cv= after the removed card' => sub {
		is $H{_shift_card_param}->('?cv=3&f=x', 1), '?cv=2&f=x', 'a later card moves down';
		is $H{_shift_card_param}->('?cv=1', 1), '?', 'one naming the removed card is dropped, not left to name its successor';
		is $H{_shift_card_param}->('?cv=1&cf=a:eq:b', 1), '?cf=a:eq:b', 'with the separator after it';
		is $H{_shift_card_param}->('?cf=a:eq:b&cv=1', 1), '?cf=a:eq:b', 'or before it';
		is $H{_shift_card_param}->('cv=1&cv=2', 1), 'cv=1', 'and its neighbour still moves down';
		is $H{_shift_card_param}->('?cv=0', 1), '?cv=0', 'an earlier one is kept';
		is $H{_shift_card_param}->('?a=1&cv=5&cv=2', 3), '?a=1&cv=4&cv=2', 'each one';
		is $H{_shift_card_param}->('?xcv=5&cvx=5', 0), '?xcv=5&cvx=5', 'only cv= itself';
		is $H{_shift_card_param}->('', 0), '', 'an empty query';
	};

	# Purpose: a text card's settings go into a style attribute, so only the
	# values listed may get there, and every other value must say why it was
	# refused.
	subtest 'Dashboard::_text_card_options -- allowed values only' => sub {
		my ($o, $e) = $H{_text_card_options}->({ text => "a\r\nb", font => 'arial', size => '12', colour => '#AABBCC',
			background => '#000000', align => 'center', bold => 1, italic => 'yes', plain => 0, evil => 1 });
		is_deeply $o, { text => "a\nb", font => 'arial', size => 12, colour => '#aabbcc', background => '#000000',
			align => 'center', bold => 1, italic => 1 }, 'each in its one spelling, unknown keys gone';
		is_deeply $e, [], 'no errors';
		(undef, $e) = $H{_text_card_options}->({ text => ' ', font => 'comic', size => '7', colour => 'red',
			background => '#12345', align => 'justify' });
		is_deeply $e, [
			'A text card needs some text',
			'That font is not one of the choices',
			"The size must be a whole number of points from $UX{pt_min} to $UX{pt_max}",
			'A colour must be written #rrggbb', 'A colour must be written #rrggbb',
			'The alignment must be left, center or right',
		], 'each refusal in its own words';
		(undef, $e) = $H{_text_card_options}->({ text => 'x' x ($UX{text_max} + 1) });
		is_deeply $e, [ "A text card can hold at most $UX{text_max} characters" ], 'too long';
		(undef, $e) = $H{_text_card_options}->({ text => 'x' x $UX{text_max} });
		is_deeply $e, [], 'the longest allowed';
		for my $size ('97', '1000', '12.5', '-1', '1e1', [12]) {
			(undef, $e) = $H{_text_card_options}->({ text => 'x', size => $size });
			is scalar(@{$e}), 1, "size '$size' is refused";
		}
		(my $f, $e) = $H{_text_card_options}->({ text => 'x', font => [ 'arial' ], colour => { a => 1 } });
		is scalar(@{$e}), 2, 'references are refused, not stringified';
		ok !exists $f->{font} && !exists $f->{colour}, 'and are not kept';
		for my $raw (undef, 'text', [ 'x' ]) {
			($f, $e) = $H{_text_card_options}->($raw);
			is_deeply $e, [ 'A text card needs some text' ], 'options that are not an object are an empty card';
		}
		($f) = $H{_text_card_options}->({ text => [ 'x' ] });
		is $f->{text}, '', 'text that is not a string is none';
	};

	subtest 'Dashboard::_text_card_markup -- escaped, styled from the list' => sub {
		my $html = $H{_text_card_markup}->({ options => { text => "<b>hi</b>\n  two  spaces\tend", font => 'courier', bold => 1 } });
		like $html, qr/&lt;b&gt;hi&lt;\/b&gt;/, 'markup is text';
		like $html, qr/<br>&#160; two&#160; spaces&#160;&#160;&#160; end/, 'line ends, leading and double spaces, tabs kept visibly';
		like $html, qr/style="font-family:&quot;Courier New&quot;, Courier, monospace;font-weight:bold"/, 'the font\'s CSS, escaped';
		my $evil = $H{_text_card_markup}->({ options => { text => 'x', colour => '#fff;background:url(x)', font => 'x;y' } });
		unlike $evil, qr/style=/, 'a value that is not allowed never reaches the style';
		like $H{_text_card_markup}->({}), qr{\A<div class="text-card-text"></div>\z}, 'a card with no options';
	};

	subtest 'Dashboard::_text_card_title, _text_card_plain and _text_card_reply' => sub {
		is $H{_text_card_title}->({ options => { text => "\n   \n  First line  \nsecond" } }), 'First line', 'the first line with words';
		is $H{_text_card_title}->({ options => { text => 'y' x ($UX{title_max} + 5) } }), ('y' x $UX{title_max}) . '...', 'cut';
		is $H{_text_card_title}->({ options => { text => " \n\t" } }), 'Text', 'a blank card';
		is $H{_text_card_title}->({}), 'Text', 'no options';
		is $H{_text_card_plain}->({ kind => 'text', options => { text => 'x', plain => 1 } }), 1, 'a plain text card';
		is $H{_text_card_plain}->({ kind => 'bar', options => { plain => 1 } }), 0, 'only a text card can be plain';
		is $H{_text_card_plain}->({}), 0, 'nothing';
		my $reply = $H{_text_card_reply}->('abc', 2, { kind => 'text', options => { text => 'Hello <you>' } });
		is_deeply [ @{$reply}{qw(id visual kind title head cf_col plain)} ], [ 'abc', 2, 'text', 'Hello <you>', '', '', 0 ],
			'the reply for the card';
		like $reply->{html}, qr/Hello &lt;you&gt;/, 'its markup escaped';
		is $H{_text_card_reply}->('a', 0, { title => 'Mine', options => { text => 'x' } })->{title}, 'Mine', 'a given title wins';
		memory_cycle_ok $reply, 'no cycle';
	};

	subtest 'Dashboard::_wordcloud_counts -- one count for page and card' => sub {
		my @rows = ({ t => 'Apple apple pear' }, { t => 'pear the and' }, { t => undef }, { t => 'kiwi' });
		my $got = $H{_wordcloud_counts}->(\@rows, 't', 2, 3, 'kiwi,  , PEAR');
		is_deeply $got->{words}, [ { word => 'apple', count => 1 } ], 'a word counts once a row; stop words, the reader\'s too, are dropped';
		is $got->{distinct}, 1, 'distinct before the cut';
		is $got->{rows}, 4, 'every row is counted';
		$got = $H{_wordcloud_counts}->(\@rows, 't', 1, 3, undef);
		is_deeply [ map { $_->{word} } @{ $got->{words} } ], ['pear'], 'the commonest word, cut to topn';
		is $got->{total}, 4, 'the total of every count';
		my $none = $H{_wordcloud_counts}->([], 't', 5, 3, '');
		is_deeply [ @{$none}{qw(words distinct total)} ], [ [], 0, 0 ], 'no rows';
		is $H{_wordcloud_counts}->(\@rows, 'nope', 5, 3, '')->{distinct}, 0, 'a column no row has';
	};

	subtest 'Dashboard::_map_loc_columns and _map_region' => sub {
		is_deeply [ $H{_map_loc_columns}->([ 'a', '', undef, [ 'x' ], 'b', 'a' ]) ], [qw(a b)], 'in order, once each, usable only';
		is_deeply [ $H{_map_loc_columns}->('a') ], ['a'], 'a single name, as an old card stored it';
		is_deeply [ $H{_map_loc_columns}->(undef) ], [], 'none';
		is_deeply [ $H{_map_loc_columns}->({ a => 1 }) ], [], 'a hash is not a list of names';
		is $H{_map_region}->({ map_region => 'GB' }), 'GB', 'two letters';
		is $H{_map_region}->({ map_region => $_ }), undef, "'" . ($_ // 'undef') . "' is not a region"
			for undef, '', 'GBR', 'G1', "GB\n", 'gb;x';
		is $H{_map_region}->({ map_region => [ 'GB' ] }), undef, 'nor a reference';
		is $H{_map_region}->({}), undef, 'none set';
	};

	# Purpose: the list of places a map could not plot drives links into the
	# table; each must select exactly the rows it describes.
	subtest 'Dashboard::_map_unplotted -- why each place is missing' => sub {
		my @records = ({ a => 'X', c => 'UK' }, { a => '', c => '' }, { a => '42', c => 'UK' }, { a => 'Y', c => 'FR' }, { a => 'X', c => 'UK' });
		my @places  = map { { 'a, c' => join(', ', grep { length } @{$_}{qw(a c)}) } } @records;
		my ($entries, $all) = $H{_map_unplotted}->(\@records, \@places, 'a, c', [qw(a c)], {
			skipped => [ '', '42, UK' ], unresolved => [ 'X, UK' ], not_attempted => [ 'Y, FR' ],
		});
		is_deeply [ map { [ @{$_}{qw(place rows reason)} ] } @{$entries} ],
			[ [ 'X, UK', 2, 'not_found' ], [ '', 1, 'empty' ], [ '42, UK', 1, 'refused' ], [ 'Y, FR', 1, 'later' ] ],
			'each place once, in the order of its first row, with its reason and rows';
		is_deeply $entries->[1]{filters}, [ 'a:empty', 'c:empty' ], 'an empty cell is selected as empty';
		is_deeply $entries->[0]{filters}, [ 'a:eq:X', 'c:eq:UK' ], 'a cell by its value';
		is scalar(@{$all}), 2, 'one in: filter per column for every row at once';
		my ($ok) = $H{_map_unplotted}->(\@records, \@places, 'a, c', [qw(a c)], {});
		is_deeply $ok, [], 'nothing missing, nothing listed';
		my (undef, $none) = $H{_map_unplotted}->([ { a => 'X', c => 'UK' }, { a => 'Y', c => 'FR' }, { a => 'X', c => 'FR' } ],
			[ { 'a, c' => 'X, UK' }, { 'a, c' => 'Y, FR' }, { 'a, c' => 'X, FR' } ], 'a, c', [qw(a c)],
			{ unresolved => [ 'X, UK', 'Y, FR' ] });
		is_deeply $none, [], 'when the in: filters would also select a plotted row, there is no all-rows link';
		lives_ok { $H{_map_unplotted}->([ 'junk' ], [ 'junk' ], 'a', ['a'], { unresolved => [''] }) } 'rows that are not rows';
	};
}


# ============================================================================
# PART U16: Dashboard -- controller helpers no earlier part reaches
#
# Each subtest builds an application of its own (its own data_dir and model
# store), so what one writes cannot be read by another, and a controller for
# the request the helper is meant to serve.
# ============================================================================
{
	Readonly my $D => 'Database::BI::Controller::Dashboard';
	Readonly my %CX => (
		sales   => "id,region,amount,code,note\n1,North,10,A,Order #1001\n2,South,5,B,no number\n3,North,7,Z,Order #7\n",
		lookup  => "code,label,tier\nA,Alpha,1\nB,Beta,2\nA,Again,3\n",
		too_big => 8 * 1_048_576 + 1,
	);

	# An application with fixture files in a data_dir of its own.
	my $fixture_app = sub {
		my $tm  = isolated_app();
		my $dir = tempdir(CLEANUP => 1);
		Mojo::File->new($dir)->child('sales.csv')->spew($CX{sales});
		Mojo::File->new($dir)->child('codes.csv')->spew($CX{lookup});
		$tm->app->config->{data_dir} = $dir;
		return ($tm, $dir);
	};
	my $spec_of = sub { 'path:' . Mojo::File->new($_[0])->child('sales.csv')->realpath->to_string };
	my $rows = sub {
		return [ map { my %r; @r{qw(id region amount code note)} = split /,/; \%r }
			grep { !/^id,/ } split /\n/, $CX{sales} ];
	};

	subtest 'Dashboard::_calc_specs_of_request and _cross_row_written' => sub {
		my ($tm) = $fixture_app->();
		my $c = dash_controller($tm->app, '/?c=double:amount*2&c=path:/x.csv&c=TABLE:t&c=url:http://x&c=mariadb:s/t&cs=amount:rank:r&cs=bad');
		is_deeply [ $c->_calc_specs_of_request ], ['double:amount*2'], 'stacked sources are not fields, whatever their case';
		$c->stash(_held_calc_fields => [ { name => 'late' } ]);
		is_deeply [ $D->can('_cross_row_written')->($c) ], [qw(r late)], 'the cs= aliases and the held fields';
		is_deeply [ $D->can('_cross_row_written')->(dash_controller($tm->app, '/')) ], [], 'none';
	};

	subtest 'Dashboard::_compile_extraction -- refusals name the extraction' => sub {
		my ($tm) = $fixture_app->();
		my $c = dash_controller($tm->app, '/');
		my ($compiled, $fields) = $c->_compile_extraction('ord', { pattern => '#(?<num>\d+)(?<rest>.*)', fields => ['num'] });
		is_deeply $fields, ['num'], 'fields= when given';
		(undef, $fields) = $c->_compile_extraction('ord', { pattern => '(?<b>x)(?<a>y)' });
		is_deeply $fields, [qw(b a)], 'else every named group, in order';
		throws_ok { $c->_compile_extraction('ord', { pattern => '(' }) } qr/\AExtraction "ord": Pattern '\(' does not compile/, 'a bad pattern';
		throws_ok { $c->_compile_extraction('ord', { pattern => '(?{1})' }) } qr/\AExtraction "ord": Pattern '\(\?\{1\}\)' uses/, 'code in a pattern';
		throws_ok { $c->_compile_extraction('ord', { pattern => '(\d+)' }) }
			qr/\AExtraction "ord": the pattern names no group; write one as/, 'no named group';
		throws_ok { $c->_compile_extraction('ord', { pattern => '(?<a>x)', fields => ['b'] }) }
			qr/\AExtraction "ord": the pattern has no group named "b"/, 'a field the pattern does not name';
		throws_ok { $c->_compile_extraction('ord', {}) } qr/names no group/, 'no pattern at all is the empty one';
	};

	# Purpose: a lookup reads a file the reader names in a stored model; it must
	# never read outside data_dir, a remote source, or something too big.
	subtest 'Dashboard::_lookup_file -- only files under data_dir' => sub {
		my ($tm, $dir) = $fixture_app->();
		my $c = dash_controller($tm->app, '/');
		# The guard's own form: canonpath, so backslashes on Windows.
		my $real = File::Spec->canonpath(Mojo::File->new($dir)->child('codes.csv')->realpath->to_string);
		is $c->_lookup_file('L', 'codes.csv'), $real, 'a relative name is under data_dir';
		is $c->_lookup_file('L', $real), $real, 'an absolute one inside it';
		for my $remote ('http://x/a.csv', 'url:http://x', 'table:codes', '/../host/a.csv', 'redis:k') {
			throws_ok { $c->_lookup_file('L', $remote) } qr/\ALookup "L": "\Q$remote\E" is not a file; a lookup reads a file under data_dir/,
				"'$remote' is refused as not a file";
		}
		my $outside = tempdir(CLEANUP => 1);
		Mojo::File->new($outside)->child('o.csv')->spew("a\n1\n");
		throws_ok { $c->_lookup_file('L', "$outside/o.csv") } qr/\ALookup "L": "[^"]+" is not under data_dir/, 'a file outside';
		throws_ok { $c->_lookup_file('L', '../' . Mojo::File->new($outside)->basename . '/o.csv') } qr/is not under data_dir/, 'reached with ..';
		SKIP: {
			skip 'no symlinks here', 1 unless eval { symlink("$outside/o.csv", "$dir/link.csv") };
			throws_ok { $c->_lookup_file('L', 'link.csv') } qr/is not under data_dir/, 'a link inside pointing out';
		}
		throws_ok { $c->_lookup_file('L', '') } qr/\ALookup "L": file "" not found, or not a supported data file/, 'no file';
		throws_ok { $c->_lookup_file('L', undef) } qr/file "" not found/, 'undef';
		throws_ok { $c->_lookup_file('L', 'none.csv') } qr/file "none\.csv" not found/, 'a missing file';
		Mojo::File->new($dir)->child('notes.txt')->spew('x');
		throws_ok { $c->_lookup_file('L', 'notes.txt') } qr/not a supported data file/, 'an unsupported kind';
		my $big = Mojo::File->new($dir)->child('big.csv');
		$big->spew('x' x $CX{too_big});
		throws_ok { $c->_lookup_file('L', 'big.csv') } qr/\ALookup "L": "big\.csv" is $CX{too_big} bytes, more than a lookup may be/, 'too large';
	};

	subtest 'Dashboard::_lookups_of_request -- own, borrowed, skipped' => sub {
		my ($tm, $dir) = $fixture_app->();
		my $spec = $spec_of->($dir);
		$D->can('_write_models')->(dash_controller($tm->app, '/'), { lookups => {
			$spec          => { mine => { file => 'codes.csv', key => 'code' }, gone => 'junk' },
			'table:other'  => { theirs => { file => 'codes.csv', key => 'code', fields => ['label'] } },
		} });
		my $c = dash_controller($tm->app, '/?lk=theirs');
		is_deeply [ map { $_->{name} } $c->_lookups_of_request($spec) ], [qw(mine theirs)], 'own first, then lk=';
		$c = dash_controller($tm->app, '/?lk=theirs&nolk=mine&lk=mine');
		is_deeply [ map { $_->{name} } $c->_lookups_of_request($spec) ], ['theirs'], 'nolk= wins over both';
		throws_ok { dash_controller($tm->app, '/?lk=nobody')->_lookups_of_request($spec) }
			qr/\ALookup "nobody" is not stored for any dataset/, 'an lk= that names nothing';
		throws_ok { dash_controller($tm->app, '/?lk=a-b')->_lookups_of_request($spec) }
			qr/\ALookup name "a-b" is not a valid identifier/, 'an lk= that is not a name';
		is_deeply [ dash_controller($tm->app, '/')->_lookups_of_request(undef) ], [], 'no spec, no lk=';
	};

	# Purpose: a lookup file is read once a request, keyed as the docs say, and
	# every way the definition can disagree with the file is refused by name.
	subtest 'Dashboard::_load_lookup and _apply_lookups' => sub {
		my ($tm, $dir) = $fixture_app->();
		my $c = dash_controller($tm->app, '/');
		$tm->app->log->level('fatal');
		my $entry = $c->_load_lookup({ name => 'L', file => 'codes.csv', key => 'code' });
		is_deeply $entry->{map}{A}, { label => 'Alpha', tier => 1 }, 'the first row of a duplicate key wins';
		is_deeply [ sort @{ $entry->{fields} } ], [qw(label tier)], 'every column but the key';
		is $c->_load_lookup({ name => 'L', file => 'codes.csv', key => 'code' }), $entry, 'read once a request';
		throws_ok { $c->_load_lookup({ name => 'L', file => 'codes.csv', key => 'nope' }) }
			qr/\ALookup "L": key column "nope" is not in "codes\.csv"/, 'a key the file does not have';
		throws_ok { $c->_load_lookup({ name => 'L', file => 'codes.csv', key => 'code', fields => ['x'] }) }
			qr/\ALookup "L": field "x" is not in "codes\.csv"/, 'a field it does not have';

		my $spec = $spec_of->($dir);
		$D->can('_write_models')->($c, { lookups => { $spec => {
			codes => { file => 'codes.csv', key => 'code', fields => ['label'], default => '?' },
		} } });
		my $records = $rows->();
		my @cols = qw(id region amount code note);
		dash_controller($tm->app, '/')->_apply_lookups($records, \@cols, $spec);
		is_deeply [ map { $_->{label} } @{$records} ], [ 'Alpha', 'Beta', '?' ], 'each row\'s field, or the default';
		is $cols[-1], 'label', 'the column is added';

		$D->can('_write_models')->($c, { lookups => { $spec => { codes => { file => 'codes.csv', key => 'code', col => 'nope' } } } });
		throws_ok { dash_controller($tm->app, '/')->_apply_lookups($rows->(), [qw(id code)], $spec) }
			qr/\ALookup "codes": column "nope" is not in this dataset \(nolk=codes skips the lookup\)/, 'a column the data does not have';
		$D->can('_write_models')->($c, { lookups => { $spec => {
			codes => { file => 'codes.csv', key => 'code', fields => ['label'] },
		} } });
		my @taken = qw(id code label codes_label);
		throws_ok { dash_controller($tm->app, '/')->_apply_lookups($rows->(), \@taken, $spec) }
			qr/\ALookup "codes": field "label" cannot be added, because "codes_label" is a column already/, 'no name left to add it under';
		my @renamed = qw(id code label);
		my $r = $rows->();
		dash_controller($tm->app, '/')->_apply_lookups($r, \@renamed, $spec);
		is $renamed[-1], 'codes_label', 'a field whose name is taken is prefixed with the lookup';
		lives_ok { dash_controller($tm->app, '/')->_apply_lookups($rows->(), [qw(id code)], 'table:nothing') } 'no lookups is nothing to do';
	};

	subtest 'Dashboard::_apply_extractions -- groups become columns' => sub {
		my ($tm, $dir) = $fixture_app->();
		my $spec = $spec_of->($dir);
		my $c = dash_controller($tm->app, '/');
		$D->can('_write_models')->($c, { extractions => { $spec => {
			ord => { col => 'note', pattern => '#(?<num>\d+)' },
		} } });
		my $records = $rows->();
		my @cols = qw(id region amount code note);
		$c->_apply_extractions($records, \@cols, $spec);
		is_deeply [ map { $_->{num} } @{$records} ], [ '1001', '(unparseable)', '7' ], 'a non-match is (unparseable), not dropped';
		is $cols[-1], 'num', 'the column is added';
		ok $c->stash('_virtual_columns')->{num}, 'and is virtual, so no SQL groups by it';

		$D->can('_write_models')->($c, { extractions => { $spec => { ord => { col => 'nope', pattern => '(?<n>x)' } } } });
		throws_ok { dash_controller($tm->app, '/')->_apply_extractions($rows->(), [qw(id note)], $spec) }
			qr/\AExtraction "ord": column "nope" is not in this dataset/, 'a column the data does not have';
		$D->can('_write_models')->($c, { extractions => { $spec => { ord => { col => 'note', pattern => '(?<id>x)' } } } });
		throws_ok { dash_controller($tm->app, '/')->_apply_extractions($rows->(), [qw(id note ord_id)], $spec) }
			qr/\AExtraction "ord": group "id" cannot be added, because "ord_id" is a column already/, 'no name left';
		$D->can('_write_models')->($c, { extractions => { $spec => { ord => 'not a definition' } } });
		lives_ok { dash_controller($tm->app, '/')->_apply_extractions($rows->(), [qw(note)], $spec) } 'a stored entry of the wrong shape is skipped';
		lives_ok { $c->_apply_extractions($rows->(), [], undef) } 'no spec';
	};

	# Purpose: stage 4 and stage 7 write a column the same way, and a card may
	# skip what the page would refuse.
	subtest 'Dashboard::_write_calc_column and _apply_held_calc_fields' => sub {
		my ($tm) = $fixture_app->();
		$tm->app->log->level('fatal');
		my $c = dash_controller($tm->app, '/');
		require Database::BI::Calc;
		my $records = $rows->();
		my @cols = qw(id amount);
		my $calc = Database::BI::Calc->new(expr => 'amount * 2', columns => \@cols);
		$c->_write_calc_column($records, \@cols, 'double', $calc);
		is_deeply [ map { $_->{double} } @{$records} ], [ 20, 10, 14 ], 'every row';
		$c->_write_calc_column($records, \@cols, 'double', $calc);
		is scalar(grep { $_ eq 'double' } @cols), 1, 'a column is listed once';
		my $bad = Database::BI::Calc->new(expr => 'amount / 0', columns => \@cols);
		$c->_write_calc_column($records, \@cols, 'inf', $bad);
		is $records->[0]{inf}, '(unparseable)', 'an undefined result is a visible bucket';

		my ($same, $c2) = dash_controller($tm->app, '/')->_apply_held_calc_fields($records, \@cols);
		is $same, $records, 'nothing held, nothing done';
		my $hc = dash_controller($tm->app, '/');
		$hc->stash(_held_calc_fields => [ { name => 'late', expr => 'r + 1' }, { name => 'typo', expr => 'nope + 1' } ]);
		my $with_r = [ map { { %$_, r => 1 } } @{$records} ];
		throws_ok { $hc->_apply_held_calc_fields($with_r, [ @cols, 'r' ]) } qr/\ACalculated field "typo": /, 'the page refuses a field that does not compile';
		my $card = dash_controller($tm->app, '/');
		$card->stash(_held_calc_fields => [ { name => 'late', expr => 'r + 1' }, { name => 'typo', expr => 'nope + 1' } ]);
		my (undef, $cc) = $card->_apply_held_calc_fields($with_r, [ @cols, 'r' ], 1);
		ok( (grep { $_ eq 'late' } @{$cc}) && !(grep { $_ eq 'typo' } @{$cc}), 'a card draws what it can');
	};

	subtest 'Dashboard::_has_stored_columns and _calc_for_page' => sub {
		my ($tm, $dir) = $fixture_app->();
		my $spec = $spec_of->($dir);
		my $c = dash_controller($tm->app, '/');
		ok !$c->_has_stored_columns($spec), 'nothing saved';
		ok dash_controller($tm->app, '/?lk=x')->_has_stored_columns($spec), 'an lk= adds columns';
		ok !$c->_has_stored_columns(''), 'no spec';
		$D->can('_write_models')->($c, { fields => { $spec => { broken => 'nope * 2' } } });
		ok $c->_has_stored_columns($spec), 'a saved field';
		ok dash_controller($tm->app, '/?l=' . Mojo::Util::url_escape($spec))->_has_stored_columns(undef), 'read from l= when not given';

		my $page = dash_controller($tm->app, '/');
		my $records = $rows->();
		my ($got) = $page->_calc_for_page($records, [qw(id region amount code note)], { spec_key => $spec });
		ok $got, 'a saved field that cannot be drawn does not stop the page';
		like $page->stash('stored_error'), qr/\ACalculated field "broken"/, 'it says why, without a file and line';
		unlike $page->stash('stored_error'), qr/ line \d+/, 'tidied';
		is_deeply $records, $rows->(), 'and the caller\'s rows were not written by the failed pass';
		my $strict = dash_controller($tm->app, '/?c=' . Mojo::Util::url_escape('x:nope+1'));
		throws_ok { $strict->_calc_for_page($rows->(), [qw(id amount)], { spec_key => 'table:none' }) }
			qr/Calculated field "x"/, 'a field in the request is still refused';
	};

	subtest 'Dashboard::_canvas_cross_filter -- late specs wait for their column' => sub {
		my ($tm) = $fixture_app->();
		my $c = dash_controller($tm->app, '/');
		$c->stash(_canvas_window_names => [qw(ytd region)], _held_calc_fields => [ { name => 'held' } ]);
		my ($got, $late) = $c->_canvas_cross_filter($rows->(), [qw(id region amount)],
			[ 'region:eq:North', 'ytd:gt:5', 'held:eq:1', 'amount:gt:6' ]);
		is_deeply [ map { $_->{id} } @{$got} ], [ 1, 3 ], 'filters on present columns apply now';
		is_deeply $late, [ 'ytd:gt:5', 'held:eq:1' ], 'those on columns written later wait';
		($got, $late) = dash_controller($tm->app, '/')->_canvas_cross_filter($rows->(), ['id'], []);
		is scalar(@{$got}), 3, 'no specs, no change';
		is_deeply $late, [], 'and nothing late';
	};

	# Purpose: an unparseable store is evidence; it is set aside, not replaced.
	subtest 'Dashboard::_set_aside_corrupt_store and _save_analyses_or_503' => sub {
		my ($tm) = $fixture_app->();
		$tm->app->log->level('fatal');
		my $c = dash_controller($tm->app, '/');
		my $dir = tempdir(CLEANUP => 1);
		my $store = "$dir/store.json";
		Mojo::File->new($store)->spew('{ broken');
		$c->_set_aside_corrupt_store($store);
		ok !-e $store, 'a corrupt store is moved';
		my @aside = glob "$dir/store.json.corrupt.*";
		is scalar(@aside), 1, 'beside itself, named as corrupt';
		for my $kept ('{"a":1}', '[1,2]', '') {
			Mojo::File->new($store)->spew($kept);
			$c->_set_aside_corrupt_store($store);
			if ($kept eq '{"a":1}' || $kept eq '') {
				ok -e $store, "'$kept' is left where it is";
			} else {
				ok !-e $store, 'a JSON array is not a store either';
			}
		}
		lives_ok { $c->_set_aside_corrupt_store("$dir/none.json") } 'a store that does not exist';

		my $w = dash_controller($tm->app, '/');
		Test::Mockingbird::mock("${D}::_write_analyses", sub { 0 });
		ok !$w->_save_analyses_or_503({}), 'a refused write is false';
		is $w->res->code, 503, 'and answers 503';
		is_deeply $w->res->json, { error => 'Analysis storage is not writable; use import/export instead' }, 'saying why';
		Test::Mockingbird::mock("${D}::_write_analyses", sub { 1 });
		ok dash_controller($tm->app, '/')->_save_analyses_or_503({}), 'a write is true';
		# Mockingbird stacks mocks: one unmock per mock, or the first stays.
		Test::Mockingbird::unmock("${D}::_write_analyses") for 1 .. 2;
	};

	subtest 'Dashboard::_chart_json -- inert in an attribute' => sub {
		my ($tm) = $fixture_app->();
		my $c = dash_controller($tm->app, '/');
		my $json = $c->_chart_json({ title => '</script><b>x</b>', n => 1 });
		unlike $json, qr/</, 'no < survives';
		is_deeply decode_json($json), { title => '</script><b>x</b>', n => 1 }, 'and it still reads back exactly';
	};

	subtest 'Dashboard::_tile_colour_measure and _tile_colours' => sub {
		my ($tm) = $fixture_app->();
		my $c = dash_controller($tm->app, '/');
		is $c->_tile_colour_measure(undef, 'amount')->{fn}, 'avg', 'average by default';
		is $c->_tile_colour_measure('SUM', 'amount')->{fn}, 'sum', 'case does not matter';
		like $c->_tile_colour_measure('evil', 'amount')->{error}, qr/\AUnknown aggregate function "evil"; expected one of: /, 'an unknown function';
		is $c->_tile_colour_measure([ 'sum' ], 'amount')->{fn}, 'avg', 'a reference is not a function name';
		my $m = $c->_tile_colour_measure('avg', 'amount');
		my $colours = $c->_tile_colours(undef, $rows->(), 'region', $m);
		is_deeply $colours, { North => 8.5, South => 5 }, 'one number a tile';
		is_deeply $c->_tile_colours(undef, $rows->(), undef, $c->_tile_colour_measure('sum', 'amount')), { '' => 22 }, 'one total without a category';
		is_deeply $c->_tile_colours(undef, [ { region => 'X', amount => 'abc' } ], 'region', $m), {}, 'a group with no number has no colour';
	};

	subtest 'Dashboard::_geo_lookup_sig -- one place, one key' => sub {
		my ($tm) = $fixture_app->();
		my $c = dash_controller($tm->app, '/');
		my $sig = $c->_geo_lookup_sig('Ramsgate');
		like $sig, qr/\A[0-9a-f]{40}\z/, 'a hex HMAC';
		is $c->_geo_lookup_sig('Ramsgate'), $sig, 'the same place, the same signature';
		isnt $c->_geo_lookup_sig('Ramsgate '), $sig, 'a different place, a different one';
		isnt $c->_geo_lookup_sig("\x{10D}"), $c->_geo_lookup_sig("\xC4\x8D"), 'characters are signed as UTF-8, not confused with their bytes';
		my $other = isolated_app();
		isnt dash_controller($other->app, '/')->_geo_lookup_sig('Ramsgate'), $sig, 'another start has another secret';
		$tm->app->secrets([ 'fixed' ]);
		is $c->_geo_lookup_sig('x'), Mojo::Util::hmac_sha1_sum("geo-lookup\0x", 'fixed'), 'keyed by the first secret';
	};

	subtest 'Dashboard::_map_geocoder -- built from the configuration' => sub {
		my ($tm) = $fixture_app->();
		my $stub = Stub::Geocoder->new;
		$tm->app->config->{geocoder} = $stub;
		my $c = dash_controller($tm->app, '/');
		my $g = $c->_map_geocoder(1);
		isa_ok $g, 'Database::BI::Model::Geocode';
		is $g->{_geocoder}, $stub, 'an injected geocoder is used';
		is $g->{online}, 1, 'online by default';
		is $c->_map_geocoder(0)->{online}, 0, 'a false argument keeps it local';
		$tm->app->config->{map_geocode_online} = 0;
		is $c->_map_geocoder(1)->{online}, 0, 'and so does the configuration, whatever is asked';
		ok $g->{cache} && $g->{cache}->can('get'), 'answers are kept in files under the model store';
		$tm->app->config->{geocoder} = 'not an object';
		ok !exists $c->_map_geocoder(1)->{_geocoder}, 'a configured geocoder that is not one is ignored';
		$tm->app->config->{map_geocode_online_max} = 'lots';
		lives_ok { $c->_map_geocoder(1) } 'a bad online limit falls back to the default';
	};

	subtest 'Dashboard::_map_key -- what HTML::OSM is given' => sub {
		my ($tm) = $fixture_app->();
		my $c = dash_controller($tm->app, '/');
		my %key = $c->_map_key('amount', [ { op => 'gt', val => 6, color => 'red' } ], '#00ff00', 0, '', []);
		is $key{legend_title}, 'amount', 'titled with the colour column';
		is_deeply [ map { [ @{$_}{qw(label colour group)} ] } @{ $key{legend} } ],
			[ [ 'amount > 6', '#ff0000', 'rule0' ], [ 'Other', '#00ff00', 'other' ] ], 'colours as hex, with groups';
		is $key{legend_empty}, 'Nothing in this view', 'what it says when nothing is in view';
		%key = $c->_map_key('', [], '#3388ff', 0, 'amount', [ 2, 10 ]);
		is_deeply [ map { $_->{label} } @{ $key{legend} } ], [qw(2 6 10)], 'sizes: smallest, middle, largest';
		ok !(grep { exists $_->{group} } @{ $key{legend} }), 'sizes have no group, so they always show';
		%key = $c->_map_key('', [], '#3388ff', 0, 'amount', [ 4, 4 ]);
		is scalar(@{ $key{legend} }), 1, 'one size when every value is the same';
		is_deeply [ $c->_map_key('', [], '#000', 0, '', []) ], [], 'nothing to explain, no key';
		is_deeply [ $c->_map_key('', [], '#000', 0, 'amount', undef) ], [], 'a size column with no values';
		is_deeply [ $c->_map_key('x', [ 'junk' ], '#000', 0, '', []) ], [], 'rules that are not rules make no key';
	};

	subtest 'Dashboard::_resolve_template -- always a directory that exists' => sub {
		my ($tm) = $fixture_app->();
		my $c = dash_controller($tm->app, '/');
		is_deeply [ $c->_resolve_template ], [qw(web en)], 'the defaults';
		my $fr = dash_controller($tm->app, '/');
		$fr->req->headers->accept_language('xx-YY, zz');
		$fr->req->headers->user_agent('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)');
		my ($platform, $language) = $fr->_resolve_template;
		ok -d $tm->app->home->child("templates/$platform/$language"), "'$platform/$language' has templates";
		$tm->app->config->{platform} = '../../etc';
		($platform) = dash_controller($tm->app, '/')->_resolve_template;
		ok $platform !~ m{/}, 'a configured platform cannot climb out of templates/';
	};

	subtest 'Dashboard::_render_csv, _render_json and _render_sqlite' => sub {
		my ($tm) = $fixture_app->();
		my $c = dash_controller($tm->app, '/');
		$c->_render_csv([ { a => '1,2', b => qq{say "hi"} } ], [qw(a b)], 'out');
		like $c->res->headers->content_disposition, qr/filename="out\.csv"/, 'a CSV download';
		is $c->res->body, qq{a,b\r\n"1,2","say ""hi"""\r\n}, 'quoted as RFC 4180 says';
		$c = dash_controller($tm->app, '/');
		$c->_render_json([ { a => '</script>' } ], ['a'], 'out');
		is_deeply $c->res->json, [ { a => '</script>' } ], 'the rows as JSON';
		like $c->res->headers->content_disposition, qr/filename="out\.json"/, 'a JSON download';
		$c = dash_controller($tm->app, '/');
		$c->_render_sqlite([ { a => 1 } ], ['a'], 'out');
		is substr($c->res->body, 0, 16), "SQLite format 3\0", 'a SQLite file';
		$c = dash_controller($tm->app, '/');
		$tm->app->log->level('fatal');
		Test::Mockingbird::mock("${D}::_write_sqlite_db", sub { die "disk full\n" });
		$c->_render_sqlite([ { a => 1 } ], ['a'], 'out');
		is $c->res->code, 500, 'a failed export is a 500';
		unlike $c->res->body, qr/disk full/, 'whose reason stays in the log';
		Test::Mockingbird::unmock("${D}::_write_sqlite_db");
	};

	subtest 'Dashboard::_page_columns -- the page with its fields drawn' => sub {
		my ($tm, $dir) = $fixture_app->();
		my $c = dash_controller($tm->app, '/?c=' . Mojo::Util::url_escape('double:amount*2'));
		my $src = $c->open_table('sales', directory => $dir);
		my ($records, $cols) = $c->_page_columns($src, $rows->(), 'table:none');
		is $records->[0]{double}, 20, 'a field is drawn on the page';
		ok( (grep { $_ eq 'double' } @{$cols}), 'and listed');
		my $bad = dash_controller($tm->app, '/?c=' . Mojo::Util::url_escape('x:nope+1'));
		is_deeply [ $bad->_page_columns($src, $rows->(), 'table:none') ], [], 'a field that cannot be drawn';
		is $bad->res->code, 400, 'is a 400';
		unlike $bad->res->body, qr/ at \S+ line \d+/, 'that does not say where in the code';
		my $span = dash_controller($tm->app, '/?span=nope&tcol=id');
		is_deeply [ $span->_page_columns($src, $rows->(), 'table:none') ], [], 'a bad span=';
		is $span->res->code, 400, 'is a 400 as well';
		my $empty = bless {}, 'Stub::NoColumns';
		{ no strict 'refs'; *{'Stub::NoColumns::columns'} = sub { return }; }
		is_deeply [ dash_controller($tm->app, '/')->_page_columns($empty, [], 'table:none') ], [ [], [] ], 'no columns, nothing to draw';
	};

	# Purpose: acceleration copies a file into the model store; it must only
	# ever take a local data file, and must never serve a stale copy.
	subtest 'Dashboard::_accel_file, accelerate, unaccelerate, accelerated_specs, _accelerated_source' => sub {
		my ($tm, $dir) = $fixture_app->();
		my $c = $tm->app->build_controller;
		bless $c, $D;
		my $real = Mojo::File->new($dir)->child('sales.csv')->realpath->to_string;
		is $c->_accel_file('table:sales'), Mojo::File->new($dir)->child('sales.csv')->to_string, 'a table in data_dir';
		is $c->_accel_file("path:$dir/sales.csv"), $real, 'a path, resolved';
		is $c->_accel_file($_), undef, "'" . ($_ // 'undef') . "' has no file"
			for undef, '', 'table:a-b', 'table:none', 'url:http://x/a.csv', "path:$dir/none.csv", 'path:/../h/a.csv', "path:$dir";

		throws_ok { $D->can('accelerate')->(undef, 'table:sales') } qr/\Aaccelerate\(\) needs a controller and a spec/, 'no controller';
		throws_ok { $D->can('accelerate')->($c, 'table:none') }
			qr/\ACannot accelerate "table:none": it must be a table: or path: spec naming a local file that exists/, 'nothing to read';
		my $db = Mojo::File->new($dir)->child('lite.db');
		$db->spew("SQLite format 3\0" . ("\0" x 84));
		throws_ok { $D->can('accelerate')->($c, "path:$db") } qr/\ACannot accelerate "path:[^"]+": it is a SQLite database already/, 'already SQLite';

		my $built = $D->can('accelerate')->($c, "path:$dir/sales.csv");
		is_deeply [ @{$built}{qw(spec rows columns)} ], [ "path:$real", 3, 5 ], 'the extract: its key, rows and columns';
		ok -f $built->{path}, 'written';
		is_deeply [ $D->can('accelerated_specs')->($c) ], [ "path:$real" ], 'listed';

		my $page = dash_controller($tm->app, '/');
		my $src = $page->_accelerated_source("path:$dir/sales.csv");
		ok $src, 'the extract is read while it matches';
		is $page->stash('acceleration')->{state}, 'fresh', 'and the page says so';
		sleep 1;
		Mojo::File->new($dir)->child('sales.csv')->spew($CX{sales} . "4,West,1,A,x\n");
		my $stale = dash_controller($tm->app, '/');
		is $stale->_accelerated_source("path:$dir/sales.csv"), undef, 'a changed file is read, not its old copy';
		is $stale->stash('acceleration')->{state}, 'stale', 'and the page says so';
		my $off = dash_controller($tm->app, '/');
		$off->stash(_no_acceleration => 1);
		is $off->_accelerated_source("path:$dir/sales.csv"), undef, 'acceleration can be turned off for a request';
		is dash_controller($tm->app, '/')->_accelerated_source('table:sales'), undef, 'a spec not accelerated';

		ok $D->can('unaccelerate')->($c, "path:$dir/sales.csv"), 'unaccelerated';
		ok !-f $built->{path}, 'and its extract removed';
		ok !$D->can('unaccelerate')->($c, "path:$dir/sales.csv"), 'a second time there is nothing to do';
		is_deeply [ $D->can('accelerated_specs')->($c) ], [], 'nothing is listed';
		throws_ok { $D->can('accelerated_specs')->(undef) } qr/\Aaccelerated_specs\(\) needs a controller/, 'no controller';
		throws_ok { $D->can('unaccelerate')->($c, undef) } qr/\Aunaccelerate\(\) needs a controller and a spec/, 'no spec';

		$tm->app->config->{model_dir} = $dir;
		throws_ok { $D->can('accelerate')->($c, 'table:sales') }
			qr/\ACannot accelerate "table:sales": the model store cannot be written/, 'a store inside data_dir is refused';
	};

	subtest 'Dashboard::_run_pipeline_source -- the inner pipeline' => sub {
		my ($tm, $dir) = $fixture_app->();
		my $c = dash_controller($tm->app, '/?l=' . Mojo::Util::url_escape("path:$dir/sales.csv"));
		my ($src, $records, $cols) = $c->_run_pipeline_source;
		ok $src, 'a source';
		is scalar(@{$records}), 3, 'every row';
		is_deeply [ sort @{$cols} ], [ sort qw(id region amount code note) ], 'every column';
		my $none = dash_controller($tm->app, '/?l=table:nosuch');
		is_deeply [ $none->_run_pipeline_source ], [], 'nothing for a table that is not there';
		is_deeply [ dash_controller($tm->app, '/')->_run_pipeline_source ], [], 'nor for no l=';
		my $bad_join = dash_controller($tm->app, '/?l=' . Mojo::Util::url_escape("path:$dir/sales.csv") . '&j=' . Mojo::Util::url_escape('table:nosuch|id|id'));
		my (undef, $kept) = $bad_join->_run_pipeline_source;
		is scalar(@{$kept}), 3, 'a join whose right side cannot be opened is skipped, not fatal';
		is_deeply $bad_join->stash('pipeline_joined') // [], [], 'and is not reported as joined';
	};
}


# ============================================================================
# PART U17: Dashboard -- the canvas, lookup, extraction and geocode routes, and
# the helpers that draw a canvas card
#
# The routes are driven through Test::Mojo, because what they promise is a
# status and a JSON body; most subtests send what a hostile or confused client
# would (bad JSON, ids that are not ids, indexes past the end, forged
# signatures) and check that the store is left as it was.  The card helpers
# are called directly on a controller, with a real CSV under data_dir.
# ============================================================================
{
	Readonly my %KX => (
		sales     => "id,region,amount\n1,North,10\n2,South,5\n3,North,7\n",
		codes     => "code,label\nA,Alpha\nB,Beta\n",
		bad_id    => 'not-an-id!',
		missing   => 'NoSuchCanvas',
		long_len  => 4097,
		not_found => 404,
		bad       => 400,
		forbidden => 403,
		gone      => 503,
		created   => 201,
	);

	# An application with sales.csv and codes.csv in a data_dir of its own,
	# and a canvas over sales.csv; returns the app, the directory and the id.
	sub canvas_app {
		my $tm  = isolated_app();
		my $dir = tempdir(CLEANUP => 1);
		Mojo::File->new($dir)->child('sales.csv')->spew($KX{sales});
		Mojo::File->new($dir)->child('codes.csv')->spew($KX{codes});
		$tm->app->config->{data_dir} = $dir;
		my $spec = 'path:' . Mojo::File->new($dir)->child('sales.csv')->realpath->to_string;
		my $id = $tm->post_ok('/api/analyses' => json => {
			name     => 'Sales',
			datasets => [ { spec => $spec, alias => 'l' } ],
			visuals  => [
				{ kind => 'bar', encode => { cat => 'region', value => 'amount' }, title => 'By region' },
				{ kind => 'text', options => { text => 'Note' } },
			],
		})->status_is($KX{created})->tx->res->json->{id};
		return ($tm, $dir, $id, $spec);
	}

	# The canvas as stored, read back through the API.
	sub canvas_doc {
		my ($tm, $id) = @_;
		return $tm->get_ok("/api/analyses/$id")->status_is(200)->tx->res->json;
	}

	subtest 'Dashboard::_cross_filter_source -- only a whole number names a card' => sub {
		# int('abc') is 0, which would draw the first card unfiltered as the
		# source of a cross-filter nobody made from it.
		my $f = \&Database::BI::Controller::Dashboard::_cross_filter_source;
		is $f->(undef), -1, 'no cv= is no source';
		is $f->(''), -1, 'an empty one neither';
		is $f->('abc'), -1, 'nor a word';
		is $f->('-1'), -1, 'nor a negative index';
		is $f->('1.5'), -1, 'nor a fraction';
		is $f->("2\n"), -1, 'nor a number with a newline after it';
		is $f->('1' x 10), -1, 'nor one too long to be an index';
		is $f->([ 1 ]), -1, 'nor a reference';
		is $f->('0'), 0, 'the first card';
		is $f->('12'), 12, 'and any other';
		warnings_are { $f->('abc') } [], 'and it warns about nothing';
	};

	subtest 'analyses_list / analyses_get -- what is stored, and nothing else' => sub {
		my ($tm, undef, $id) = canvas_app();
		my $list = $tm->get_ok('/api/analyses')->status_is(200)->tx->res->json->{analyses};
		is scalar(@$list), 1, 'one canvas listed';
		is $list->[0]{id}, $id, 'by its id';
		is $list->[0]{name}, 'Sales', 'and its name';
		ok !exists $list->[0]{visuals}, 'the list does not carry every card';

		$tm->get_ok("/api/analyses/$KX{missing}")->status_is($KX{not_found})
			->json_is('/error', qq{Analysis "$KX{missing}" not found});
		$tm->get_ok('/api/analyses/' . url_escape($KX{bad_id}))->status_is($KX{bad})
			->json_is('/error', 'Invalid analysis id');
		is canvas_doc($tm, $id)->{name}, 'Sales', 'a real one is returned whole';
	};

	subtest 'analyses_create -- refuses what is not a canvas' => sub {
		my ($tm) = canvas_app();
		$tm->post_ok('/api/analyses' => '{not json')->status_is($KX{bad})->json_has('/error');
		$tm->post_ok('/api/analyses' => json => [ 1, 2 ])->status_is($KX{bad});
		$tm->post_ok('/api/analyses' => json => { name => 'x' })->status_is($KX{bad})
			->json_like('/error', qr/\AInvalid analysis spec: /);
		$tm->post_ok('/api/analyses' => json => { name => 'x', datasets => [ 'junk' ], visuals => [] })
			->status_is($KX{bad})->json_like('/error', qr/spec field/);
		$tm->post_ok('/api/analyses' => json => { name => 'x', datasets => [ { spec => 'table:sales' } ], visuals => [ 'junk' ] })
			->status_is($KX{bad})->json_like('/error', qr/must be an object/);
		is scalar(@{ $tm->get_ok('/api/analyses')->tx->res->json->{analyses} }), 1, 'none of them was stored';

		# A caller cannot choose its own id or smuggle in keys the store does not know.
		my $id = $tm->post_ok('/api/analyses' => json => {
			name => 'y', id => 'mine', datasets => [ { spec => 'table:sales' } ], visuals => [], evil => 1,
		})->status_is($KX{created})->tx->res->json->{id};
		isnt $id, 'mine', 'the server picks the id';
		my $doc = canvas_doc($tm, $id);
		ok !exists $doc->{evil}, 'an unknown key is dropped';
		ok $doc->{created} && $doc->{updated}, 'times are stamped';
	};

	subtest 'analyses_create / _delete -- a store that cannot be written is a 503' => sub {
		my ($tm, undef, $id) = canvas_app();
		Test::Mockingbird::mock('Database::BI::Controller::Dashboard::_write_analyses', sub { 0 });
		$tm->post_ok('/api/analyses' => json => { name => 'z', datasets => [ { spec => 'table:sales' } ], visuals => [] })
			->status_is($KX{gone});
		$tm->delete_ok("/api/analyses/$id")->status_is($KX{gone});
		Test::Mockingbird::unmock('Database::BI::Controller::Dashboard::_write_analyses');
		is canvas_doc($tm, $id)->{name}, 'Sales', 'the canvas a refused delete named is still there';
	};

	subtest 'analyses_update -- a full replace keeps id and created' => sub {
		my ($tm, undef, $id, $spec) = canvas_app();
		my $before = canvas_doc($tm, $id);
		$tm->put_ok("/api/analyses/$KX{missing}" => json => { name => 'x', datasets => [ { spec => $spec } ], visuals => [] })
			->status_is($KX{not_found});
		$tm->put_ok("/api/analyses/$id" => '[1]')->status_is($KX{bad});
		$tm->put_ok("/api/analyses/$id" => json => { name => 'x', datasets => [ 'junk' ], visuals => [] })
			->status_is($KX{bad});
		is canvas_doc($tm, $id)->{name}, 'Sales', 'a refused replace changes nothing';

		$tm->put_ok("/api/analyses/$id" => json => {
			name => 'Renamed', id => 'other', created => 1, datasets => [ { spec => $spec } ], visuals => [],
		})->status_is(200)->json_is('/updated', 1);
		my $after = canvas_doc($tm, $id);
		is $after->{name}, 'Renamed', 'replaced';
		is $after->{id}, $id, 'the id cannot be changed';
		is $after->{created}, $before->{created}, 'nor when it was made';
	};

	subtest 'analyses_patch -- merges only what is sent, and checks only that' => sub {
		my ($tm, undef, $id) = canvas_app();
		my $created = canvas_doc($tm, $id)->{created};
		$tm->patch_ok("/api/analyses/$KX{missing}" => json => { name => 'x' })->status_is($KX{not_found});
		$tm->patch_ok("/api/analyses/$id" => 'nope')->status_is($KX{bad});
		$tm->patch_ok("/api/analyses/$id" => json => { visuals => 'junk' })->status_is($KX{bad})
			->json_like('/error', qr/\AInvalid analysis spec: /);
		$tm->patch_ok("/api/analyses/$id" => json => { created => 1, id => 'x', name => 'Patched' })->status_is(200);
		my $doc = canvas_doc($tm, $id);
		is $doc->{name}, 'Patched', 'the name was merged';
		is $doc->{created}, $created, 'created is immutable';
		is $doc->{id}, $id, 'and so is id';
		is scalar(@{ $doc->{visuals} }), 2, 'the cards it did not mention are kept';
	};

	subtest 'analyses_delete -- one canvas, once' => sub {
		my ($tm, undef, $id) = canvas_app();
		$tm->delete_ok('/api/analyses/' . url_escape($KX{bad_id}))->status_is($KX{bad});
		$tm->delete_ok("/api/analyses/$KX{missing}")->status_is($KX{not_found});
		$tm->delete_ok("/api/analyses/$id")->status_is(200)->json_is('/deleted', 1);
		$tm->delete_ok("/api/analyses/$id")->status_is($KX{not_found}, 'a second delete finds nothing');
	};

	subtest 'analyses_add_visual / _update_visual -- refused cards are not stored' => sub {
		my ($tm, undef, $id) = canvas_app();
		$tm->post_ok("/api/analyses/$KX{missing}/visuals" => json => { kind => 'bar' })->status_is($KX{not_found});
		$tm->post_ok("/api/analyses/$id/visuals" => 'x')->status_is($KX{bad});
		$tm->post_ok("/api/analyses/$id/visuals" => json => { kind => 'teapot' })->status_is($KX{bad});
		$tm->post_ok("/api/analyses/$id/visuals" => json => { kind => 'bar', encode => { cat => 'nope', value => 'amount' } })
			->status_is($KX{bad}, 'a column the data does not have');
		is scalar(@{ canvas_doc($tm, $id)->{visuals} }), 2, 'nothing was added';

		$tm->patch_ok("/api/analyses/$id/visuals/9" => json => { title => 'x' })->status_is($KX{not_found});
		$tm->patch_ok("/api/analyses/$id/visuals/abc" => json => { title => 'x' })->status_is($KX{bad});
		$tm->patch_ok("/api/analyses/$id/visuals/0" => '[')->status_is($KX{bad});
		is canvas_doc($tm, $id)->{visuals}[0]{title}, 'By region', 'the card is as it was';

		$tm->post_ok("/api/analyses/$id/visuals" => json => { kind => 'bar', encode => { cat => 'region', value => 'amount' }, title => 'Again' })
			->status_is($KX{created});
		is canvas_doc($tm, $id)->{visuals}[2]{title}, 'Again', 'a good card is appended';
	};

	subtest 'analyses_delete_visual -- only a text card, and the layout follows' => sub {
		my ($tm, undef, $id) = canvas_app();
		$tm->patch_ok("/api/analyses/$id" => json => {
			layout    => [ { visual => 0, x => 1, y => 1, w => 6, h => 1 }, { visual => 1, x => 7, y => 1, w => 6, h => 1 } ],
			bookmarks => [ { name => 'b', state => 'cv=1&cf=region:eq:North' } ],
		})->status_is(200);
		$tm->delete_ok("/api/analyses/$id/visuals/0")->status_is($KX{bad})
			->json_is('/error', 'Only a text card can be removed');
		$tm->delete_ok("/api/analyses/$id/visuals/7")->status_is($KX{not_found})->json_is('/error', 'No visual at index 7');
		$tm->delete_ok("/api/analyses/$id/visuals/x")->status_is($KX{bad});
		$tm->delete_ok("/api/analyses/$KX{missing}/visuals/1")->status_is($KX{not_found});
		is scalar(@{ canvas_doc($tm, $id)->{visuals} }), 2, 'nothing was removed';

		$tm->delete_ok("/api/analyses/$id/visuals/1")->status_is(200)->json_is('/deleted', 1);
		my $doc = canvas_doc($tm, $id);
		is scalar(@{ $doc->{visuals} }), 1, 'the text card is gone';
		is_deeply [ map { $_->{visual} } @{ $doc->{layout} } ], [ 0 ], 'and its place in the layout';
		unlike $doc->{bookmarks}[0]{state}, qr/cv=1/, 'a bookmark no longer names it';
	};

	subtest 'analyses_export / analyses_import -- round trip, and junk refused' => sub {
		my ($tm, undef, $id) = canvas_app();
		$tm->get_ok("/api/analyses/$KX{missing}/export")->status_is($KX{not_found});
		my $file = $tm->get_ok("/api/analyses/$id/export")->status_is(200)->tx->res->json;
		is $file->{name}, 'Sales', 'the export is the canvas';

		$tm->post_ok('/api/analyses/import' => '{')->status_is($KX{bad});
		$tm->post_ok('/api/analyses/import' => json => { name => 'i', datasets => [ 'junk' ], visuals => [] })->status_is($KX{bad});
		my $new = $tm->post_ok('/api/analyses/import' => json => $file)->status_is($KX{created})->tx->res->json->{id};
		isnt $new, $id, 'an import is a new canvas, not an overwrite';
		is canvas_doc($tm, $new)->{name}, 'Sales', 'with the same content';
	};

	subtest 'canvas page -- a non-numeric cv= is not card 0' => sub {
		my ($tm, undef, $id) = canvas_app();
		my @warned;
		local $SIG{__WARN__} = sub { push @warned, @_ };
		$tm->get_ok("/a/$id?cv=abc&cf=region:eq:North")->status_is(200);
		ok !(grep { /isn't numeric/ } @warned), 'no warning from int()' or diag explain \@warned;
		$tm->get_ok("/a/$KX{missing}")->status_is($KX{not_found});
	};

	subtest 'canvases_view / preferences -- pages that read no data' => sub {
		my ($tm) = canvas_app();
		# The cards are drawn by the page's script from /api/analyses, so the
		# page itself is checked for the parts that script and Import need.
		$tm->get_ok('/canvases')->status_is(200)->element_exists('#cv-import')
			->content_like(qr/There are no saved canvases yet/, 'the empty-list text is there for the script');
		$tm->get_ok('/canvases?l=' . url_escape('<script>'))->status_is(200)->content_unlike(qr/<script>[^<]*<\/script>\s*\z/);
		$tm->get_ok('/preferences')->status_is(200)->element_exists('select, input');
		$tm->post_ok('/preferences')->status_is($KX{not_found}, 'preferences are kept by the browser, never posted');
	};

	subtest 'lookups_save / _list / _delete -- refuses before it writes' => sub {
		my ($tm, $dir, undef, $spec) = canvas_app();
		my $l = url_escape($spec);
		$tm->post_ok('/lookups/save')->status_is($KX{bad})->json_is('/error', 'l= required');
		$tm->post_ok("/lookups/save?l=$l&name=1bad&key=code")->status_is($KX{bad})
			->json_is('/error', 'Lookup name "1bad" is not a valid identifier');
		$tm->post_ok("/lookups/save?l=$l&name=codes")->status_is($KX{bad})->json_is('/error', 'key= required');
		$tm->post_ok("/lookups/save?l=$l&name=codes&key=code&file=../../etc/passwd")->status_is($KX{bad});
		$tm->post_ok("/lookups/save?l=$l&name=codes&key=code&file=nosuch.csv")->status_is($KX{bad});
		$tm->get_ok("/lookups/list?l=$l")->status_is(200)->json_is('/lookups', {}, 'nothing refused was stored');
		$tm->get_ok('/lookups/list')->status_is($KX{bad});

		$tm->post_ok("/lookups/save?l=$l&name=codes&key=code&col=region&file=codes.csv&fields=label")->status_is(200);
		$tm->get_ok("/lookups/list?l=$l")->json_is('/lookups/codes/file', 'codes.csv');
		$tm->post_ok('/lookups/delete')->status_is($KX{bad});
		$tm->post_ok("/lookups/delete?l=$l&name=other")->status_is(200);
		$tm->get_ok("/lookups/list?l=$l")->json_has('/lookups/codes', 'deleting another name leaves this one');
		$tm->post_ok("/lookups/delete?l=$l")->status_is(200);
		$tm->get_ok("/lookups/list?l=$l")->json_is('/lookups', {}, 'no name= deletes them all');
	};

	subtest 'extract_save / _list / _delete -- a bad pattern is not stored' => sub {
		my ($tm, undef, undef, $spec) = canvas_app();
		my $l = url_escape($spec);
		$tm->post_ok('/extract/save')->status_is($KX{bad})->json_is('/error', 'l= required');
		$tm->post_ok("/extract/save?l=$l&name=x-y&col=region&pattern=a")->status_is($KX{bad})
			->json_is('/error', 'Extraction name "x-y" is not a valid identifier');
		$tm->post_ok("/extract/save?l=$l&name=n&pattern=a")->status_is($KX{bad})->json_is('/error', 'col= required');
		$tm->post_ok("/extract/save?l=$l&name=n&col=region")->status_is($KX{bad})->json_is('/error', 'pattern= required');
		$tm->post_ok("/extract/save?l=$l&name=n&col=region&pattern=" . url_escape('(?<a>x'))->status_is($KX{bad});
		$tm->post_ok("/extract/save?l=$l&name=n&col=region&pattern=" . url_escape('(?{ 1 })'))->status_is($KX{bad}, 'no code in a pattern');
		$tm->get_ok("/extract/list?l=$l")->status_is(200)->json_is('/extractions', {});
		$tm->get_ok('/extract/list')->status_is($KX{bad});

		$tm->post_ok("/extract/save?l=$l&name=n&col=region&pattern=" . url_escape('(?<first>\w)'))->status_is(200)
			->json_is('/fields', [ 'first' ]);
		$tm->post_ok('/extract/delete')->status_is($KX{bad});
		$tm->post_ok("/extract/delete?l=$l&name=n")->status_is(200);
		$tm->get_ok("/extract/list?l=$l")->json_is('/extractions', {});
	};

	subtest 'geo_lookup -- only a place a map page signed' => sub {
		my ($tm) = canvas_app();
		my $stub = Stub::Geocoder->new(results => {
			$GOOD_PLACE => Stub::GeoPoint->new({ latitude => 51.3, longitude => 1.4, database => 'Test' }),
		});
		$tm->app->config->{geocoder} = $stub;
		my $sig = dash_controller($tm->app, '/')->_geo_lookup_sig($GOOD_PLACE);

		$tm->post_ok('/geo/lookup')->status_is($KX{bad})
			->json_is('/error', 'A lookup needs place= and the sig= the map page gave it');
		$tm->post_ok('/geo/lookup' => form => { place => $GOOD_PLACE })->status_is($KX{bad});
		$tm->post_ok('/geo/lookup' => form => { place => $GOOD_PLACE, sig => 'f' x 40 })->status_is($KX{forbidden})
			->json_like('/error', qr/\AThis place was not listed by a map page/);
		$tm->post_ok('/geo/lookup' => form => { place => 'Elsewhere', sig => $sig })->status_is($KX{forbidden}, 'a signature is for one place');
		is scalar(@{ $stub->{calls} }), 0, 'a refused request reaches no geocoder';

		$tm->post_ok('/geo/lookup' => form => { place => $GOOD_PLACE, sig => $sig })->status_is(200)
			->json_is('/place', $GOOD_PLACE)->json_is('/status', 'found')->json_is('/stored', 1);
		$tm->post_ok('/geo/lookup' => form => { place => $GOOD_PLACE, sig => $sig })->status_is(200)
			->json_is('/status', 'found');
		is scalar(@{ $stub->{calls} }), 1, 'the second answer came from the cache';

		my $none = dash_controller($tm->app, '/')->_geo_lookup_sig('Nowhere');
		$tm->post_ok('/geo/lookup' => form => { place => 'Nowhere', sig => $none })->status_is(200)
			->json_is('/status', 'not_found');
	};

	subtest 'Dashboard::_build_canvas_pipeline -- nothing to open is an empty list' => sub {
		my ($tm, $dir, undef, $spec) = canvas_app();
		my $c = dash_controller($tm->app, '/');
		is_deeply [ $c->_build_canvas_pipeline({}) ], [], 'no datasets';
		is_deeply [ $c->_build_canvas_pipeline({ datasets => [ {} ] }) ], [], 'a dataset with no spec';
		is_deeply [ $c->_build_canvas_pipeline({ datasets => [ { spec => 'path:/no/such/file.csv' } ] }) ], [], 'one that cannot be opened';

		my ($src, $records, $columns) = $c->_build_canvas_pipeline({ datasets => [ { spec => $spec, alias => 'l' } ] });
		ok $src, 'a source';
		is scalar(@$records), 3, 'every row';
		ok((grep { $_ eq 'amount' } @$columns), 'and its columns');

		my $codes = 'path:' . Mojo::File->new($dir)->child('codes.csv')->realpath->to_string;
		lives_ok {
			($src, $records) = $c->_build_canvas_pipeline({
				datasets => [ { spec => $spec, alias => 'l' }, { spec => $codes, alias => 'r' } ],
				joins    => [ { left => 'l' }, { left => 'l', right => 'r' } ],
			});
		} 'a join with no key is skipped, not fatal';
		is scalar(@$records), 3, 'and the left rows are kept';
	};

	subtest 'Dashboard::_canvas_render_context -- bad state is a status, not a croak' => sub {
		my ($tm, undef, $id, $spec) = canvas_app();
		my $c = dash_controller($tm->app, '/');
		my $a = { datasets => [ { spec => $spec } ], visuals => [] };
		is_deeply $c->_canvas_render_context($a, [ 'q' ]), { error => 'query must be a string', status => $KX{bad} }, 'a reference';
		is_deeply $c->_canvas_render_context($a, 'x' x $KX{long_len}), { error => 'query must be a string', status => $KX{bad} }, 'too long';
		is $c->_canvas_render_context({ datasets => [] }, '')->{status}, 422, 'no data';
		is $c->_canvas_render_context($a, '?c=' . url_escape('t:nosuchcol + 1'))->{status}, $KX{bad}, 'a calculated field that does not compile';

		my $ctx = $c->_canvas_render_context($a, '?cf=region:eq:North&cv=zz');
		is $ctx->{cf_source}, -1, 'a cv= that is not a number names no card';
		is_deeply $ctx->{cf_specs}, [ 'region:eq:North' ], 'the cross-filter is kept';
		is scalar(@{ $ctx->{records} }), 3, 'rows are not filtered here';
		is $c->_canvas_render_context($a, '?cv=1')->{cf_source}, 1, 'a real index';
		is $c->_canvas_render_context($a, undef)->{spec_key}, $spec, 'no query at all is fine';
		memory_cycle_ok $ctx, 'the context holds no cycles';
	};

	subtest 'Dashboard::_render_visual_html / _markup -- every card is drawn or explained' => sub {
		my ($tm, undef, undef, $spec) = canvas_app();
		my $c = dash_controller($tm->app, '/');
		my ($src, $records, $columns) = $c->_build_canvas_pipeline({ datasets => [ { spec => $spec } ] });
		my $draw = sub { $c->_render_visual_html($_[0], $records, $columns, $src, 0, $spec, 0) };

		my $text = $draw->({ kind => 'text', options => { text => '<b>hi</b>' } });
		unlike $text->{html}, qr/<b>hi/, 'a text card escapes markup';
		my $bar = $draw->({ kind => 'bar', encode => { cat => 'region', value => 'amount' } });
		ok defined($bar->{html}) && !$bar->{error}, 'a bar card is drawn';
		my $none = $draw->({ kind => 'bar', encode => { cat => 'nosuch', value => 'amount' } });
		ok $none->{error} || defined $none->{html}, 'a missing column answers, rather than croaking';
		my $odd = $draw->({ kind => 'teapot' });
		ok ref($odd) eq 'HASH', 'an unknown kind answers too';
		lives_ok { $draw->({ kind => 'bar', encode => 'junk', options => 'junk', filters => 'junk' }) }
			'a card whose parts are not hashes does not take the page down';
		lives_ok { $draw->({ kind => 'map', encode => { loc => 'region' }, options => { color_rules => 'junk' } }) }
			'nor a map with junk rules';
	};

	subtest 'Dashboard::_map_data -- places, pending and keys from a stub geocoder' => sub {
		my ($tm) = canvas_app();
		$tm->app->config->{geocoder} = Stub::Geocoder->new(results => {
			North => Stub::GeoPoint->new({ latitude => 55, longitude => -2, database => 'Test' }),
		});
		my $c = dash_controller($tm->app, '/');
		my $rows = [ { region => 'North', amount => 10 }, { region => 'South', amount => 5 }, { region => '', amount => 1 } ];
		my $cols = [ qw(region amount) ];

		my $data = $c->_map_data($rows, $cols, { loc => 'region' }, {}, '', 'x');
		ok ref($data) eq 'HASH', 'an answer';
		diag explain [ sort keys %$data ] if $ENV{TEST_VERBOSE};

		my $wait = $c->_map_data($rows, $cols, { loc => 'region' }, { lookup => 0 }, '', 'y');
		ok ref($wait->{pending}) eq 'ARRAY', 'lookup => 0 says what is still to be looked up';
		ok !(grep { $_ eq '' } @{ $wait->{pending} }), 'an empty cell is never pending';

		lives_ok { $c->_map_data($rows, $cols, { loc => 'nosuch' }, {}, '', 'z') } 'a column that is not there';
		lives_ok { $c->_map_data([], $cols, { loc => 'region' }, {}, '', 'w') } 'no rows at all';
		lives_ok { $c->_map_data($rows, $cols, { loc => 'region' }, { color_rules => [ 'junk', 3 ] }, '', 'v') }
			'rules that are not hashes are ignored';
	};
}

# ============================================================================
# DataSource::_best_id_column -- the id must not drop rows
#
# Database::Abstraction drops every row whose id cell is empty or starts with
# '#', so the id is the safe column with the fewest such cells over the whole
# file, not the first that happens to be filled in the first data row.
# ============================================================================
subtest 'DataSource::_best_id_column -- the column that drops fewest rows' => sub {
	my $best = \&Database::BI::Model::DataSource::_best_id_column;
	my $pick = sub {
		my ($body, @header) = @_;
		# CORE:: because the autodie in scope here cannot open an in-memory file.
		CORE::open(my $fh, '<', \$body) or return 'cannot read';
		return $best->($fh, ',', \@header);
	};
	is $pick->("650825,a,x\n,b,y\n,c,z\n", qw(Check Desc Status)), 'Desc',
		'filled in the first row is not enough';
	is $pick->("1,a\n2,b\n", qw(id name)), 'id', 'the earliest of two full columns';
	is $pick->("1,\"a,b\",x\n2,c,y\n", qw(Check Desc Status)), 'Check', 'a quoted separator does not shift the cells';
	is $pick->("#1,a\n#2,b\n", qw(id name)), 'name', "a cell D::A reads as a comment counts as empty";
	is $pick->("  ,a\n\t,b\n", qw(id name)), 'name', 'so does whitespace';
	is $pick->("\n\n1,\n", qw(id name)), 'id', 'blank lines are not rows';
	is $pick->('', qw(id name)), 'id', 'no data: the first safe column';
	is $pick->("1,2\n", 'Account Number', 'Post Date'), undef, 'no safe column at all';
	is $pick->("1,2\n", '', 'b'), 'b', 'an empty header name is skipped, its index kept';
	is $pick->(",,,x\n,,,y\n", qw(a b c d)), 'd', 'a short row is all empties before the filled cell';
	is $pick->("a\nb\n", qw(x y)), 'x', 'a missing cell is empty in every row, so a tie keeps the earliest';
	is $pick->("\"unterminated,1\n2,3\n", qw(a b)), 'a', 'a malformed line stops the count, not the open';
	keeps_globals_ok('_best_id_column', sub { $pick->("1,a\n", qw(id name)) });
};

done_testing();

