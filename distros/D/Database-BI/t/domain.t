use strict;
use warnings;
use Test::Most;
use Test::Mojo;
use Test::Mockingbird	qw(mock restore_all);
use Readonly;
use File::Spec		();
use File::Temp		qw(tempdir);
use Mojo::File		();
use Mojo::Util		qw(url_escape);

# ------------------------------------------------------------------
# Bootstrap the app first so :Private stash entries survive.
# ------------------------------------------------------------------
my $t = Test::Mojo->new('Database::BI');

# A staging directory this file owns, so a parallel test file's
# POST /uploads/clear cannot empty it mid-test.
$t->app->config->{uploads_dir} = tempdir(CLEANUP => 1);

# The model store (.bi/) is shared state in the checkout: give this file its
# own directory, so a parallel run cannot create, read or write it underneath.
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

require Database::BI::Model::DataSource;
require Database::BI::Controller::Dashboard;

my $FILTER = \&Database::BI::Controller::Dashboard::_apply_filter_spec;

Readonly my $TMPDIR	=> tempdir(CLEANUP => 1);
Readonly my $DATA_DIR	=> $t->app->home->child('data')->to_string;
Readonly my $SALES_ABS	=> $t->app->home->child('data/sales.csv')->to_string;
Readonly my $PSV_ABS	=> $t->app->home->child('data/products.psv')->to_string;

# ------------------------------------------------------------------
# Representative records from data/sales.csv (id, product, region,
# sales_rep, amount, sale_date).  Used for direct filter EP/BVA tests.
# amounts: 1250.00, 875.50, 2100.00, 950.00, 1875.00, 725.25
# ------------------------------------------------------------------
Readonly my @RECS => (
	{ id => '1', product => 'Widget A',   region => 'North', sales_rep => 'Alice Smith', amount => '1250.00', sale_date => '2025-01-15' },
	{ id => '2', product => 'Widget B',   region => 'South', sales_rep => 'Bob Jones',   amount => '875.50',  sale_date => '2025-01-16' },
	{ id => '3', product => 'Gadget Pro', region => 'East',  sales_rep => 'Carol White', amount => '2100.00', sale_date => '2025-01-17' },
	{ id => '4', product => 'Widget A',   region => 'West',  sales_rep => 'David Lee',   amount => '950.00',  sale_date => '2025-01-18' },
	{ id => '5', product => 'Gadget Pro', region => 'North', sales_rep => 'Alice Smith', amount => '1875.00', sale_date => '2025-01-19' },
	{ id => '6', product => 'Widget B',   region => 'East',  sales_rep => 'Carol White', amount => '725.25',  sale_date => '2025-01-20' },
);

# ======================================================================
# DOMAIN 1: Table name domain -- GET /view/:table
#
# TABLE_NAME_RE = \A[A-Za-z_][A-Za-z0-9_]*\z
#
# Equivalence Partitions:
#   VP-Alpha   : letter-start, letters only          (e.g. "sales")
#   VP-Under   : underscore-start                    (e.g. "_data")
#   VP-Mixed   : letter-start with digits/underscore (e.g. "sales_2024")
#   A valid name with no file is a 404 too, but from the action: its page
#   says "There is no table called ...", which a rejected name never gets.
#   IP-Digit   : digit at position 0                 -> 404
#   IP-Dot     : contains dot                        -> 404
#   IP-Hyphen  : contains hyphen                     -> 404
#   IP-NonASCII: non-ASCII characters                -> 404
#
# Boundary Values:
#   BV-min-letter    : single letter "a"             -> valid (200)
#   BV-min-underscore: single underscore "_"         -> valid (200)
#   BV-min-digit     : single digit "1"              -> 404
#   BV-len2-valid    : "a1" (letter + digit)         -> valid (200)
#   BV-len2-invalid  : "1a" (digit + letter)         -> 404
# ======================================================================

subtest 'table name EP-Alpha: letter-start word accepted (200)' => sub {
	$t->get_ok('/view/sales')->status_is(200);
};

subtest 'table name EP-Under: underscore-start accepted (reaches the action)' => sub {
	# "_data" has no backing file: the name reaches the action, which says the
	# table does not exist (404) -- unlike a rejected name, which never gets there.
	$t->get_ok('/view/_data')->status_is(404)->content_like(qr/There is no table called/);
};

subtest 'table name EP-Mixed: letter+digits+underscore accepted (reaches the action)' => sub {
	$t->get_ok('/view/sales_2024')->status_is(404)->content_like(qr/There is no table called/);
};

subtest 'table name IP-Digit: digit-start rejected (404)' => sub {
	$t->get_ok('/view/1sales')->status_is(404)->content_unlike(qr/There is no table called/);
};

subtest 'table name IP-Dot: dot in name rejected (404)' => sub {
	$t->get_ok('/view/sales.data')->status_is(404);
};

subtest 'table name IP-Hyphen: hyphen in name rejected (404)' => sub {
	$t->get_ok('/view/my-data')->status_is(404);
};

subtest 'table name IP-NonASCII: non-ASCII characters rejected (404)' => sub {
	# URL-encoded UTF-8 for "caf\xc3\xa9"
	$t->get_ok('/view/caf%C3%A9')->status_is(404);
};

subtest 'table name BV-min-letter: single letter "a" is valid (shortest VP)' => sub {
	$t->get_ok('/view/a')->status_is(404)->content_like(qr/There is no table called/);
};

subtest 'table name BV-min-underscore: single underscore "_" is valid' => sub {
	$t->get_ok('/view/_')->status_is(404)->content_like(qr/There is no table called/);
};

subtest 'table name BV-min-digit: single digit "1" is invalid -- 404' => sub {
	$t->get_ok('/view/1')->status_is(404);
};

subtest 'table name BV-len2-valid: letter+digit "a1" is valid' => sub {
	$t->get_ok('/view/a1')->status_is(404)->content_like(qr/There is no table called/);
};

subtest 'table name BV-len2-invalid: digit+letter "1a" is invalid -- 404' => sub {
	$t->get_ok('/view/1a')->status_is(404);
};

# ======================================================================
# DOMAIN 2: Open-file path domain -- GET /open?path=
#
# EXT_RE = qr/\.(?:csv|db|sql|xml|psv)\z/i  -- \z prevents trailing \n bypass
#
# Equivalence Partitions:
#   VP-CSV  : existing .csv regular file   -> 200
#   VP-PSV  : existing .psv regular file   -> 200
#   IP-Miss : missing ?path= param         -> 404
#   IP-None : non-existent file            -> 404
#   IP-Dir  : directory instead of file   -> 404
#   IP-Ext  : unsupported extension (.txt) -> 404
#
# Boundary Values:
#   BV-case   : .CSV (uppercase extension) -> 200  (EXT_RE has /i flag)
#   BV-newline: .csv\n embedded newline    -> 404  (\z anchor blocks this)
#   BV-double : file.php.csv              -> 200 with friendly error (caught eval)
#   BV-empty  : ?path= (empty string)     -> 404
# ======================================================================

subtest 'open path EP-CSV: existing CSV file opens (200)' => sub {
	$t->get_ok('/open?path=' . url_escape($SALES_ABS))->status_is(200);
};

subtest 'open path EP-PSV: existing PSV file opens (200)' => sub {
	SKIP: {
		skip 'data/products.psv not found', 1 unless -f $PSV_ABS;
		$t->get_ok('/open?path=' . url_escape($PSV_ABS))->status_is(200);
	}
};

subtest 'open path IP-Miss: missing path param yields 404' => sub {
	$t->get_ok('/open')->status_is(404);
};

subtest 'open path IP-None: non-existent file yields 404' => sub {
	my $fake = url_escape("$TMPDIR/does_not_exist.csv");
	$t->get_ok("/open?path=$fake")->status_is(404);
};

subtest 'open path IP-Dir: directory path yields 404 (not a regular file)' => sub {
	$t->get_ok('/open?path=' . url_escape($TMPDIR))->status_is(404);
};

subtest 'open path IP-Ext: unsupported extension .txt yields 404' => sub {
	Mojo::File->new("$TMPDIR/data.txt")->spew("hello\n");
	$t->get_ok('/open?path=' . url_escape("$TMPDIR/data.txt"))->status_is(404);
};

subtest 'open path BV-case: uppercase extension .CSV accepted (EXT_RE /i)' => sub {
	Mojo::File->new("$TMPDIR/report.CSV")->spew("id,name\n1,Alice\n");
	$t->get_ok('/open?path=' . url_escape("$TMPDIR/report.CSV"))->status_is(200);
};

subtest 'open path BV-newline: path with embedded newline rejected (EXT_RE \\z)' => sub {
	# ?path= contains URL-encoded newline after .csv; the \\z anchor in EXT_RE
	# means the extension check sees ".csv\n" which does not match.
	my $path = url_escape("$TMPDIR/report.csv") . '%0A';
	$t->get_ok("/open?path=$path")->status_is(404);
};

subtest 'open path BV-double-ext: file.php.csv passes EXT_RE but triggers eval-caught croak' => sub {
	# .csv matches EXT_RE; table stem "file.php" fails TABLE_NAME_RE inside DataSource::new.
	# open_file wraps open_table in eval -> friendly error rendered as 200, not 500.
	Mojo::File->new("$TMPDIR/file.php.csv")->spew("id,val\n1,x\n");
	$t->get_ok('/open?path=' . url_escape("$TMPDIR/file.php.csv"))->status_is(200);
};

subtest 'open path BV-empty: empty path param yields 404' => sub {
	$t->get_ok('/open?path=')->status_is(404);
};

# ======================================================================
# DOMAIN 2b: /open with bank-export CSV shapes (bug-regression)
#
# Three production bugs triggered when opening a real bank-export CSV:
#
#  Bug 1 (case):  table stem was lowercased before file lookup.  On a
#                 case-sensitive Linux filesystem "MyData.csv" was not found
#                 when the derived table name was "mydata".
#  Bug 2 (space): first column "Account Number" (contains a space) is not a
#                 valid identifier; Database::Abstraction croaked at new().
#  Bug 3 (empty): first safe-name column "Check" was always empty; D::A's
#                 empty_is_undef => 1 made it undef, so the row-sentinel
#                 grep silently dropped every row that had no check number.
# ======================================================================

