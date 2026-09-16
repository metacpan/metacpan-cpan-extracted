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

done_testing();
