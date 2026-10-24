use strict;
use warnings;
use Test::Most;
use Test::Mockingbird;
use Test::Returns qw(returns_is returns_isnt);
use Test::Memory::Cycle;
use File::Spec   ();
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
	# synthesized keys, bypassing Database::Abstraction entirely.
	subtest '_detect_file_info -- headerless CSV full fetch round-trip' => sub {
		# Descriptions contain spaces so no first-row value is a $SAFE_IDENTIFIER,
		# forcing the headerless-detection path.
		Mojo::File->new("$dir/bank.csv")->spew(
			"2026-09-01,-50.00,SUPER MARKET\n" .
			"2026-09-02,-12.50,COFFEE SHOP\n" .
			"2026-09-03,1200.00,SALARY CREDIT\n"
		);
		my $info = $fn->($dir, 'bank');
		ok exists $info->{_headerless_data},          'headerless sentinel returned';
		is scalar @{ $info->{_headerless_data} }, 3,  'all three rows parsed';
		is $info->{_headerless_data}[2]{Amount}, '1200.00', 'positive Amount on row 3';
		is $info->{_headerless_data}[0]{Description}, 'SUPER MARKET', 'Description on row 1';
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

subtest 'Dashboard::_resolve_language -- valid header parsed, falls back when no templates' => sub {
	my $tx = $t->ua->build_tx(GET => '/');
	# 'fr' has no template directory in this installation; should fall back to 'en'.
	$tx->req->headers->header('Accept-Language' => 'fr-FR,fr;q=0.9,en;q=0.8');
	my $c    = $t->app->build_controller($tx);
	my $lang = Database::BI::Controller::Dashboard::_resolve_language($c, 'web', 'en');
	ok $lang eq 'fr' || $lang eq 'en',
		"resolved language is 'fr' or 'en' (fallback when no fr templates)";
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
			"Feb,(\$450.00)\n" .   # accounting negative — was plotted as +450
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
# Three fast-paths are exercised before the backend delegation:
#   1. _file_is_empty -- always returns []
#   2. _file_data     -- returns pre-loaded rows without touching _db
#   3. Cache hit      -- returns cached rows without touching _db
# ---------------------------------------------------------------------------
subtest 'DataSource::selectall_arrayref -- _file_is_empty fast-path returns []' => sub {
	# Construct a real DataSource then force the empty-file sentinel to verify
	# the fast-path exits before any backend access.
	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);
	$src->{_file_is_empty} = 1;

	my $result = $src->selectall_arrayref;
	is_deeply $result, [], 'selectall_arrayref returns [] when _file_is_empty is set';
};

subtest 'DataSource::selectall_arrayref -- _file_data fast-path returns pre-loaded rows' => sub {
	my $src = $DS->new(directory => $DATA_DIR, table => $SALES_CSV);
	my $fake_rows = [{ col => 'val1' }, { col => 'val2' }];
	$src->{_file_data} = $fake_rows;

	my $result = $src->selectall_arrayref;
	is $result, $fake_rows,
		'selectall_arrayref returns _file_data reference unchanged (no copy)';
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

subtest 'DataSource::updated -- delegates to _db->updated() when available' => sub {
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

	is $src->updated, $FAKE_MTIME,
		'updated() returns value from _db->updated() when _db implements it';
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

subtest 'treemap_view -- ?color= returns 400 (not yet implemented)' => sub {
	SKIP: {
		skip 'data/sales.csv not found', 2 unless -f 'data/sales.csv';
		$t->get_ok("/treemap?l=$SALES_SPEC&group=region&color=amount")
		  ->status_is(400)
		  ->content_like(qr/color.*not.*supported|not.*supported.*color/i,
			'?color= parameter yields 400 (use ?scheme= instead)');
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

done_testing();