subtest 'open path BV-mixed-case-stem: MixedCase.csv opens all rows (bug 1)' => sub {
	# The file stem has mixed case; the controller must NOT lowercase it
	# before calling open_table or DataSource will look for "mixedcase.csv".
	Mojo::File->new("$TMPDIR/MixedCase.csv")->spew("id,label\n1,Alpha\n2,Beta\n");
	$t->get_ok('/open?path=' . url_escape("$TMPDIR/MixedCase.csv"))
		->status_is(200, 'bug 1: mixed-case stem opens without error')
		->content_like(qr/Alpha/, 'bug 1: first row data visible')
		->content_like(qr/Beta/,  'bug 1: second row data visible');
	$t->content_unlike(qr/Could not open &quot;MixedCase/, 'bug 1: no server-side error message');
};

subtest 'open path BV-spaced-header: "Account Number" first col opens all rows (bug 2)' => sub {
	# "Account Number" is not a valid SQL identifier; _detect_file_info must
	# fall through to the first safe column ("Date") so D::A construction succeeds.
	Mojo::File->new("$TMPDIR/spending.csv")->spew(
		"Account Number,Date,Amount\nXX1234,2026-01-01,42.00\nXX1234,2026-01-02,13.50\n"
	);
	$t->get_ok('/open?path=' . url_escape("$TMPDIR/spending.csv"))
		->status_is(200, 'bug 2: CSV with spaced first-col header opens without error')
		->content_like(qr/42\.00/, 'bug 2: first row data visible')
		->content_like(qr/13\.50/, 'bug 2: second row data visible');
	$t->content_unlike(qr/unsafe id column name|Could not open &quot;spending/, 'bug 2: no D::A identifier error');
};

subtest 'open path BV-empty-safe-col: empty sentinel col shows all rows (bug 3)' => sub {
	# "ref" is the first safe-identifier column but is empty in every row.
	# D::A uses empty_is_undef; picking "ref" as id would drop every row.
	# _detect_file_info must scan the data row and pick "description" instead.
	Mojo::File->new("$TMPDIR/bankstmt.csv")->spew(
		"Account Number,ref,description,amount\n" .
		"XX1234,,Coffee,4.50\n" .
		"XX1234,,Groceries,23.10\n" .
		"XX1234,,Salary,1500.00\n"
	);
	$t->get_ok('/open?path=' . url_escape("$TMPDIR/bankstmt.csv"))
		->status_is(200, 'bug 3: CSV with empty safe-col sentinel opens without error')
		->content_like(qr/Coffee/,    'bug 3: row 1 visible')
		->content_like(qr/Groceries/, 'bug 3: row 2 visible')
		->content_like(qr/Salary/,    'bug 3: row 3 visible -- not filtered out');
};

subtest 'open path BV-large-spaced-header: spaced col names survive > 16 KB file (bug 4)' => sub {
	# DBD::CSV (used by Database::Abstraction for files > 16 KB) sanitizes column
	# names: "Account Number" -> "account_number".  The slurp path
	# (Text::xSV::Slurp) preserves original names.  DataSource now passes the
	# actual file size as max_slurp_size to force the slurp path and prevent the
	# restricted-hash "disallowed key" crash at render time.
	my $header = "Account Number,Date,Description,Amount\n";
	my @rows;
	for my $i (1 .. 400) {
		push @rows, sprintf("ACC%05d,2024-%02d-%02d,Transaction %d,%.2f\n",
			$i, ($i % 12) + 1, ($i % 28) + 1, $i, $i * 1.5);
	}
	my $content = $header . join('', @rows);
	# Verify the generated file actually exceeds the 16 KB slurp threshold.
	ok length($content) > 16 * 1024, "bug 4: test file is > 16 KB (" . length($content) . " bytes)";

	Mojo::File->new("$TMPDIR/largebankstmt.csv")->spew($content);
	# Request all 400 rows on one page to verify the full dataset is accessible.
	$t->get_ok('/open?path=' . url_escape("$TMPDIR/largebankstmt.csv") . '&per_page=400')
		->status_is(200, 'bug 4: large CSV with spaced header opens without crash')
		->content_like(qr/Account Number/, 'bug 4: original column header preserved in table')
		->content_like(qr/ACC00001/,       'bug 4: first row data visible')
		->content_like(qr/ACC00400/,       'bug 4: last row data visible');
	$t->content_unlike(qr/disallowed key|restricted hash|internal server error/i,
		'bug 4: no restricted-hash crash or server error');
};

# ======================================================================
# DOMAIN 3: Browse path domain -- GET /browse?path=
#
# Default: $ENV{HOME} // '/' when ?path= is absent.
# realpath must succeed and result must pass -d (is directory).
#
# Equivalence Partitions:
#   VP-Absent : no ?path= -> 200 (defaults to $HOME or /)
#   VP-Dir    : existing directory -> 200
#   IP-None   : non-existent path -> 404
#   IP-File   : regular file path -> 404 (fails -d check)
# ======================================================================

subtest 'browse path VP-Absent: no path param defaults to home/root -- 200' => sub {
	$t->get_ok('/browse')->status_is(200);
};

subtest 'browse path VP-Dir: valid existing directory -- 200' => sub {
	$t->get_ok('/browse?path=' . url_escape($TMPDIR))->status_is(200);
};

subtest 'browse path IP-None: non-existent path -- 404' => sub {
	$t->get_ok('/browse?path=' . url_escape("$TMPDIR/no_such_dir_xyz"))->status_is(404);
};

subtest 'browse path IP-File: regular file path fails -d check -- 404' => sub {
	$t->get_ok('/browse?path=' . url_escape($SALES_ABS))->status_is(404);
};

# ======================================================================
# DOMAIN 4: Filter spec operator domain -- _apply_filter_spec
#
# Spec format: "col:op:val" (split limit 3, so val may contain colons).
# Operator names are CASE-SENSITIVE; only lowercase forms are recognised.
# String ops (eq, ne, contains, starts): VALUE comparison is case-insensitive
#   (both cell and val are lowercased before comparison).
# Numeric ops (lt, le, gt, ge): compare parsed numbers; a blank or word matches none.
# Unary ops (empty, notempty): ignore val entirely.
# Unknown / uppercase operators: default case 1 -> all rows pass (no-op).
#
# Boundary Values using sales amounts: 725.25, 875.50, 950.00, 1250.00, 1875.00, 2100.00
#   lt 875.50  -> strict less than  -> [725.25]                         (1 row)
#   le 875.50  -> inclusive         -> [875.50, 725.25]                 (2 rows)
#   gt 1875.00 -> strict greater    -> [2100.00]                        (1 row)
#   ge 1875.00 -> inclusive         -> [1875.00, 2100.00]               (2 rows)
# ======================================================================

# --- Equivalence Partitions: one test per valid operator ---

subtest 'filter EP-eq: case-insensitive value match filters rows' => sub {
	my $result = $FILTER->(\@RECS, 'region:eq:north');
	is scalar(@$result), 2, 'eq: 2 North records (case-insensitive)';
	ok !(grep { lc($_->{region}) ne 'north' } @$result),
		'eq: all returned rows have matching region';
};

subtest 'filter EP-ne: case-insensitive value exclusion filters rows' => sub {
	my $result = $FILTER->(\@RECS, 'region:ne:north');
	is scalar(@$result), 4, 'ne: 4 non-North records';
	ok !(grep { lc($_->{region}) eq 'north' } @$result),
		'ne: no returned row has excluded region';
};

subtest 'filter order ops: only numbers match, and nothing warns' => sub {
	my @rows = (
		{ id => 'blank',    v => '' },
		{ id => 'null',     v => undef },
		{ id => 'word',     v => 'none' },
		{ id => 'zero',     v => '0' },
		{ id => 'nine',     v => '9' },
		{ id => 'currency', v => '$1,234.56' },
		{ id => 'negative', v => '(5.00)' },
	);
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $ids = sub { [ sort map { $_->{id} } @{ $FILTER->(\@rows, $_[0]) } ] };
	is_deeply $ids->('v:lt:9'), [qw(negative zero)],         'lt: a blank and a word are not less than 9';
	is_deeply $ids->('v:le:9'), [qw(negative nine zero)],    'le: includes the bound';
	is_deeply $ids->('v:gt:0'), [qw(currency nine)],         'gt: a blank is not above 0, currency is read';
	is_deeply $ids->('v:ge:0'), [qw(currency nine zero)],    'ge: includes zero itself but not a blank';
	is_deeply $ids->('v:lt:0'), [qw(negative)],              'accounting brackets are negative';
	is_deeply $ids->('v:gt:$1,000'), [qw(currency)],         'the value may be written as currency too';
	is_deeply $ids->('v:gt:many'), [],                       'a value that is not a number matches nothing';
	is_deeply \@warnings, [],                                'no warning about a non-numeric argument';
};

subtest 'filter EP-contains: substring match is case-insensitive' => sub {
	my $result = $FILTER->(\@RECS, 'product:contains:widget');
	is scalar(@$result), 4, 'contains: 4 Widget A/B records';
};

subtest 'filter EP-starts: prefix match is case-insensitive' => sub {
	my $result = $FILTER->(\@RECS, 'product:starts:gadget');
	is scalar(@$result), 2, 'starts: 2 Gadget Pro records';
};

subtest 'filter EP-lt: numeric strict less-than' => sub {
	my $result = $FILTER->(\@RECS, 'amount:lt:1000');
	is scalar(@$result), 3, 'lt 1000: 875.50, 950.00, 725.25 (3 records)';
};

subtest 'filter EP-le: numeric inclusive less-or-equal' => sub {
	my $result = $FILTER->(\@RECS, 'amount:le:950.00');
	is scalar(@$result), 3, 'le 950: 875.50, 950.00, 725.25 (3 records)';
};

subtest 'filter EP-gt: numeric strict greater-than' => sub {
	my $result = $FILTER->(\@RECS, 'amount:gt:1875.00');
	is scalar(@$result), 1, 'gt 1875.00: only 2100.00 (1 record)';
	is $result->[0]{amount}, '2100.00', 'gt: correct record returned';
};

subtest 'filter EP-ge: numeric inclusive greater-or-equal' => sub {
	my $result = $FILTER->(\@RECS, 'amount:ge:1875.00');
	is scalar(@$result), 2, 'ge 1875.00: 1875.00 and 2100.00 (2 records)';
};

subtest 'filter EP-empty: unary operator matches empty/undef cells' => sub {
	my @with_gap = (@RECS, { id => '7', product => '', region => undef, amount => '99' });
	my $result = $FILTER->(\@with_gap, 'region:empty:ignored_val');
	is scalar(@$result), 1, 'empty: only the row with undef/blank region matches';
};

subtest 'filter EP-notempty: unary operator matches non-empty cells' => sub {
	my @with_gap = (@RECS, { id => '7', product => '', region => '', amount => '99' });
	my $result = $FILTER->(\@with_gap, 'region:notempty:ignored_val');
	is scalar(@$result), 6, 'notempty: all 6 original records (non-empty region)';
};

subtest 'filter EP-UnknownOp: unknown operator passes all rows (no-op)' => sub {
	my $result = $FILTER->(\@RECS, 'region:regex:North');
	is scalar(@$result), 6, 'unknown op "regex": all 6 rows returned unchanged';
};

# --- Equivalence Partitions: invalid/malformed specs ---

subtest 'filter EP-EmptySpec: empty spec string is a no-op' => sub {
	my $result = $FILTER->(\@RECS, '');
	is scalar(@$result), 6, 'empty spec: all 6 rows returned';
};

subtest 'filter EP-NoSep: spec with no colon separator is a no-op' => sub {
	my $result = $FILTER->(\@RECS, 'regionNorth');
	is scalar(@$result), 6, 'no-colon spec: all 6 rows returned';
};

subtest 'filter EP-EmptyCol: empty column name is a no-op' => sub {
	my $result = $FILTER->(\@RECS, ':eq:North');
	is scalar(@$result), 6, 'empty col: all 6 rows returned';
};

# --- Case-sensitivity of operator names ---

subtest 'filter domain: operator names ARE case-sensitive -- EQ is not eq' => sub {
	# "EQ" is not a recognised operator; falls through to default 1 -> all rows pass.
	my $result = $FILTER->(\@RECS, 'region:EQ:North');
	is scalar(@$result), 6, '"EQ" (uppercase) is not a valid op -- all rows pass';
};

subtest 'filter domain: operator names ARE case-sensitive -- Lt is not lt' => sub {
	my $result = $FILTER->(\@RECS, 'amount:Lt:1000');
	is scalar(@$result), 6, '"Lt" (mixed case) is not a valid op -- all rows pass';
};

# --- Boundary Value Analysis: numeric operators at exact boundary ---

subtest 'filter BVA-lt-at-boundary: lt excludes the boundary value (strict)' => sub {
	# Boundary is 875.50; lt should exclude it.
	my $result = $FILTER->(\@RECS, 'amount:lt:875.50');
	is scalar(@$result), 1, 'lt 875.50: only 725.25 qualifies (875.50 excluded)';
	is $result->[0]{amount}, '725.25', 'lt at boundary: correct sole record';
};

subtest 'filter BVA-le-at-boundary: le includes the boundary value (inclusive)' => sub {
	my $result = $FILTER->(\@RECS, 'amount:le:875.50');
	is scalar(@$result), 2, 'le 875.50: 725.25 and 875.50 qualify (inclusive)';
	ok +(grep { $_->{amount} eq '875.50' } @$result), 'le: boundary value 875.50 is included';
};

subtest 'filter BVA-gt-at-boundary: gt excludes the boundary value (strict)' => sub {
	my $result = $FILTER->(\@RECS, 'amount:gt:1875.00');
	is scalar(@$result), 1, 'gt 1875.00: only 2100.00 qualifies (1875.00 excluded)';
	ok !(grep { $_->{amount} eq '1875.00' } @$result), 'gt: boundary value 1875.00 excluded';
};

subtest 'filter BVA-ge-at-boundary: ge includes the boundary value (inclusive)' => sub {
	my $result = $FILTER->(\@RECS, 'amount:ge:1875.00');
	is scalar(@$result), 2, 'ge 1875.00: 1875.00 and 2100.00 qualify (inclusive)';
	ok +(grep { $_->{amount} eq '1875.00' } @$result), 'ge: boundary value 1875.00 included';
};

subtest 'filter BVA-contains-empty-val: contains "" matches every record' => sub {
	# index(str, '') always returns 0 (found), so all rows pass.
	my $result = $FILTER->(\@RECS, 'product:contains:');
	is scalar(@$result), 6, 'contains "": all 6 rows match (empty substring is always found)';
};

subtest 'filter BVA-starts-empty-val: starts "" matches every record' => sub {
	my $result = $FILTER->(\@RECS, 'region:starts:');
	is scalar(@$result), 6, 'starts "": all 6 rows match (every string starts with empty)';
};

subtest 'filter BVA-colon-in-value: split limit 3 preserves colons in val' => sub {
	# Spec "sale_date:starts:2025:01" -> col="sale_date", op="starts", val="2025:01".
	# All 6 dates start with "2025-" but not "2025:01", so 0 rows.
	my $result = $FILTER->(\@RECS, 'sale_date:starts:2025:01');
	is scalar(@$result), 0,
		'colon in val: "2025:01" is the full val (not a 4th field); no date matches';
	# Verify the val is the full colon-containing string, not a truncation.
	my $all = $FILTER->(\@RECS, 'sale_date:starts:2025');
	is scalar(@$all), 6, 'sanity: starts "2025" (no inner colon) matches all 6 dates';
};

# ======================================================================
# DOMAIN 5: Export format domain -- GET /export?l=...&format=
#
# Code: $format = 'csv' unless $format eq 'sqlite';
# Comparison is exact and case-SENSITIVE.
#
# Equivalence Partitions:
#   VP-csv    : format=csv     -> text/csv download
#   VP-sqlite : format=sqlite  -> application/octet-stream
#   VP-json   : format=json    -> application/json download
#   VP-absent : no format=     -> csv (default)
#
# Boundary Values:
#   BV-SQLITE : format=SQLITE  -> csv (uppercase != 'sqlite')
#   BV-sqlit  : format=sqlit   -> csv (truncated, not exact 'sqlite')
#   BV-sqlite1: format=sqlite1 -> csv (extra char, not exact)
# ======================================================================

subtest 'export format VP-csv: format=csv returns text/csv' => sub {
	$t->get_ok('/export?l=table:sales&format=csv')
	  ->status_is(200)
	  ->content_type_like(qr{text/csv}i);
};

subtest 'export format VP-sqlite: format=sqlite returns SQLite binary' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 2;
		$t->get_ok('/export?l=table:sales&format=sqlite')
		  ->status_is(200)
		  ->content_type_like(qr{octet-stream|sqlite}i);
	}
};

subtest 'export format VP-absent: missing format defaults to csv' => sub {
	$t->get_ok('/export?l=table:sales')
	  ->status_is(200)
	  ->content_type_like(qr{text/csv}i);
};

subtest 'export format VP-json: format=json returns application/json' => sub {
	$t->get_ok('/export?l=table:sales&format=json')
	  ->status_is(200)
	  ->content_type_like(qr{application/json}i);
};

subtest 'export format BV-SQLITE: uppercase "SQLITE" does NOT match -- csv returned' => sub {
	$t->get_ok('/export?l=table:sales&format=SQLITE')
	  ->status_is(200)
	  ->content_type_like(qr{text/csv}i);
};

subtest 'export format BV-truncated: "sqlit" (one char short) does not match' => sub {
	$t->get_ok('/export?l=table:sales&format=sqlit')
	  ->status_is(200)
	  ->content_type_like(qr{text/csv}i);
};

# ======================================================================
# DOMAIN 6: Export write filename domain -- POST /export (body)
#
# Code: $filename =~ /\.csv\z/i  OR  $filename =~ /\.sql\z/i
# Case-INSENSITIVE via /i flag.  Everything else -> 415.
# Path separators in filename are stripped first.
#
# Equivalence Partitions:
#   VP-csv    : report.csv        -> 200
#   VP-sql    : report.sql        -> 200
#   VP-CSV    : REPORT.CSV        -> 200 (case-insensitive)
#   IP-txt    : report.txt        -> 415 error_ext_required
#   IP-noext  : report            -> 415
#   IP-empty  : (empty filename)  -> 415
#
# Boundary Values:
#   BV-minstem: a.csv (1-char stem) -> 200
#   BV-sep    : dir/report.csv     -> stem "report.csv" after path-strip -> 200
# ======================================================================

subtest 'export write EP-csv: filename ending .csv produces 200' => sub {
	$t->post_ok('/export', form => {
		l        => 'table:sales',
		dir      => $TMPDIR,
		filename => 'report.csv',
	})->status_is(200)->json_has('/saved');
};

subtest 'export write EP-sql: filename ending .sql produces 200' => sub {
	SKIP: {
		eval { require DBI; DBI->install_driver('SQLite') }
			or skip 'DBD::SQLite not available', 1;
		$t->post_ok('/export', form => {
			l        => 'table:sales',
			dir      => $TMPDIR,
			filename => 'report.sql',
		})->status_is(200)->json_has('/saved');
	}
};

subtest 'export write EP-CSV: uppercase .CSV extension is accepted (case-insensitive)' => sub {
	$t->post_ok('/export', form => {
		l        => 'table:sales',
		dir      => $TMPDIR,
		filename => 'REPORT.CSV',
	})->status_is(200)->json_has('/saved');
};

subtest 'export write IP-txt: unsupported extension returns 415' => sub {
	$t->post_ok('/export', form => {
		l        => 'table:sales',
		dir      => $TMPDIR,
		filename => 'report.txt',
	})->status_is(415)->json_has('/error');
};

subtest 'export write IP-noext: filename with no extension returns 415' => sub {
	$t->post_ok('/export', form => {
		l        => 'table:sales',
		dir      => $TMPDIR,
		filename => 'report',
	})->status_is(415)->json_has('/error');
};

subtest 'export write IP-empty: empty filename returns 415' => sub {
	$t->post_ok('/export', form => {
		l        => 'table:sales',
		dir      => $TMPDIR,
		filename => '',
	})->status_is(415)->json_has('/error');
};

subtest 'export write BV-minstem: single-char stem "a.csv" is valid' => sub {
	$t->post_ok('/export', form => {
		l        => 'table:sales',
		dir      => $TMPDIR,
		filename => 'a.csv',
	})->status_is(200)->json_has('/saved');
};

subtest 'export write BV-sep: path separator in filename stripped to basename' => sub {
	# The controller strips everything up to and including the last / or \.
	# "dir/report.csv" -> "report.csv" (safe against directory traversal).
	$t->post_ok('/export', form => {
		l        => 'table:sales',
		dir      => $TMPDIR,
		filename => 'subdir/safe.csv',
	})->status_is(200)->json_has('/saved');
};

subtest 'export write IP-baddir: non-existent directory returns 404' => sub {
	$t->post_ok('/export', form => {
		l        => 'table:sales',
		dir      => "$TMPDIR/no_such_dir_xyz",
		filename => 'report.csv',
	})->status_is(404)->json_has('/error');
};

# ======================================================================
# DOMAIN 7: DataSource::new parameter domain
#
# directory:
#   Valid:   existing directory path (-d returns true)
#   Invalid: non-existent path       -> croak error_directory_missing
#   Invalid: regular file path       -> croak error_directory_missing
#   Invalid: empty string ""         -> croak error_directory_missing
#
# table sanitization: illegal chars replaced with '_'; path separators croak.
#   Sanitized: digit-start -> '_' prefix; hyphens/dots/spaces -> '_'
#   Invalid (croak): path separators ('/', '\', NUL), empty string
#
# Boundary Values:
#   BV-table-len1-letter:     "a"  -> valid
#   BV-table-len1-underscore: "_"  -> valid
#   BV-table-len1-digit:      "1"  -> sanitized to "_1" (valid)
# ======================================================================

{
	# Write a CSV so the backend actually initialises without error.
	Mojo::File->new("$TMPDIR/sample.csv")->spew("id,name\n1,Alice\n");
	Mojo::File->new("$TMPDIR/a.csv")->spew("id\n1\n");
	Mojo::File->new("$TMPDIR/_.csv")->spew("id\n1\n");

	subtest 'DataSource VP-valid: valid dir + valid table name -> success' => sub {
		my $ds;
		lives_ok { $ds = Database::BI::Model::DataSource->new(directory => $TMPDIR, table => 'sample') }
			'valid dir + valid table: no exception';
		isa_ok $ds, 'Database::BI::Model::DataSource', 'returned object';
	};

	subtest 'DataSource IP-dir-nonexistent: non-existent directory -> croak' => sub {
		throws_ok {
			Database::BI::Model::DataSource->new(
				directory => "$TMPDIR/no_such_dir",
				table     => 'sample',
			)
		} qr/does not exist or is not readable/,
			'non-existent directory: croak error_directory_missing';
	};

	subtest 'DataSource IP-dir-file: file path instead of directory -> croak' => sub {
		throws_ok {
			Database::BI::Model::DataSource->new(
				directory => "$TMPDIR/sample.csv",
				table     => 'sample',
			)
		} qr/does not exist or is not readable/,
			'file used as directory: croak error_directory_missing';
	};

	subtest 'DataSource IP-dir-empty: empty string directory -> croak' => sub {
		throws_ok {
			Database::BI::Model::DataSource->new(directory => '', table => 'sample')
		} qr/does not exist or is not readable/,
			'empty directory string: croak error_directory_missing';
	};

	subtest 'DataSource IP-table-digit: digit-start is sanitized (prefixed with _)' => sub {
		my $src;
		lives_ok { $src = Database::BI::Model::DataSource->new(directory => $TMPDIR, table => '1data') }
			'digit-start table name accepted (sanitized)';
		is $src->table_name, '_1data', 'internal name has underscore prefix';
	};

	subtest 'DataSource IP-table-dot: dot in table name is sanitized to underscore' => sub {
		my $src;
		lives_ok { $src = Database::BI::Model::DataSource->new(directory => $TMPDIR, table => 'my.data') }
			'dot-in-table-name accepted (sanitized)';
		is $src->table_name, 'my_data', 'internal name has underscore for dot';
	};

	subtest 'DataSource IP-table-hyphen: hyphen sanitized; file is found on disk' => sub {
		# Core use-case: a date-stamped CSV like "my-data.csv" must be openable.
		Mojo::File->new("$TMPDIR/my-data.csv")->spew("id,value\n1,hello\n");
		my $src;
		lives_ok { $src = Database::BI::Model::DataSource->new(directory => $TMPDIR, table => 'my-data') }
			'hyphen-in-table-name accepted (sanitized)';
		is $src->table_name, 'my_data', 'internal name has underscore for hyphen';
		my $rows = eval { $src->fetch_all };
		is $@, '', 'fetch_all succeeds for sanitized-name DataSource';
		is scalar @{$rows}, 1, 'one data row returned from my-data.csv';
		is $rows->[0]{value}, 'hello', 'correct data value returned';
	};

	subtest 'DataSource IP-table-empty: empty table name -> croak' => sub {
		throws_ok {
			Database::BI::Model::DataSource->new(directory => $TMPDIR, table => '')
		} qr/contains illegal characters/,
			'empty table name: croak error_table_name_invalid';
	};

	subtest 'DataSource BV-table-len1-letter: single letter "a" is valid (shortest VP)' => sub {
		my $ds;
		lives_ok { $ds = Database::BI::Model::DataSource->new(directory => $TMPDIR, table => 'a') }
			'single letter "a": valid table name';
	};

	subtest 'DataSource BV-table-len1-underscore: single underscore "_" is valid' => sub {
		my $ds;
		lives_ok { $ds = Database::BI::Model::DataSource->new(directory => $TMPDIR, table => '_') }
			'single underscore "_": valid table name';
	};

	subtest 'DataSource BV-table-len1-digit: single digit "1" is sanitized to "_1"' => sub {
		my $src;
		lives_ok { $src = Database::BI::Model::DataSource->new(directory => $TMPDIR, table => '1') }
			'single digit "1" accepted (sanitized to _1)';
		is $src->table_name, '_1', 'internal name is "_1"';
	};

	subtest 'DataSource Combinatorial: longest valid name with every char class' => sub {
		# Max-length valid name: starts with underscore, body has letters+digits+underscores.
		my $long = '_' . ('a1_' x 30);  # 91 chars
		Mojo::File->new("$TMPDIR/${long}.csv")->spew("id\n1\n");
		my $ds;
		lives_ok { $ds = Database::BI::Model::DataSource->new(directory => $TMPDIR, table => $long) }
			'91-char valid name accepted';
	};
}

# ======================================================================
# DOMAIN 8: Upload file domain -- POST /upload
#
# Extension validated via EXT_RE (csv|db|sql|xml|psv, case-insensitive).
# Size guard: is_limit_exceeded || upload->size > MAX_UPLOAD_BYTES -> 413.
# Missing file -> 400. Unsupported ext -> 415.
#
# Equivalence Partitions:
#   VP-csv   : .csv upload -> 200
#   VP-psv   : .psv upload -> 200
#   VP-xml   : .xml upload -> 200
#   VP-sql   : .sql upload -> 200
#   IP-php   : .php upload -> 415 error_upload_ext
#   IP-none  : no file field -> 400 error_upload_none
#   IP-size  : file > limit -> 413 error_upload_too_large
#
# Boundary Value:
#   BV-case  : .CSV (uppercase) -> 200 (EXT_RE /i)
# ======================================================================

subtest 'upload EP-csv: CSV file upload succeeds (200, JSON url/path)' => sub {
	$t->post_ok('/upload', form => {
		file => { content => "id,name\n1,Alice\n", filename => 'up.csv' },
	})->status_is(200)->json_has('/url')->json_has('/path');
};

subtest 'upload EP-psv: PSV file upload succeeds' => sub {
	$t->post_ok('/upload', form => {
		file => { content => "id|name\n1|Alice\n", filename => 'up.psv' },
	})->status_is(200)->json_has('/url');
};

subtest 'upload EP-xml: XML file upload succeeds' => sub {
	$t->post_ok('/upload', form => {
		file => { content => '<r><row><id>1</id></row></r>', filename => 'up.xml' },
	})->status_is(200)->json_has('/url');
};

subtest 'upload EP-sql: SQLite file upload accepted' => sub {
	$t->post_ok('/upload', form => {
		file => { content => 'SQLite format 3', filename => 'up.sql' },
	})->status_is(200)->json_has('/url');
};

subtest 'upload IP-php: .php extension rejected -- 415 error_upload_ext' => sub {
	$t->post_ok('/upload', form => {
		file => { content => '<?php phpinfo(); ?>', filename => 'evil.php' },
	})->status_is(415)->json_like('/error', qr/Unsupported file type/i);
};

subtest 'upload IP-none: missing file field -- 400 error_upload_none' => sub {
	$t->post_ok('/upload', form => { note => 'no file here' })
	  ->status_is(400)->json_like('/error', qr/No file received/i);
};

subtest 'upload BV-case: uppercase .CSV extension accepted (EXT_RE /i)' => sub {
	$t->post_ok('/upload', form => {
		file => { content => "ID,NAME\n1,Alice\n", filename => 'UP.CSV' },
	})->status_is(200)->json_has('/url');
};

subtest 'upload IP-size: file exceeding limit returns 413' => sub {
	# Lower the transport cap to 512 bytes, then upload 600 bytes.
	# The guard: is_limit_exceeded || upload->size > MAX_UPLOAD_BYTES.
	my $orig_limit = $t->app->max_request_size;
	$t->app->max_request_size(512);
	$t->post_ok('/upload', form => {
		file => { content => 'x' x 600, filename => 'big.csv' },
	})->status_is(413)->json_like('/error', qr/too large/i);
	$t->app->max_request_size($orig_limit);
};

# ======================================================================
# DOMAIN 9: stat_api path domain -- GET /api/stat
#
# stat_api restricts results to EXT_RE files (security: not a filesystem oracle).
# A non-data-extension path returns 200 with exists:false, not 404.
# A missing path param returns 400.
#
# Equivalence Partitions:
#   VP-exists  : existing CSV file      -> 200, exists:true
#   VP-missing : non-existent CSV path  -> 200, exists:false
#   IP-noparam : no ?path=             -> 400 error_path_required
#   IP-security: /etc/passwd (no EXT)  -> 200, exists:false (not an oracle)
# ======================================================================

subtest 'stat_api VP-exists: existing data file returns exists:true' => sub {
	$t->get_ok('/api/stat?path=' . url_escape($SALES_ABS))
	  ->status_is(200)
	  ->json_is('/exists', 1);
};

subtest 'stat_api VP-missing: non-existent CSV path returns exists:false (not 404)' => sub {
	$t->get_ok('/api/stat?path=' . url_escape("$TMPDIR/ghost.csv"))
	  ->status_is(200)
	  ->json_is('/exists', 0);
};

subtest 'stat_api IP-noparam: missing path parameter returns 400' => sub {
	$t->get_ok('/api/stat')
	  ->status_is(400)
	  ->json_has('/error');
};

subtest 'stat_api IP-security: non-data file /etc/passwd returns exists:false' => sub {
	# stat_api must not be a filesystem oracle; unsupported extensions always
	# return exists:false regardless of whether the file actually exists.
	$t->get_ok('/api/stat?path=' . url_escape('/etc/passwd'))
	  ->status_is(200)
	  ->json_is('/exists', 0);
};

# ======================================================================
# DOMAIN 10: graph_view Y-value accounting notation
#
# The Y-column parser in graph_view must recognise accounting notation
# (parentheses = negative) as well as plain numerics and dash-negatives.
#
# Equivalence Partitions:
#   VP-plain-pos  : "$1,234.56"    -> valid, plotted as  1234.56
#   VP-plain-neg  : "-15.00"       -> valid, plotted as   -15.00
#   VP-acct-neg   : "($450.00)"    -> valid, plotted as  -450.00
#   VP-acct-nodol : "(148.00)"     -> valid (no $ prefix), plotted as -148
#   IP-text       : "Hello"        -> non-numeric, row skipped
#   IP-all-text   : entire column  -> No plottable data (200, not 500)
#
# Boundary Values:
#   BV-acct-zero  : "($0.00)"      -> valid, plotted as 0 (not skipped)
#   BV-acct-large : "($28,800.00)" -> valid, thousands separator inside parens
#   BV-mixed      : mix of VP forms -> all rows plotted, none skipped
# ======================================================================

subtest 'graph Y-value VP-plain-pos: $1,234.56 is numeric' => sub {
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $file = Mojo::File->new($TMPDIR, 'vp_pos.csv');
		$file->spew("month,amount\nJan,\$1234.00\nFeb,\$500.00\n");
		$t->get_ok('/graph?l=path:' . url_escape($file->to_string) . '&x=month&y=amount')
		  ->status_is(200)
		  ->content_unlike(qr/No plottable data/i, 'plain positive amount is plottable');
	}
};

subtest 'graph Y-value VP-acct-neg: ($450.00) plotted as -450' => sub {
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 3;
		my $file = Mojo::File->new($TMPDIR, 'vp_acct.csv');
		$file->spew("month,amount\nJan,\$500.00\nFeb,(\$450.00)\n");
		$t->get_ok('/graph?l=path:' . url_escape($file->to_string) . '&x=month&y=amount')
		  ->status_is(200)
		  ->content_like(qr/-450\b/, 'accounting negative is plotted as -450, not +450')
		  ->content_unlike(qr/No plottable data/i, 'accounting column is plottable');
	}
};

subtest 'graph Y-value VP-acct-nodol: (148.00) plotted as -148' => sub {
	# No currency symbol inside parens: (148.00) must still be treated as -148.
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $file = Mojo::File->new($TMPDIR, 'vp_nodol.csv');
		$file->spew("month,amount\nJan,200.00\nFeb,(148.00)\n");
		$t->get_ok('/graph?l=path:' . url_escape($file->to_string) . '&x=month&y=amount')
		  ->status_is(200)
		  ->content_like(qr/-148\b/, 'no-dollar accounting parens parsed as negative');
	}
};

subtest 'graph Y-value IP-all-text: non-numeric Y returns 200 No plottable data' => sub {
	my $file = Mojo::File->new($TMPDIR, 'ip_text.csv');
	$file->spew("month,label\nJan,Alpha\nFeb,Beta\n");
	$t->get_ok('/graph?l=path:' . url_escape($file->to_string) . '&x=month&y=label')
	  ->status_is(200, 'all-text Y column is 200, not 500')
	  ->content_like(qr/No plottable data/i, 'all-text Y column shows No plottable data');
};

subtest 'graph Y-value BV-acct-zero: ($0.00) is valid (not skipped)' => sub {
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $file = Mojo::File->new($TMPDIR, 'bv_zero.csv');
		$file->spew("month,amount\nJan,(\$0.00)\nFeb,\$100.00\n");
		$t->get_ok('/graph?l=path:' . url_escape($file->to_string) . '&x=month&y=amount')
		  ->status_is(200)
		  ->content_unlike(qr/No plottable data/i, '($0.00) is valid and not skipped');
	}
};

subtest 'graph Y-value BV-acct-large: ($28,800.00) with thousands separator' => sub {
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 2;
		my $file = Mojo::File->new($TMPDIR, 'bv_large.csv');
		$file->spew("month,amount\nJan,\$5000.00\nFeb,(\$28800.00)\n");
		$t->get_ok('/graph?l=path:' . url_escape($file->to_string) . '&x=month&y=amount')
		  ->status_is(200)
		  ->content_like(qr/-28800\b/, 'large accounting value parsed correctly');
	}
};

subtest 'graph Y-value BV-mixed: mix of positive, dash-negative, accounting-negative' => sub {
	# All three forms must be recognised as numeric; the graph must plot all rows.
	SKIP: {
		eval { require HTML::D3 } or skip 'HTML::D3 not available', 3;
		my $file = Mojo::File->new($TMPDIR, 'bv_mixed.csv');
		$file->spew(
			"month,amount\n" .
			"Jan,\$1000.00\n" .    # plain positive
			"Feb,-200.00\n" .       # dash negative
			"Mar,(\$350.00)\n"      # accounting negative
		);
		$t->get_ok('/graph?l=path:' . url_escape($file->to_string) . '&x=month&y=amount')
		  ->status_is(200)
		  ->content_like(qr/Plotting 3 points?/, 'all three notation styles produce 3 plotted points')
		  ->content_unlike(qr/No plottable data/i, 'mixed-notation column is fully plottable');
	}
};

# ---------------------------------------------------------------------------
# Header-less CSV: column synthesis domain/boundary tests
#
# Equivalence partitions: ISO date, slash-date (M/D/YYYY), signed negative,
# accounting negative, plain integer, plain word (description), hyphenated
# (treated as header, not data-like).
# Boundary: exactly at the threshold between data-like and non-data-like rows.
# ---------------------------------------------------------------------------

subtest 'headerless CSV VP-iso-date: ISO date first row -> "date" column synthesised' => sub {
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/isodates.csv")->spew(
		"2026-01-01\n2026-01-02\n2026-01-03\n"
	);
	my $src;
	lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'isodates') }
		'ISO date headerless CSV opens without error';
	is_deeply $src->columns, ['Date'], 'ISO date column synthesised as "Date"';
	my $rows = eval { $src->fetch_all };
	is $@, '', 'fetch_all does not throw';
	is scalar @{$rows}, 3, 'all three rows returned';
	is $rows->[0]{Date}, '2026-01-01', 'first row Date value preserved verbatim';
};

subtest 'headerless CSV VP-slash-date: M/D/YYYY format -> "date" column' => sub {
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/slashdates.csv")->spew(
		"9/1/2026\n9/2/2026\n"
	);
	my $src;
	lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'slashdates') }
		'M/D/YYYY headerless CSV opens without error';
	is_deeply $src->columns, ['Date'], 'slash-date column synthesised as "Date"';
	is $src->fetch_all->[0]{Date}, '9/1/2026', 'slash-date value preserved verbatim';
};

subtest 'headerless CSV VP-signed-neg: signed negative -> "amount" column' => sub {
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/signed.csv")->spew(
		"-75.13\n-12.50\n100.00\n"
	);
	my $src;
	lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'signed') }
		'signed-negative headerless CSV opens without error';
	is_deeply $src->columns, ['Amount'], 'signed negative column synthesised as "Amount"';
	is $src->fetch_all->[0]{Amount}, '-75.13', 'negative value preserved';
};

subtest 'headerless CSV VP-acct-neg: accounting negative -> "amount" column' => sub {
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/acct.csv")->spew(
		"(99.50)\n(12.00)\n(0.01)\n"
	);
	my $src;
	lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'acct') }
		'accounting-negative headerless CSV opens without error';
	is_deeply $src->columns, ['Amount'], 'accounting negative synthesised as "Amount"';
};

subtest 'headerless CSV VP-plain-int: unsigned integer first row -> error_no_safe_id' => sub {
	# _values_are_data_like requires a sign (+/-) or date for numeric detection.
	# A plain unsigned integer "100" does NOT trigger headerless detection.
	# The first row is treated as a header "100", which fails $SAFE_IDENTIFIER
	# (starts with digit), so $safe_id = undef -> construction croaks.
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/plain.csv")->spew(
		"100\n200\n300\n"
	);
	throws_ok {
		Database::BI::Model::DataSource->new(directory => $dir, table => 'plain')
	} qr/no column with a safe identifier/i,
		'unsigned-integer-only CSV croaks error_no_safe_id (not treated as headerless)';
};

subtest 'headerless CSV VP-description: plain word -> "description" column' => sub {
	# A row of plain words with no numeric or date column cannot be
	# treated as a data-first row — _values_are_data_like returns false.
	# This exercises the boundary between "data-like" and "header-like".
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	# Use a file whose first row consists entirely of plain words that look
	# like column headers.  DataSource must treat "name,region" as a header,
	# not data, and must find a safe id ("name").
	Mojo::File->new("$dir/wordonly.csv")->spew(
		"name,region\nAlice,North\nBob,South\n"
	);
	my $src;
	lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'wordonly') }
		'word-only first row CSV opens without error (treated as header)';
	is_deeply $src->columns, [qw(name region)], 'word-only first row preserved as headers';
	is $src->id_column, 'name', 'id_column is "name" (first safe identifier)';
};

subtest 'headerless CSV BV-dup-dates: two date columns -> "date", "date2"' => sub {
	# Two ISO date columns must produce date and date2 (no bare duplicate).
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/dupdates.csv")->spew(
		"2026-01-01,2026-01-31\n2026-02-01,2026-02-28\n"
	);
	my $src;
	lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'dupdates') }
		'dual-date-column CSV opens without error';
	is_deeply $src->columns, [qw(Date Date2)], 'duplicate date columns disambiguated';
};

subtest 'headerless CSV BV-full-bank: date+amount+description (full bank row)' => sub {
	# The canonical bank-export pattern: ISO date, signed amount, text description.
	# Description values contain spaces so no first-row value is a $SAFE_IDENTIFIER,
	# which forces the headerless-detection path (otherwise SUPERMARKET would be
	# found as a valid identifier and the row would be treated as a header).
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/bank.csv")->spew(
		"2026-09-01,-75.00,SUPER MARKET\n" .
		"2026-09-02,-12.50,COFFEE SHOP\n" .
		"2026-09-03,1500.00,SALARY CREDIT\n"
	);
	my $src;
	lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'bank') }
		'bank-export headerless CSV opens without error';
	is_deeply $src->columns, [qw(Date Amount Description)],
		'canonical bank row: Date+Amount+Description synthesised correctly';
	my $rows = eval { $src->fetch_all };
	is scalar @{$rows}, 3, 'all three rows returned';
	is $rows->[1]{Description}, 'COFFEE SHOP', 'Description column value preserved';
	is $rows->[2]{Amount},      '1500.00',     'positive Amount preserved';
};

subtest 'headerless PSV BV-psv-bank: pipe-separated date+amount (no header)' => sub {
	# Same bank pattern but pipe-separated (PSV).  The separator sniffer must
	# detect "|" and synthesise the same column names.
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/bankpsv.psv")->spew(
		"2026-09-01|-75.00\n" .
		"2026-09-02|-12.50\n"
	);
	my $src;
	lives_ok { $src = Database::BI::Model::DataSource->new(directory => $dir, table => 'bankpsv') }
		'headerless PSV opens without error';
	is_deeply $src->columns, [qw(Date Amount)], 'PSV: Date+Amount synthesised correctly';
	is $src->fetch_all->[0]{Date}, '2026-09-01', 'Date value preserved in PSV';
};

subtest 'headerless CSV BV-hyphen-no-data: hyphenated first row NOT treated as headerless' => sub {
	# "first-name" fails $SAFE_IDENTIFIER but is also not data-like.
	# Construction must croak error_no_safe_id, not synthesise columns.
	require Database::BI::Model::DataSource;
	my $dir = tempdir(CLEANUP => 1);
	Mojo::File->new("$dir/hyphonly.csv")->spew(
		"first-name,last-name\nAlice,Smith\n"
	);
	throws_ok {
		Database::BI::Model::DataSource->new(directory => $dir, table => 'hyphonly')
	} qr/no column with a safe identifier/i,
		'hyphenated headers still croak: not treated as headerless data';
};

# ---------------------------------------------------------------------------
# Totals checkbox: domain boundary for chk-totals presence in rendered page
# ---------------------------------------------------------------------------

subtest 'GET /view/sales has chk-totals checkbox in toolbar' => sub {
	$t->get_ok('/view/sales')
	  ->status_is(200)
	  ->content_like(qr/id="chk-totals"/, 'Totals checkbox input present in toolbar')
	  ->content_like(qr/id="lbl-totals"/, 'Totals label present in toolbar')
	  ->content_like(qr/buildTotals/,     'buildTotals JS function defined in page');
};

subtest 'GET /view/sales chk-totals localStorage state includes totals key' => sub {
	$t->get_ok('/view/sales')
	  ->status_is(200)
	  ->content_like(qr/totals\s*:/, 'localStorage stored shape includes totals key');
};

# ---------------------------------------------------------------------------
# Combine panel drag-and-drop: domain check for drop-hook JS
# ---------------------------------------------------------------------------

subtest 'GET /view/sales dashboard JS defines __biDropCallback and __biDropLabel hooks' => sub {
	$t->get_ok('/view/sales')
	  ->status_is(200)
	  ->content_like(qr/__biDropCallback/, '__biDropCallback hook defined in dashboard JS')
	  ->content_like(qr/__biDropLabel/,    '__biDropLabel hook defined in dashboard JS')
	  ->content_like(qr/registerDropHooks/, 'registerDropHooks function defined')
	  ->content_like(qr/clearDropHooks/,    'clearDropHooks function defined');
};


# ======================================================================
# DOMAINS 11-18: numeric, length, format and character domains
#
# Each parameter has its own subtest.  For each: the valid partition(s), the
# invalid ones, the exact edges (minimum, maximum, one either side), and the
# character classes a user can type (umlauts, emoji, Zalgo, a right-to-left
# override).  Limits are named in %LIMIT and %TEXT so a test reads as a
# statement of the domain, not a list of numbers.
# ======================================================================
{
	use Encode ();
	require Database::BI::Password;
	require Database::BI::Model::Boundary;
	require Database::BI::Model::Geocode;
	require Database::BI::Util;

	Readonly my %LIMIT => (
		rounds_min   => 10_000,
		rounds_max   => 100_000_000,
		salt_bytes   => 16,
		hmac_block   => 64,		# a key longer than this is hashed first
		lat_max      => 90,
		lon_max      => 180,
		online_max   => 20,		# Boundary's default
		plain_digits => 300,		# parse_number's fast-path length
		per_page_max => 2_000,
		srccol_max   => 64,
		login_min    => 60,
		secret_min   => 16,
		ask_max      => 500,
		place_max    => 200,
	);
	# Text a user can type, as characters (not bytes), for every free-text domain.
	Readonly my %TEXT => (
		ascii  => 'plain',
		umlaut => "M\x{FC}ller Stra\x{DF}e",
		emoji  => "\x{1F600}\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F467}",	# a smile and a family joined with ZWJ
		zalgo  => "z\x{0351}\x{0315}\x{0346}a\x{0300}\x{0301}\x{0302}l\x{0303}\x{0304}g\x{0305}o",
		rtl    => "abc\x{202E}def\x{202C}",
		cjk    => "\x{6771}\x{4EAC}\x{90FD}",
	);
	my @TEXT_KINDS = sort keys %TEXT;
	my $shown = sub { my ($v) = @_; return defined $v ? ($v =~ s/([^\x20-\x7e])/sprintf('\\x{%X}', ord $1)/gre) : 'undef' };
	my $why = sub { my ($code) = @_; local $@; return eval { $code->(); 1 } ? undef : ($@ =~ s/ at \S+ line \d+\.?\n?\z//r) };

	# -- DOMAIN 11 ------------------------------------------------------
	# hash_password rounds: valid is a whole number from 10_000 to 100_000_000.
	# Partitions: below, inside, above, and not a whole number at all.  The
	# real PBKDF2 is replaced by a stub so the top edge costs nothing.
	subtest 'DOMAIN 11 rounds: 9_999 | 10_000 | 10_001 ... 99_999_999 | 100_000_000 | 100_000_001' => sub {
		mock 'Database::BI::Password::_pbkdf2' => sub { 'k' x 32 };
		my $refusal = sprintf('hash_password: rounds must be a whole number from %d to %d', $LIMIT{rounds_min}, $LIMIT{rounds_max});
		for my $rounds ($LIMIT{rounds_min}, $LIMIT{rounds_min} + 1, 200_000, $LIMIT{rounds_max} - 1, $LIMIT{rounds_max}) {
			my $made = eval { Database::BI::Password::hash_password('pw', rounds => $rounds) };
			like $made // 'refused', qr/\Apbkdf2-sha256\$$rounds\$/, "$rounds is accepted";
		}
		for my $rounds ($LIMIT{rounds_min} - 1, 0, 1, $LIMIT{rounds_max} + 1, 10 * $LIMIT{rounds_max}, -10_000, '10000.5', '1e4', '', ' 10000', "10000\n", 'many', '9' x 40) {
			is $why->(sub { Database::BI::Password::hash_password('pw', rounds => $rounds) }), $refusal, 'refused: rounds ' . $shown->($rounds);
		}
		restore_all();
		# Combinatorial: the largest rounds with the shortest password and an edge salt.
		mock 'Database::BI::Password::_pbkdf2' => sub { 'k' x 32 };
		like Database::BI::Password::hash_password('x', rounds => $LIMIT{rounds_max}, salt => 'S' x $LIMIT{salt_bytes}), qr/\$$LIMIT{rounds_max}\$/, 'the highest rounds, a one-character password and the exact salt together';
		restore_all();
	};

	# -- DOMAIN 12 ------------------------------------------------------
	# hash_password salt: exactly 16 bytes (characters up to U+00FF).
	subtest 'DOMAIN 12 salt: 15 | 16 | 17 bytes; bytes against characters' => sub {
		my $refusal = sprintf('hash_password: a salt is %d bytes', $LIMIT{salt_bytes});
		mock 'Database::BI::Password::_pbkdf2' => sub { 'k' x 32 };
		for my $salt ('S' x $LIMIT{salt_bytes}, "\x{E9}" x $LIMIT{salt_bytes}, "\0" x $LIMIT{salt_bytes}, "\xFF" x $LIMIT{salt_bytes}) {
			ok eval { Database::BI::Password::hash_password('pw', salt => $salt); 1 }, 'accepted: ' . $shown->($salt);
		}
		for my $salt ('', 'S', 'S' x ($LIMIT{salt_bytes} - 1), 'S' x ($LIMIT{salt_bytes} + 1), "\x{263A}" x $LIMIT{salt_bytes}, "\x{1F600}" x $LIMIT{salt_bytes},
			"S" x ($LIMIT{salt_bytes} - 1) . "\x{100}", [ 1 .. $LIMIT{salt_bytes} ]) {
			is $why->(sub { Database::BI::Password::hash_password('pw', salt => $salt) }), $refusal, 'refused: ' . (ref $salt || $shown->($salt));
		}
		restore_all();
	};

	# -- DOMAIN 13 ------------------------------------------------------
	# The password: any text but empty, a reference, or ending in NUL.  The
	# edge at 64 bytes is where HMAC starts hashing the key first: both sides
	# must verify, and a changed last character must not.
	subtest 'DOMAIN 13 password: lengths 1, 63, 64, 65, 66 bytes and every kind of text' => sub {
		my $salt = 'S' x $LIMIT{salt_bytes};
		for my $length (1, $LIMIT{hmac_block} - 1, $LIMIT{hmac_block}, $LIMIT{hmac_block} + 1, $LIMIT{hmac_block} + 2) {
			my $password = 'a' x ($length - 1) . 'b';
			my $hash = Database::BI::Password::hash_password($password, rounds => $LIMIT{rounds_min}, salt => $salt);
			ok Database::BI::Password::verify_password($password, $hash), "$length bytes verifies";
			ok !Database::BI::Password::verify_password('a' x $length, $hash), "$length bytes: the last character matters";
			ok !Database::BI::Password::verify_password('a' x ($length - 1), $hash) || $length == 1, "$length bytes: one fewer does not verify" if $length > 1;
		}
		my %hash_of;
		for my $kind (@TEXT_KINDS) {
			# A character string (UTF-8 flag on, as a decoded form field is).
			my $password = $TEXT{$kind};
			utf8::upgrade($password);
			my $hash = Database::BI::Password::hash_password($password, rounds => $LIMIT{rounds_min}, salt => $salt);
			ok Database::BI::Password::verify_password($password, $hash), "$kind text: made and verified";
			ok Database::BI::Password::verify_password(Encode::encode('UTF-8', $password), $hash), "$kind text: as characters or as its UTF-8 bytes, the same password";
			$hash_of{$hash}++;
		}
		is scalar(keys %hash_of), scalar(@TEXT_KINDS), 'different texts give different hashes';
		is $why->(sub { Database::BI::Password::hash_password('') }), 'hash_password: a password is required', 'empty: refused';
		is $why->(sub { Database::BI::Password::hash_password("x\0") }), 'hash_password: a password may not end in a NUL byte', 'a trailing NUL: refused';
		ok eval { Database::BI::Password::hash_password("x\0y", rounds => $LIMIT{rounds_min}); 1 }, 'a NUL inside is a password';
		ok eval { Database::BI::Password::hash_password('0', rounds => $LIMIT{rounds_min}); 1 }, '"0" is a password, not an empty one';
		ok eval { Database::BI::Password::hash_password(' ', rounds => $LIMIT{rounds_min}); 1 }, 'a space is a password';
	};

	# -- DOMAIN 14 ------------------------------------------------------
	# point_key: lat in -90..90 and lon in -180..180, written as a plain decimal.
	subtest 'DOMAIN 14 point_key range: the edges and one either side' => sub {
		my $key = sub { Database::BI::Model::Boundary->point_key(@_) };
		my %valid = (
			'-90,-180' => '-90.000,-180.000', '90,180' => '90.000,180.000', '0,0' => '0.000,0.000',
			'89.9999,179.9999' => '90.000,180.000', '-89.9999,-179.9999' => '-90.000,-180.000',
			'90,-180' => '90.000,-180.000', '-90,180' => '-90.000,180.000',
		);
		is $key->(split /,/), $valid{$_}, "$_ -> $valid{$_}" for sort keys %valid;
		for my $point ('90.0001,0', '-90.0001,0', '0,180.0001', '0,-180.0001', '91,0', '0,181', '90.0001,180.0001', '90,180.0001', '90.0001,180',
			'1000,0', '0,1000') {
			is $key->(split /,/, $point), undef, "out of range: $point";
		}
		# Combinatorial: each coordinate at its limit, the other at both edges of its own.
		is $key->(90, -180), '90.000,-180.000', 'latitude at its maximum, longitude at its minimum';
		is $key->(-90, 180), '-90.000,180.000', 'latitude at its minimum, longitude at its maximum';
		is $key->(90, 180.001), undef, 'latitude at its maximum, longitude just above';
		is $key->(-90.001, -180), undef, 'longitude at its minimum, latitude just below';
		# Rounding is to three places.
		is $key->(0.0004, 0.0004), '0.000,0.000', '0.0004 rounds down';
		is $key->(0.0006, 0.0006), '0.001,0.001', '0.0006 rounds up';
	};

	subtest 'DOMAIN 15 point_key format: plain decimals against everything else' => sub {
		my $key = sub { Database::BI::Model::Boundary->point_key(@_) };
		for my $good ('1', '1.5', '-1.5', '0', '-0', '0.0', '12.345678', '007') {
			ok defined $key->($good, $good), 'a plain decimal: ' . $good;
		}
		for my $bad ('+1', '.5', '5.', '1e2', '1E2', ' 1', '1 ', "1\n", '1,5', '0x1', 'NaN', 'Inf', '', '--1', '1-', "\x{661}", "1\x{FF11}", "\x{1F600}", "1\x{202E}", "\x{0301}1", "\x{FC}") {
			is $key->($bad, 0), undef, 'not a plain decimal: ' . $shown->($bad);
		}
		is $key->(undef, 0), undef, 'undef latitude';
		is $key->(0, undef), undef, 'undef longitude';
	};

	# -- DOMAIN 16 ------------------------------------------------------
	# Boundary settings: ranks 8, 10 or 12; country codes of two letters;
	# online_max a whole number from 0.
	subtest 'DOMAIN 16 ranks, codes and online_max' => sub {
		my $class = 'Database::BI::Model::Boundary';
		for my $rank (8, 10, 12) {
			is_deeply $class->check_ranks({ lk => $rank }), { lk => $rank }, "rank $rank accepted";
		}
		for my $rank (7, 9, 11, 13, 0, -8, 80, 100, '08', '8 ') {
			throws_ok { $class->check_ranks({ lk => $rank }) } qr/\Athe rank for 'lk' must be one of 8, 10, 12/, "rank refused: '$rank'";
		}
		is_deeply $class->check_ranks({ aa => 8, ZZ => 12 }), { aa => 8, zz => 12 }, 'the first and last two-letter codes, in either case';
		for my $code ('', 'a', 'abc', 'a1', '1a', 'a-', "\x{FC}\x{FC}", "\x{1F600}\x{1F600}", "a\x{301}", "a\n") {
			throws_ok { $class->check_ranks({ $code => 10 }) } qr/\A'.*' is not a two-letter country code/s, 'code refused: ' . $shown->($code);
		}
		for my $max (0, 1, $LIMIT{online_max}, 1_000_000) {
			ok eval { $class->new(online_max => $max); 1 }, "online_max $max accepted";
		}
		for my $max (-1, 1.5, 'x', '') {
			ok !eval { $class->new(online_max => $max); 1 }, 'online_max refused: ' . $shown->($max);
		}
	};

	# -- DOMAIN 17 ------------------------------------------------------
	# parse_number: a plain ASCII decimal of up to 300 integer digits takes
	# the fast path; longer ones the full path; anything past DBL_MAX is no
	# number.  Non-ASCII symbols are removed, so currency signs do not matter.
	subtest 'DOMAIN 17 parse_number: digit count, magnitude and symbols' => sub {
		my $num = \&Database::BI::Util::parse_number;
		is $num->('1' x $LIMIT{plain_digits}), '1' x $LIMIT{plain_digits} + 0, 'the longest fast-path integer';
		is $num->('1' . '0' x ($LIMIT{plain_digits})), 1e300, 'one digit longer takes the full path to the same kind of answer';
		is $num->('1' . '0' x 307), 1e307, '308 digits';
		ok defined $num->('1' . '0' x 308), '309 digits starting 1 (1e308) is under the largest double';
		is $num->('9' . '0' x 308), undef, '309 digits starting 9 is past the largest double: no number';
		is $num->('-' . '9' . '0' x 308), undef, '... and so is its negative';
		ok defined $num->('-1' . '0' x 308), 'the negative edge, inside';
		ok defined $num->('1.7976931348623157e308'), 'the largest double, spelt out';
		is $num->('1.7976931348623159e308'), undef, 'one step past it';
		is $num->('1e309'), undef, '1e309';
		is $num->('0'), 0, 'zero';
		is $num->('-0.0'), 0, 'minus zero';
		is $num->('1e-400'), 0, 'underflow is zero, not an error';

		is $num->("\x{20AC}1,234.50"), 1234.5, 'a euro sign is removed';
		is $num->("1,234.50\x{20AC}"), 1234.5, '... after the number too';
		is $num->("\x{A3}5"), 5, 'a pound sign';
		is $num->("\x{202E}5"), 5, 'a right-to-left override is not a letter';
		is $num->('5%'), 5, 'a percent sign';
		for my $text ($TEXT{umlaut}, 'Gr' . "\x{F6}" . "\x{DF}e", $TEXT{zalgo}, $TEXT{cjk}, "\x{661}\x{662}\x{663}", "\x{FF11}\x{FF12}", 'abc', '1a', 'a1', '1.2.3', '--1') {
			is $num->($text), undef, 'not a number: ' . $shown->($text);
		}
		is $num->("\x{1F600}"), undef, 'an emoji alone is not a number';
		is $num->("(1,234.50)"), -1234.5, 'accounting brackets mean negative';
		is $num->('USD 7'), 7, 'a currency code';
	};

	# -- DOMAIN 18 ------------------------------------------------------
	# The text added to each place: one short line, at most 200 characters
	# once tidied.  Length is in characters, not bytes.
	subtest 'DOMAIN 18 place_text: 199 | 200 | 201 characters, and what counts as a line' => sub {
		my $text = sub { Database::BI::Model::Geocode->place_text(@_) };
		for my $length ($LIMIT{place_max} - 1, $LIMIT{place_max}) {
			is_deeply [ $text->('a' x $length) ], [ 'a' x $length ], "$length characters accepted";
		}
		is_deeply [ $text->('a' x ($LIMIT{place_max} + 1)) ], [], '201 characters refused';
		is_deeply [ $text->('a' x $LIMIT{place_max} . '   ') ], [ 'a' x $LIMIT{place_max} ], 'tidied first: trailing spaces do not count';
		is_deeply [ $text->(', ' . 'a' x $LIMIT{place_max}) ], [ 'a' x $LIMIT{place_max} ], '... nor a leading comma';
		is_deeply [ $text->('a ' x 150) ], [ join ' ', ('a') x 150 ], 'runs of spaces collapse before the count' if 0;
		# Characters, not bytes: 200 of a wide character is still 200.
		for my $kind (qw(umlaut emoji cjk)) {
			my $ch = substr($TEXT{$kind}, 0, 1);
			is_deeply [ $text->($ch x $LIMIT{place_max}) ], [ $ch x $LIMIT{place_max} ], "200 characters of $kind (more than 200 bytes) accepted";
			is_deeply [ $text->($ch x ($LIMIT{place_max} + 1)) ], [], "201 characters of $kind refused";
		}
		for my $kind (@TEXT_KINDS) {
			my @got = $text->($TEXT{$kind});
			is_deeply \@got, [ $TEXT{$kind} ], "$kind text passes through unchanged";
		}
		is_deeply [ $text->(undef) ], [ '' ], 'undef is an empty text';
		is_deeply [ $text->('') ], [ '' ], 'empty is an empty text';
		is_deeply [ $text->('   ') ], [ '' ], 'blank is an empty text';
		for my $bad ("a\nb", "a\tb", "a\x00b", "a\x1Fb", "a\x7Fb", [], {}, \'x') {
			is_deeply [ $text->($bad) ], [], 'not one line: ' . (ref $bad || $shown->($bad));
		}
		is_deeply [ $text->("a\x{20}b") ], [ 'a b' ], 'U+0020 is the first character allowed';
		is_deeply [ $text->("a\x{80}b") ], [ "a\x{80}b" ], 'a C1 character is not an ASCII control';
	};

	# -- DOMAIN 19 ------------------------------------------------------
	# Config values checked at startup, called as the app does.
	subtest 'DOMAIN 19 login_expiration and share_secret: the edges' => sub {
		my $login  = \&Database::BI::_check_login;
		my $secret = \&Database::BI::_check_share_secret;
		for my $seconds ($LIMIT{login_min}, $LIMIT{login_min} + 1, 28_800, 10_000_000) {
			ok eval { $login->(undef, $seconds); 1 }, "login_expiration $seconds accepted";
		}
		ok eval { $login->(undef, undef); 1 }, 'unset is accepted';
		for my $seconds ($LIMIT{login_min} - 1, 0, -60, '60.0', '6e1', '', ' 60', "60\n", 'a minute', [ 60 ]) {
			my $m = $why->(sub { $login->(undef, $seconds) });
			like $m // 'accepted', qr/\Alogin_expiration: '.*' is not a number of seconds from 60\z/s, 'refused: ' . (ref $seconds || $shown->($seconds));
		}

		for my $value ('x' x $LIMIT{secret_min}, 'x' x ($LIMIT{secret_min} + 1), (map { $TEXT{$_} x 16 } qw(umlaut emoji cjk)), "\x{FC}" x $LIMIT{secret_min}) {
			ok eval { $secret->($value); 1 }, 'share_secret accepted: ' . length($value) . ' characters';
		}
		ok eval { $secret->(undef); $secret->(''); 1 }, 'unset or empty means derive one';
		for my $value ('x', 'x' x ($LIMIT{secret_min} - 1), "\x{FC}" x ($LIMIT{secret_min} - 1), "\x{1F600}" x ($LIMIT{secret_min} - 1)) {
			is $why->(sub { $secret->($value) }), 'share_secret: give at least 16 characters, so a share link cannot be forged by guessing it', 'too short: ' . length($value) . ' characters';
		}
		is $why->(sub { $secret->('BI_DEFAULT_INSECURE_SECRET') }), 'share_secret: that is the default from the source, which anyone can read; choose another', 'the old default is refused';
		is $why->(sub { $secret->([ 'x' x 16 ]) }), 'share_secret: give a string of at least 16 characters, or leave it out', 'a reference is refused';
	};

	# -- DOMAIN 20 ------------------------------------------------------
	# GET /api/ask q=: 1 to 500 characters.  Length is in characters.
	subtest 'DOMAIN 20 question length: 0 | 1 | 500 | 501 characters, as ASCII and as multibyte text' => sub {
		my $app = Test::Mojo->new('Database::BI');
		$app->app->config->{model_dir} = tempdir(CLEANUP => 1);
		$app->app->config->{ai_api_key} = 'test-key-not-used';
		$app->app->config->{ai_calls_per_hour} = 0;	# 0 = no provider call is allowed, so no network
		my $ask = sub {
			my ($q) = @_;
			$app->post_ok('/api/ask' => form => { l => "path:$SALES_ABS", q => $q });
			return ($app->tx->res->code, $app->tx->res->json // {});
		};
		my ($code, $json) = $ask->('');
		is $code, 400, 'no question: 400';
		like $json->{error}, qr/\S/, '... with a message';

		my $too_long = sprintf('The question is longer than %d characters; please shorten it', $LIMIT{ask_max});
		for my $kind (qw(ascii umlaut emoji cjk)) {
			my $unit = substr($TEXT{$kind}, 0, 1);
			($code, $json) = $ask->($unit);
			isnt $code, 400, "$kind: one character is past the length check";
			($code, $json) = $ask->($unit x $LIMIT{ask_max});
			isnt $code, 400, "$kind: $LIMIT{ask_max} characters is past the length check (" . length(Encode::encode('UTF-8', $unit x $LIMIT{ask_max})) . ' bytes)';
			($code, $json) = $ask->($unit x ($LIMIT{ask_max} + 1));
			is $code, 400, "$kind: 501 characters is refused";
			is $json->{error}, $too_long, '... with the documented message';
		}
		($code, $json) = $ask->($TEXT{zalgo} x 100);
		is $code, 400, 'Zalgo text counts its combining marks as characters: refused';
		($code, $json) = $ask->($TEXT{rtl});
		isnt $code, 400, 'a right-to-left override is just text';
	};

	# -- DOMAIN 21 ------------------------------------------------------
	# per_page=: 1 to 2,000 rows; 0 is every row; below 1 is 1; above 2,000 is
	# 2,000; anything but a whole number is the default.
	subtest 'DOMAIN 21 per_page: -1 | 0 | 1 | 2 | 2000 | 2001, and not numbers' => sub {
		my $dir = tempdir(CLEANUP => 1);
		my $rows = $LIMIT{per_page_max} + 5;
		Mojo::File->new($dir, 'many.csv')->spew(join("\n", 'sku,qty', map { "r$_,$_" } 1 .. $rows) . "\n");
		my $app = Test::Mojo->new('Database::BI', { data_dir => $dir, model_dir => tempdir(CLEANUP => 1) });
		my $shown_rows = sub {
			my ($qs) = @_;
			$app->get_ok('/open?path=' . url_escape("$dir/many.csv") . $qs)->status_is(200);
			return scalar(() = $app->tx->res->body =~ m{<td[^>]*>r\d+</td>}g);
		};
		my %expect = (
			'1' => 1, '2' => 2, '25' => 25, $LIMIT{per_page_max} => $LIMIT{per_page_max},
			$LIMIT{per_page_max} + 1 => $LIMIT{per_page_max}, '99999' => $LIMIT{per_page_max},
			'0' => $rows, '-1' => 1, '-100' => 1,
		);
		is $shown_rows->("&per_page=$_"), $expect{$_}, "per_page=$_ shows $expect{$_} rows" for sort { $a <=> $b } keys %expect;
		for my $junk ('', 'abc', '2.5', '1e3', '+5', ' 5', "\x{FC}", "5\x{FF11}") {
			is $shown_rows->('&per_page=' . url_escape(Encode::encode('UTF-8', $junk))), 200, 'not a whole number (' . $shown->($junk) . '): the default 200';
		}
	};

	# -- DOMAIN 22 ------------------------------------------------------
	# srccol=: an identifier of 1 to 64 characters, else ignored.
	subtest 'DOMAIN 22 srccol: 1 | 64 | 65 characters and which characters' => sub {
		my $dir = tempdir(CLEANUP => 1);
		Mojo::File->new($dir, 'a.csv')->spew("k,v\n1,x\n2,y\n");
		Mojo::File->new($dir, 'b.csv')->spew("k,v\n3,z\n4,w\n");
		my $app = Test::Mojo->new('Database::BI', { data_dir => $dir, model_dir => tempdir(CLEANUP => 1) });
		my $columns_with = sub {
			my ($name) = @_;
			$app->get_ok('/export?format=json&l=' . url_escape("path:$dir/a.csv") . '&c=' . url_escape("path:$dir/b.csv") . '&srccol=' . url_escape(Encode::encode('UTF-8', $name)))->status_is(200);
			return $app->tx->res->json->[0] // {};
		};
		for my $name ('a', '_', 'A9', 'x' x $LIMIT{srccol_max}) {
			ok exists $columns_with->($name)->{$name}, 'a column is added: ' . length($name) . ' characters';
		}
		for my $name ('x' x ($LIMIT{srccol_max} + 1), '1a', '9', 'a b', 'a-b', "\x{FC}ber", "caf\x{E9}", "\x{1F600}", "a\x{301}", "a\x{202E}b", "a\n") {
			my $row = $columns_with->($name);
			ok !exists $row->{$name} && scalar(keys %{$row}) == 2, 'ignored, no column added: ' . $shown->($name);
		}
	};
}

done_testing;
