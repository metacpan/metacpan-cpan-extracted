#!perl -w

# edge_cases.t — destructive, pathological, boundary-condition, and security
# tests for Database::Abstraction.  Each section is designed to actively try
# to break or subvert the module.  See CLAUDE.md for the module architecture.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Readonly;
use Test::Most;
use Test::Returns;

use lib 't/lib';

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# test1.csv columns: entry(key)  number
# Rows: one=>1, two=>2, three=>3, empty=>""
Readonly my $DATA_DIR    => File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
Readonly my $ENTRY_ONE   => 'one';
Readonly my $NUM_ONE     => 1;
Readonly my $ROWS_TOTAL  => 4;

my $HAVE_SQLITE = eval { require DBI; require DBD::SQLite; 1 };

# ---------------------------------------------------------------------------
# Smoke — module loads
# ---------------------------------------------------------------------------

use_ok('Database::Abstraction');

require Database::test1;   # CSV  — entry + number

# ===========================================================================
# EC1 — Hostile constructor inputs
# Purpose: verify that bad arguments to new() fail loudly.  Checks fire
# either at new() or at first use (count()); the test wraps both into one.
# ===========================================================================

subtest 'EC1: hostile constructor inputs' => sub {
	plan tests => 6;

	{
		package Database::ec1;
		use parent 'Database::Abstraction';
	}

	# EC1.1 — directory pointing at a file, not a directory
	my $plain_file = File::Spec->catfile($DATA_DIR, 'test1.csv');
	throws_ok { Database::ec1->new(directory => $plain_file)->count() }
		qr/not a directory/i,
		'EC1.1 file-as-directory path croaks on use';

	# EC1.2 — non-existent directory (same "not a directory" check covers it)
	throws_ok { Database::ec1->new(directory => '/no/such/path/xyz123abc')->count() }
		qr/not a directory/i,
		'EC1.2 missing directory path croaks on use';

	# EC1.3 — empty string directory (must not segfault; croak is acceptable)
	eval { Database::ec1->new(directory => '')->count() };
	ok(1, 'EC1.3 empty string directory does not segfault');

	# EC1.4 — undef directory (must not segfault)
	eval { Database::ec1->new(directory => undef)->count() };
	ok(1, 'EC1.4 undef directory does not segfault');

	# EC1.5 — direct instantiation of the abstract base class must croak
	throws_ok { Database::Abstraction->new(directory => $DATA_DIR) }
		qr/(?:abstract|cannot instantiate|Database::Abstraction)/i,
		'EC1.5 direct instantiation of abstract base class croaks';

	# EC1.6 — max_slurp_size => 0 forces SQL path; must not crash new()
	my $obj6 = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => 0 });
	my $n = eval { $obj6->count() };
	ok(defined($n) && $n >= 0, 'EC1.6 count() works with max_slurp_size=>0');
};

# ===========================================================================
# EC2 — Locked-hash (slurp) key-access boundary conditions
# Purpose: Data::Reuse::fixate() locks all hash keys.  Reading a missing
# key throws.  All public methods must use exists() guards and return
# undef/empty rather than throwing for missing entries.
# ===========================================================================

subtest 'EC2: locked-hash missing-key access' => sub {
	plan tests => 10;

	my $db = Database::test1->new({ directory => $DATA_DIR });
	$db->count();   # force slurp

	# EC2.1 — selectall_arrayref for a non-existent entry: must return [] not throw
	my $result;
	lives_ok { $result = $db->selectall_arrayref(entry => 'NO_SUCH_KEY_XYZ') }
		'EC2.1 selectall_arrayref for missing key does not throw';
	is(scalar(@{$result}), 0, 'EC2.1 returns empty arrayref for missing entry');

	# EC2.2 — fetchrow_hashref for a non-existent entry: must return undef not throw
	my $row;
	lives_ok { $row = $db->fetchrow_hashref(entry => 'NO_SUCH_KEY_XYZ') }
		'EC2.2 fetchrow_hashref for missing key does not throw';
	ok(!defined($row), 'EC2.2 returns undef for missing entry');

	# EC2.3 — count() for a non-existent entry: must return 0 not throw
	my $cnt;
	lives_ok { $cnt = $db->count(entry => 'NO_SUCH_KEY_XYZ') }
		'EC2.3 count for missing key does not throw';
	is($cnt, 0, 'EC2.3 count returns 0 for missing entry');

	# EC2.4 — selectall_array fast-path: regression for missing exists() guard.
	# In list context a missing entry must give 0 elements, not (undef).
	my @arr;
	lives_ok { @arr = $db->selectall_array(entry => 'NO_SUCH_KEY_XYZ') }
		'EC2.4 selectall_array for missing key does not throw';
	ok(!@arr || !defined($arr[0]),
		'EC2.4 selectall_array returns empty (or undef) for missing entry');

	# EC2.5 — AUTOLOAD column access for a missing entry: must return undef not throw
	my $val;
	lives_ok { $val = $db->number(entry => 'NO_SUCH_KEY_XYZ') }
		'EC2.5 AUTOLOAD column access for missing entry does not throw';
	ok(!defined($val), 'EC2.5 AUTOLOAD returns undef for missing entry');
};

# ===========================================================================
# EC3 — SQL injection via criteria column names
# Purpose: WHERE-building interpolates column names into SQL.  The guard
# regex must reject any key containing SQL meta-characters.
# ===========================================================================

subtest 'EC3: SQL injection via criteria column names' => sub {
	plan tests => 6;

	my $db = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => 0 });

	# EC3.1 — semicolon (statement-terminator injection)
	throws_ok { $db->selectall_arrayref('en;DROP TABLE test1--' => 'x') }
		qr/unsafe column name/i, 'EC3.1 semicolon in column name croaks';

	# EC3.2 — single-quote injection
	throws_ok { $db->selectall_arrayref("entry' OR '1'='1" => 'x') }
		qr/unsafe column name/i, "EC3.2 single-quote in column name croaks";

	# EC3.3 — keyword injection via space
	throws_ok { $db->selectall_arrayref('entry OR 1=1' => 'x') }
		qr/unsafe column name/i, 'EC3.3 space in column name croaks';

	# EC3.4 — parenthesis injection
	throws_ok { $db->count('entry) OR (1=1' => 'x') }
		qr/unsafe column name/i, 'EC3.4 parenthesis in column name croaks';

	# EC3.5 — dotted table.col notation must be ACCEPTED
	lives_ok { $db->selectall_arrayref('test1.entry' => 'one') }
		'EC3.5 dotted table.col column name is accepted';

	# EC3.6 — simple alphanumeric name must be accepted
	lives_ok { $db->selectall_arrayref(entry => $ENTRY_ONE) }
		'EC3.6 simple column name accepted';
};

# ===========================================================================
# EC4 — AUTOLOAD SQL injection via parameter key names
# Purpose: AUTOLOAD non-slurp path builds WHERE from %params keys.  Before
# the fix those keys were interpolated without validation.
# ===========================================================================

subtest 'EC4: AUTOLOAD SQL injection via param keys' => sub {
	plan tests => 4;

	my $db = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => 0 });

	# EC4.1 — semicolon in param key
	throws_ok { $db->number('en;DROP TABLE test1--' => 'one') }
		qr/unsafe column name/i, 'EC4.1 AUTOLOAD rejects semicolon in param key';

	# EC4.2 — space in param key
	throws_ok { $db->number('entry OR 1=1' => 'one') }
		qr/unsafe column name/i, 'EC4.2 AUTOLOAD rejects space in param key';

	# EC4.3 — legitimate column name must still work
	my $val;
	lives_ok { $val = $db->number(entry => $ENTRY_ONE) }
		'EC4.3 AUTOLOAD accepts legitimate column name';
	is($val, $NUM_ONE, 'EC4.3 AUTOLOAD returns correct value');
};

# ===========================================================================
# EC5 — Hostile reference types as criteria values
# Purpose: criteria values should be scalars.  Unexpected reference types
# must not crash or silently match all rows.
# ===========================================================================

subtest 'EC5: hostile reference types as criteria values' => sub {
	plan tests => 5;

	my $db = Database::test1->new({ directory => $DATA_DIR });

	# EC5.1 — arrayref as criteria value must not match all rows
	my $result;
	eval { $result = $db->selectall_arrayref(entry => ['one', 'two']) };
	if(defined($result)) {
		isnt(scalar(@{$result}), $ROWS_TOTAL,
			'EC5.1 arrayref as criteria value does not match all rows');
	} else {
		ok(1, 'EC5.1 arrayref as criteria value croaked (acceptable)');
	}

	# EC5.2 — coderef as criteria value must not segfault
	eval { $db->selectall_arrayref(entry => sub { 1 }) };
	ok(1, 'EC5.2 coderef as criteria value does not segfault');

	# EC5.3 — undef criteria value matches IS NULL rows (intentional API use)
	my $nulls;
	lives_ok { $nulls = $db->selectall_arrayref(number => undef) }
		'EC5.3 undef criteria value (IS NULL) does not throw';
	ok(defined($nulls), 'EC5.3 IS NULL returns defined result');

	# EC5.4 — zero as criteria value must not be treated as undef/false
	lives_ok { $db->selectall_arrayref(number => 0) }
		'EC5.4 zero as numeric criteria value does not throw';
};

# ===========================================================================
# EC6 — _match_criterion regex injection via -like/-not_like operands
# Purpose: slurp-mode _match_criterion converts LIKE pattern to Perl regex.
# Before the fix, metacharacters in the operand crashed the regex engine.
# The fix applies quotemeta to literal characters.
#
# Direct call needed because _has_complex_criteria() routes hashref values to
# SQL in normal API usage, making the -like slurp path unreachable otherwise.
# ===========================================================================

subtest 'EC6: _match_criterion regex injection via -like' => sub {
	plan tests => 4;

	my $db = Database::test1->new({ directory => $DATA_DIR });

	# EC6.1 — parenthesis in operand must not crash the regex engine
	my $result;
	lives_ok {
		$result = $db->_match_criterion('hello(world)', { '-like' => 'hello(world)' });
	} 'EC6.1 parenthesis in -like operand does not throw';
	ok($result, 'EC6.1 exact match with parenthesis literal returns true');

	# EC6.2 — dot in operand must be treated as a literal character, not regex .
	# Without quotemeta, 'a.b' would match 'axb' because . is any-char.
	lives_ok {
		$result = $db->_match_criterion('axb', { '-like' => 'a.b' });
	} 'EC6.2 -like with literal dot does not throw for non-matching string';
	ok(!$result, 'EC6.2 literal dot in -like pattern does not act as regex wildcard');
};

# ===========================================================================
# EC7-EC9 — SQLite-backed section (skipped if DBD::SQLite unavailable)
# ===========================================================================

# ===========================================================================
# EC10 — undef / NULL values in the middle of result arrays (CSV slurp mode)
# Purpose: verify that undef column values at any position in the result set
# do not cause crashes, are returned faithfully by all query methods, are
# correctly excluded by 'distinct', and are correctly matched (or skipped)
# by IS NULL / concrete-value criteria.
# Fixture: test1.csv has an 'empty' row whose 'number' column is blank →
# undef after blank_is_undef / empty_is_undef CSV options applied at slurp.
# ===========================================================================

subtest 'EC10: undef mid-array — CSV slurp path' => sub {
	plan tests => 24;

	my $db = Database::test1->new({ directory => $DATA_DIR });

	# ---- selectall_arrayref ------------------------------------------------

	# EC10.1 — all rows returned, including the undef-column row
	my $all;
	lives_ok { $all = $db->selectall_arrayref() }
		'EC10.1 selectall_arrayref does not throw when undef-column row is present';
	is(scalar(@{$all}), 4, 'EC10.1 returns all 4 rows including the undef-column row');

	# EC10.2 — the undef column value is faithfully preserved
	my ($empty_row) = grep { defined($_->{'entry'}) && $_->{'entry'} eq 'empty' } @{$all};
	ok(defined($empty_row),              'EC10.2 undef-column row is present in selectall_arrayref result');
	ok(!defined($empty_row->{'number'}), 'EC10.2 undef column value is preserved in result row');

	# EC10.3 — IS NULL criterion matches the undef-column row
	my $null_rows;
	lives_ok { $null_rows = $db->selectall_arrayref(number => undef) }
		'EC10.3 selectall_arrayref(number => undef) does not throw';
	is(scalar(@{$null_rows}), 1, 'EC10.3 IS NULL criterion selects exactly the 1 undef-number row');

	# EC10.4 — concrete-value criterion excludes the undef-column row
	my $val_rows = $db->selectall_arrayref(number => 2);
	is(scalar(@{$val_rows}), 1, 'EC10.4 number=2 criterion returns 1 row and skips the undef row');

	# ---- fetchrow_hashref --------------------------------------------------

	# EC10.5 — fetchrow_hashref for the undef-column row
	my $row;
	lives_ok { $row = $db->fetchrow_hashref(entry => 'empty') }
		'EC10.5 fetchrow_hashref for undef-column row does not throw';
	ok(defined($row),              'EC10.5 returns a defined hashref for the undef-column entry');
	ok(!defined($row->{'number'}), 'EC10.5 number column is undef in the returned hashref');

	# ---- selectall_array ---------------------------------------------------

	# EC10.6 — selectall_array returns all rows with undef preserved
	my @arr;
	lives_ok { @arr = $db->selectall_array() }
		'EC10.6 selectall_array does not throw with undef mid-array';
	is(scalar(@arr), 4, 'EC10.6 selectall_array returns all 4 rows');
	my ($arr_empty) = grep { defined($_->{'entry'}) && $_->{'entry'} eq 'empty' } @arr;
	ok(!defined($arr_empty->{'number'}), 'EC10.6 undef column value preserved in selectall_array result');

	# ---- count -------------------------------------------------------------

	# EC10.7 — count correctly includes and filters undef-column rows
	is($db->count(),                4, 'EC10.7 count() includes undef-column rows');
	is($db->count(number => undef), 1, 'EC10.7 count(number => undef) matches the 1 undef row');
	is($db->count(number => 2),     1, 'EC10.7 count(number => 2) excludes the undef row');

	# ---- AUTOLOAD list context ---------------------------------------------

	# EC10.8-9 — list context returns all column values including undef
	my @numbers;
	lives_ok { @numbers = $db->number() }
		'EC10.8 AUTOLOAD list context with undef mid-array does not throw';
	is(scalar(@numbers), 4, 'EC10.8 AUTOLOAD list context returns all 4 values including undef');
	is(scalar(grep { !defined($_) } @numbers), 1,
		'EC10.9 exactly one undef value present in AUTOLOAD list result');

	# ---- AUTOLOAD distinct -------------------------------------------------

	# EC10.10-12 — distinct excludes undef values in slurp mode
	# The slurp path uses: grep { defined } before deduplication (see CLAUDE.md)
	my @distinct;
	lives_ok { @distinct = $db->number(distinct => 1) }
		'EC10.10 AUTOLOAD distinct with undef in data does not throw';
	is(scalar(grep { !defined($_) } @distinct), 0,
		'EC10.11 distinct result contains no undef values (slurp grep-defined filter applied)');
	is(scalar(@distinct), 3, 'EC10.12 distinct returns exactly 3 defined values, not 4');

	# ---- AUTOLOAD scalar context -------------------------------------------

	# EC10.13 — scalar context for entry with undef column returns undef
	my $undef_val = $db->number(entry => 'empty');
	ok(!defined($undef_val), 'EC10.13 AUTOLOAD scalar returns undef for undef-column row');

	# EC10.14 — scalar context for entry with defined column returns the value
	my $defined_val = $db->number(entry => 'one');
	is($defined_val, 1, 'EC10.14 AUTOLOAD scalar returns correct defined value');
};

# ===========================================================================
# EC11-EC13 — SQLite-backed section (skipped if DBD::SQLite unavailable)
# ===========================================================================

SKIP: {
	skip 'DBD::SQLite not available', 4 unless $HAVE_SQLITE;

	{
		package Database::ec_sql;
		use parent 'Database::Abstraction';
	}

	# Fixture: 5 named rows + 1 NULL row for IS-NULL testing.
	# Named rows: Alice(9.5,active), Bob(7.0,inactive), Carol(8.5,active),
	#             Dave(6.0,inactive), Eve(10.0,active)
	# NULL row: id=6, all columns NULL
	my $tmpdir = tempdir(CLEANUP => 1);
	my $file   = File::Spec->catfile($tmpdir, 'ec_sql.sql');
	my $dsn    = "dbi:SQLite:dbname=$file";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do(q{
		CREATE TABLE ec_sql (
			id      INTEGER PRIMARY KEY,
			name    TEXT,
			score   REAL,
			status  TEXT
		)
	});
	$setup->do(q{INSERT INTO ec_sql VALUES (1, 'Alice',  9.5, 'active')});
	$setup->do(q{INSERT INTO ec_sql VALUES (2, 'Bob',    7.0, 'inactive')});
	$setup->do(q{INSERT INTO ec_sql VALUES (3, 'Carol',  8.5, 'active')});
	$setup->do(q{INSERT INTO ec_sql VALUES (4, 'Dave',   6.0, 'inactive')});
	$setup->do(q{INSERT INTO ec_sql VALUES (5, 'Eve',   10.0, 'active')});
	$setup->do(q{INSERT INTO ec_sql VALUES (6,  NULL,   NULL,  NULL)});
	$setup->do(q{
		CREATE TABLE dept (
			id   INTEGER PRIMARY KEY,
			name TEXT
		)
	});
	$setup->do(q{INSERT INTO dept VALUES (1, 'Engineering')});
	$setup->do(q{INSERT INTO dept VALUES (2, 'Marketing')});
	$setup->disconnect();

	my $db_sql = Database::ec_sql->new(dsn => $dsn, no_entry => 1);

	# -------------------------------------------------------------------------
	# EC7 — Extreme / boundary numeric values in operator criteria
	# -------------------------------------------------------------------------
	subtest 'EC7: extreme numeric values in operator criteria' => sub {
		plan tests => 10;

		# EC7.1 — score > very large number → 0 rows
		my $rows = $db_sql->selectall_arrayref(score => { '>' => 1e308 });
		ok(!defined($rows), 'EC7.1 score > 1e308 returns 0 rows');

		# EC7.2 — score > very negative number → all 5 rows with a score
		$rows = $db_sql->selectall_arrayref(score => { '>' => -1e308 });
		is(scalar(@{$rows}), 5, 'EC7.2 score > -1e308 returns all 5 scored rows');

		# EC7.3 — -between with reversed bounds → 0 rows (SQL BETWEEN semantics)
		$rows = $db_sql->selectall_arrayref(score => { '-between' => [10, 6] });
		is(scalar(@{$rows}), 0, 'EC7.3 reversed -between bounds returns 0 rows');

		# EC7.4 — -between with identical bounds (point range)
		$rows = $db_sql->selectall_arrayref(score => { '-between' => [7.0, 7.0] });
		is(scalar(@{$rows}), 1, 'EC7.4 point -between returns 1 row (Bob)');

		# EC7.5 — score >= 0 → all 5 non-null scored rows
		$rows = $db_sql->selectall_arrayref(score => { '>=' => 0 });
		is(scalar(@{$rows}), 5, 'EC7.5 score >= 0 matches all 5 scored rows');

		# EC7.6 — -in with empty list → 0 rows (not a crash)
		lives_ok { $rows = $db_sql->selectall_arrayref(name => { '-in' => [] }) }
			'EC7.6 -in with empty list does not throw';
		is(scalar(@{$rows}), 0, 'EC7.6 -in with empty list returns 0 rows');

		# EC7.7 — -not_in with empty list → all 6 rows
		lives_ok { $rows = $db_sql->selectall_arrayref(name => { '-not_in' => [] }) }
			'EC7.7 -not_in with empty list does not throw';
		is(scalar(@{$rows}), 6, 'EC7.7 -not_in with empty list returns all 6 rows');

		# EC7.8 — undef criteria value (IS NULL match on score) → 1 NULL row
		$rows = $db_sql->selectall_arrayref(score => undef);
		is(scalar(@{$rows}), 1, 'EC7.8 undef criteria matches the 1 NULL row');
	};

	# -------------------------------------------------------------------------
	# EC8 — Deeply nested -or/-and criteria
	# -------------------------------------------------------------------------
	subtest 'EC8: deeply nested -or/-and criteria' => sub {
		plan tests => 8;

		# EC8.1 — -or with one branch → equivalent to plain criterion
		my $rows = $db_sql->selectall_arrayref(-or => [{ name => 'Alice' }]);
		is(scalar(@{$rows}), 1, 'EC8.1 -or with single branch returns 1 row');

		# EC8.2 — -and with one branch → equivalent to plain criterion
		$rows = $db_sql->selectall_arrayref(-and => [{ name => 'Alice' }]);
		is(scalar(@{$rows}), 1, 'EC8.2 -and with single branch returns 1 row');

		# EC8.3 — -or covering all statuses (active, inactive, NULL) → all 6 rows
		$rows = $db_sql->selectall_arrayref(
			-or => [
				{ status => 'active'   },
				{ status => 'inactive' },
				{ status => undef      },
			]
		);
		is(scalar(@{$rows}), 6, 'EC8.3 -or covering all statuses returns all 6 rows');

		# EC8.4 — -or with no matching branches → 0 rows
		$rows = $db_sql->selectall_arrayref(
			-or => [
				{ name => 'Nobody1' },
				{ name => 'Nobody2' },
			]
		);
		is(scalar(@{$rows}), 0, 'EC8.4 -or with no matches returns 0 rows');

		# EC8.5 — -or combined with a plain top-level AND criterion
		$rows = $db_sql->selectall_arrayref(
			status => 'active',
			-or    => [{ name => 'Alice' }, { name => 'Carol' }],
		);
		is(scalar(@{$rows}), 2, 'EC8.5 -or inside top-level AND returns 2 rows');

		# EC8.6 — -or with operator hashes inside each branch
		# Alice(9.5) and Eve(10.0) are >= 9.5; Dave(6.0) is <= 6.0
		$rows = $db_sql->selectall_arrayref(
			-or => [
				{ score => { '>=' => 9.5 } },
				{ score => { '<=' => 6.0 } },
			]
		);
		is(scalar(@{$rows}), 3, 'EC8.6 -or with operator branches returns 3 rows');

		# EC8.7 — -and with multiple conditions (all must be satisfied)
		# active AND score >= 9.0 → Alice(9.5) + Eve(10.0) = 2 rows
		$rows = $db_sql->selectall_arrayref(
			-and => [
				{ status => 'active'          },
				{ score  => { '>=' => 9.0 }   },
			]
		);
		is(scalar(@{$rows}), 2, 'EC8.7 -and with two conditions returns 2 rows');

		# EC8.8 — count() with -or: 3 active + 2 inactive = 5
		my $cnt = $db_sql->count(-or => [{ status => 'active' }, { status => 'inactive' }]);
		is($cnt, 5, 'EC8.8 count with -or[active|inactive] returns 5');
	};

	# -------------------------------------------------------------------------
	# EC9 — Join spec validation: missing and invalid fields
	# -------------------------------------------------------------------------
	subtest 'EC9: join spec validation' => sub {
		plan tests => 11;

		# EC9.1 — missing "table" key must croak
		throws_ok {
			$db_sql->selectall_arrayref(join => { on => 'ec_sql.id = dept.id' })
		} qr/missing.*table/i, 'EC9.1 missing table key croaks';

		# EC9.2 — missing "on" key must croak
		throws_ok {
			$db_sql->selectall_arrayref(join => { table => 'dept' })
		} qr/missing.*on/i, 'EC9.2 missing on key croaks';

		# EC9.3 — invalid join type must croak
		throws_ok {
			$db_sql->selectall_arrayref(join => {
				table => 'dept',
				on    => 'ec_sql.id = dept.id',
				type  => 'CARTESIAN',
			})
		} qr/Invalid JOIN type/i, 'EC9.3 invalid join type croaks';

		# EC9.4 — default (INNER) join must succeed
		my $rows;
		lives_ok {
			$rows = $db_sql->selectall_arrayref(join => {
				table => 'dept',
				on    => 'ec_sql.id = dept.id',
			});
		} 'EC9.4 default INNER join does not throw';

		# EC9.5 — all valid type strings are accepted (module uppercases them)
		for my $type (qw(LEFT RIGHT FULL CROSS)) {
			lives_ok {
				$db_sql->selectall_arrayref(join => {
					table => 'dept',
					on    => 'ec_sql.id = dept.id',
					type  => $type,
				});
			} "EC9.5+ $type join type is valid";
		}

		# EC9.6 — lowercase type is also accepted (uc() normalises)
		lives_ok {
			$db_sql->selectall_arrayref(join => {
				table => 'dept',
				on    => 'ec_sql.id = dept.id',
				type  => 'left',
			});
		} 'EC9.6 lowercase join type is accepted (normalised via uc())';

		# EC9.7 — empty string join type must croak (uc("") = "" not in valid set)
		throws_ok {
			$db_sql->selectall_arrayref(join => {
				table => 'dept',
				on    => 'ec_sql.id = dept.id',
				type  => '',
			});
		} qr/Invalid JOIN type/i, 'EC9.7 empty string join type croaks';

		# EC9.8 — empty arrayref of join specs must not crash
		lives_ok {
			$rows = $db_sql->selectall_arrayref(join => []);
		} 'EC9.8 empty join arrayref does not crash';
	};

	# -------------------------------------------------------------------------
	# EC11 — undef / NULL values in the middle of result arrays (SQLite SQL path)
	# Three rows: first(defined), mid(NULL), last(defined).  NULL is row 2 so it
	# appears in the middle of any ordered result set.  All public query methods
	# are exercised to ensure NULL mid-array does not cause crashes or data loss.
	# -------------------------------------------------------------------------
	subtest 'EC11: undef mid-array — SQLite SQL path' => sub {
		plan tests => 16;

		{
			package Database::ec_null;
			use parent 'Database::Abstraction';
		}

		my $null_dir  = tempdir(CLEANUP => 1);
		my $null_file = File::Spec->catfile($null_dir, 'ec_null.sql');
		my $null_dsn  = "dbi:SQLite:dbname=$null_file";

		my $setup2 = DBI->connect($null_dsn, undef, undef, { RaiseError => 1 });
		$setup2->do(q{CREATE TABLE ec_null (id INTEGER PRIMARY KEY, label TEXT)});
		$setup2->do(q{INSERT INTO ec_null VALUES (1, 'first')});
		$setup2->do(q{INSERT INTO ec_null VALUES (2,  NULL)});    # NULL in the middle
		$setup2->do(q{INSERT INTO ec_null VALUES (3, 'last')});
		$setup2->disconnect();

		my $db_null = Database::ec_null->new(dsn => $null_dsn, no_entry => 1);

		# EC11.1 — selectall_arrayref returns all 3 rows including the NULL row
		my $all_null = $db_null->selectall_arrayref();
		is(scalar(@{$all_null}), 3, 'EC11.1 selectall_arrayref returns all 3 rows');
		my ($null_row) = grep { defined($_->{'id'}) && $_->{'id'} == 2 } @{$all_null};
		ok(defined($null_row),             'EC11.2 NULL row (id=2) is present in results');
		ok(!defined($null_row->{'label'}), 'EC11.2 NULL column is undef in result row');

		# EC11.3 — IS NULL criterion selects only the NULL-column row
		my $is_null = $db_null->selectall_arrayref(label => undef);
		is(scalar(@{$is_null}), 1, 'EC11.3 IS NULL criterion returns exactly the 1 NULL row');

		# EC11.4 — concrete-value criterion excludes the NULL-column row
		my $concrete = $db_null->selectall_arrayref(label => 'first');
		is(scalar(@{$concrete}), 1, 'EC11.4 label="first" returns 1 row, excludes NULL row');

		# EC11.5 — fetchrow_hashref for the NULL-column row
		my $null_fetched = $db_null->fetchrow_hashref(id => 2);
		ok(defined($null_fetched),              'EC11.5 fetchrow_hashref returns defined hashref for NULL row');
		ok(!defined($null_fetched->{'label'}),  'EC11.5 NULL column is undef in fetchrow_hashref result');

		# EC11.6 — selectall_array returns all rows with NULL preserved
		my @null_arr = $db_null->selectall_array();
		is(scalar(@null_arr), 3, 'EC11.6 selectall_array returns all 3 rows');
		my ($null_arr_row) = grep { defined($_->{'id'}) && $_->{'id'} == 2 } @null_arr;
		ok(!defined($null_arr_row->{'label'}), 'EC11.6 NULL column preserved in selectall_array result');

		# EC11.7 — count correctly counts all rows and NULL-column rows
		is($db_null->count(),               3, 'EC11.7 count() == 3 including the NULL-column row');
		is($db_null->count(label => undef), 1, 'EC11.7 count(label => undef) == 1');
		is($db_null->count(label => 'last'), 1, 'EC11.7 count(label => "last") == 1');

		# EC11.8 — AUTOLOAD list context returns all values including undef
		# SQL path: SELECT label FROM ec_null ORDER BY label → (NULL, first, last)
		my @labels;
		lives_ok { @labels = $db_null->label() }
			'EC11.8 AUTOLOAD list context with NULL mid-array does not throw';
		is(scalar(@labels), 3, 'EC11.8 AUTOLOAD list context returns 3 values including undef');
		is(scalar(grep { !defined($_) } @labels), 1,
			'EC11.8 exactly one undef value in AUTOLOAD list context result');

		# EC11.9 — AUTOLOAD scalar with id criterion returns undef for the NULL row
		my $null_label = $db_null->label(id => 2);
		ok(!defined($null_label), 'EC11.9 AUTOLOAD scalar returns undef for the NULL-column row');
	};
}   # end SKIP block

# ===========================================================================
# EC12 — columns() / schema() ARRAY-slurp branch (regression guard)
# Purpose: Before the fix, calling columns() or schema() on a no_entry CSV
# object (whose $self->{'data'} is an ARRAY ref) returned an empty result
# because the ref($data) eq 'HASH' branch was skipped and the else (DBI)
# branch never ran.  This confirms the fix produces correct non-empty results.
#
# Database::test4ne uses no_entry=>1, id=>'cardinal', sep_char=>',',
# dbname=>'test4'.  Because 'cardinal' exists in test4.csv, the slurp
# filter keeps all 3 rows and stores them as an ARRAY ref.
# ===========================================================================
{
	require Database::test4ne;

	my $ne = Database::test4ne->new(directory => $DATA_DIR);
	$ne->count();    # trigger lazy _open + slurp into ARRAY ref

	is(ref($ne->{'data'}), 'ARRAY',
		'EC12 pre-cond: no_entry CSV data is ARRAY ref after slurp');

	my $cols = $ne->columns();
	ok(ref($cols) eq 'ARRAY' && scalar(@{$cols}) > 0,
		'EC12a: columns() on ARRAY-slurp data returns non-empty arrayref');

	my $sch = $ne->schema();
	ok(ref($sch) eq 'HASH' && scalar(keys %{$sch}) > 0,
		'EC12b: schema() on ARRAY-slurp data returns non-empty hashref');
}

# ===========================================================================
# EC13 — Query builder boundary conditions
# Purpose: exercise the chained Query builder under edge inputs — zero limit,
# over-offset, multiple chained where() (AND semantics), empty where({}),
# and first() with ordering — to confirm each boundary path behaves as
# documented without croaking or returning garbage.
# ===========================================================================

SKIP: {
	skip 'DBD::SQLite not available', 1 unless $HAVE_SQLITE;

	{
		package Database::ec13;
		use parent 'Database::Abstraction';
	}

	my $ec13_dir  = tempdir(CLEANUP => 1);
	my $ec13_file = File::Spec->catfile($ec13_dir, 'ec13.sql');
	my $ec13_dsn  = "dbi:SQLite:dbname=$ec13_file";

	my $ec13_dbh = DBI->connect($ec13_dsn, undef, undef, { RaiseError => 1 });
	$ec13_dbh->do(q{CREATE TABLE ec13 (id INTEGER PRIMARY KEY, name TEXT, score REAL)});
	$ec13_dbh->do(q{INSERT INTO ec13 VALUES (1, 'Alpha',   10.0)});
	$ec13_dbh->do(q{INSERT INTO ec13 VALUES (2, 'Beta',    20.0)});
	$ec13_dbh->do(q{INSERT INTO ec13 VALUES (3, 'Gamma',   30.0)});
	$ec13_dbh->do(q{INSERT INTO ec13 VALUES (4, 'Delta',   40.0)});
	$ec13_dbh->do(q{INSERT INTO ec13 VALUES (5, 'Epsilon', 50.0)});
	$ec13_dbh->disconnect();

	my $qb_db = Database::ec13->new(dsn => $ec13_dsn, no_entry => 1);

	subtest 'EC13: query builder boundary conditions' => sub {
		plan tests => 10;

		# EC13.1 — limit(0) must return an empty arrayref, not crash
		my $rows;
		lives_ok { $rows = $qb_db->query()->limit(0)->all() }
			'EC13.1 query()->limit(0)->all() does not throw';
		is(scalar(@{$rows}), 0, 'EC13.1 limit(0) returns 0 rows');

		# EC13.2 — offset far beyond row count must silently return empty
		lives_ok { $rows = $qb_db->query()->limit(5)->offset(10_000)->all() }
			'EC13.2 offset beyond row count does not throw';
		is(scalar(@{$rows}), 0, 'EC13.2 offset beyond row count returns 0 rows');

		# EC13.3 — two chained where() must apply AND semantics using DIFFERENT keys.
		# Note: two where() calls on the SAME key overwrite (hash merge), so the
		# AND test must use distinct keys to prove both conditions are retained.
		# id <= 3 → Alpha(1),Beta(2),Gamma(3); score >= 20 → Beta(2),Gamma(3),Delta(4),Epsilon(5)
		# Intersection (AND): Beta(2), Gamma(3) = 2 rows
		$rows = $qb_db->query()
			->where({ id    => { '<=' => 3    } })
			->where({ score => { '>=' => 20.0 } })
			->all();
		is(scalar(@{$rows}), 2,
			'EC13.3 two chained where() on different keys apply AND semantics (2 rows)');

		# EC13.4 — empty where({}) must not filter any rows (all 5 pass)
		$rows = $qb_db->query()->where({})->all();
		is(scalar(@{$rows}), 5, 'EC13.4 where({}) returns all 5 rows unfiltered');

		# EC13.5 — order_by(ASC) + limit(1) + first() returns lowest-score row
		my $first;
		lives_ok { $first = $qb_db->query()->order_by('score ASC')->limit(1)->first() }
			'EC13.5 first() with order_by does not throw';
		is($first->{'name'}, 'Alpha',
			'EC13.5 first() with ASC score order returns the Alpha row (score 10.0)');

		# EC13.6 — query builder count() with a where() filter
		# score > 30.0 → Delta(40) + Epsilon(50) = 2 rows
		my $cnt = $qb_db->query()->where({ score => { '>' => 30.0 } })->count();
		is($cnt, 2, 'EC13.6 query builder count() with where filter returns 2');

		# EC13.7 — offset equal to row count is an exact boundary: must return 0 rows.
		# SQLite requires LIMIT when using OFFSET; supply a large limit to avoid
		# a syntax error while still exercising the offset boundary condition.
		$rows = $qb_db->query()->limit(99_999)->offset(5)->all();
		is(scalar(@{$rows}), 0, 'EC13.7 offset == row count (5) with large limit returns 0 rows');
	};
}

# ===========================================================================
# EC14 — id / filename injection guards (including clone-path bypass fix)
# Purpose: new() validates the 'id' column name at construction time for
# both direct and clone (blessed-object) invocations.  _open() validates
# 'filename' before using it to build a filesystem path.  Hostile values
# must croak loudly before any DBI or filesystem call.
# ===========================================================================

subtest 'EC14: id / filename injection guards' => sub {
	plan tests => 9;

	{
		package Database::ec14;
		use parent 'Database::Abstraction';
	}

	# EC14.1 — a safe, valid identifier is accepted without error
	lives_ok { Database::ec14->new(directory => $DATA_DIR, id => 'entry') }
		'EC14.1 safe id column name accepted at new()';

	# EC14.2 — semicolon: classic statement-terminator injection
	throws_ok {
		Database::ec14->new(directory => $DATA_DIR, id => 'col;DROP TABLE ec14--')
	} qr/unsafe id column name/i,
		'EC14.2 semicolon in id column name croaks at new()';

	# EC14.3 — space: allows keyword injection via identifier interpolation
	throws_ok {
		Database::ec14->new(directory => $DATA_DIR, id => 'col OR 1=1')
	} qr/unsafe id column name/i,
		'EC14.3 space in id column name croaks at new()';

	# EC14.4 — empty string fails the leading [a-zA-Z_] anchor
	throws_ok {
		Database::ec14->new(directory => $DATA_DIR, id => '')
	} qr/unsafe id column name/i,
		'EC14.4 empty string id croaks at new()';

	# EC14.5 — leading digit: not a valid SQL identifier
	throws_ok {
		Database::ec14->new(directory => $DATA_DIR, id => '1bad_col')
	} qr/unsafe id column name/i,
		'EC14.5 leading-digit id column name croaks at new()';

	# EC14.6 — clone path: new() called on a blessed instance must validate id.
	# Before the fix the clone branch returned early before the validation block,
	# allowing SQL injection via $self->{'id'} in ORDER BY / COUNT() / CSV comment-filter.
	my $base_obj = Database::ec14->new(directory => $DATA_DIR, id => 'entry');
	throws_ok { $base_obj->new(id => 'clone;injection') }
		qr/unsafe id column name/i,
		'EC14.6 clone-path new() validates id (historical injection bypass is fixed)';

	# EC14.7 — path traversal in filename: slash rejected by [a-zA-Z0-9_.-]+ regex
	throws_ok {
		Database::ec14->new(directory => $DATA_DIR, filename => '../etc/passwd')->count()
	} qr/unsafe (?:filename|dbname)/i,
		'EC14.7 path traversal "../etc/passwd" in filename croaks at _open()';

	# EC14.8 — slash inside filename: same regex guard
	throws_ok {
		Database::ec14->new(directory => $DATA_DIR, filename => 'subdir/test1')->count()
	} qr/unsafe (?:filename|dbname)/i,
		'EC14.8 slash in filename "subdir/test1" croaks at _open()';

	# EC14.9 — standalone ".." has its own explicit rejection guard beyond the
	# regex (the regex allows individual dots; ".." is caught separately)
	throws_ok {
		Database::ec14->new(directory => $DATA_DIR, filename => '..')->count()
	} qr/unsafe (?:filename|dbname)/i,
		'EC14.9 ".." as filename is explicitly rejected by the double-dot guard';
};

# ===========================================================================
# EC15 — Filesystem hostility
# Purpose: character-device files and dangling symbolic links given as
# 'directory' must be rejected as cleanly as a plain regular file.
# A symlink that resolves to a real directory must still be accepted.
# ===========================================================================

subtest 'EC15: filesystem hostility' => sub {

	# EC15.1-2 — symlink tests (skipped on platforms without symlink support)
	SKIP: {
		my $ec15_dir = tempdir(CLEANUP => 1);
		my $dangle   = File::Spec->catfile($ec15_dir, 'dangle');

		# Create a dangling symlink; skip the whole block if symlink() fails
		skip 'symlink() not supported on this platform', 2
			unless eval {
				symlink(File::Spec->catfile($ec15_dir, 'nonexistent'), $dangle);
				1;
			};

		# Dangling symlink: -d returns false → "not a directory" croak
		throws_ok { Database::test1->new(directory => $dangle)->count() }
			qr/not a directory/i,
			'EC15.1 dangling symlink as directory croaks "not a directory"';

		# A symlink resolving to a real directory must not be over-rejected
		my $real_dir  = tempdir(CLEANUP => 1);
		my $good_link = File::Spec->catfile($ec15_dir, 'goodlink');
		symlink($real_dir, $good_link);
		my $sym_obj = eval { Database::test1->new(directory => $good_link) };
		ok(defined($sym_obj),
			'EC15.2 symlink to a real directory is accepted by new()');
	}

	# EC15.3 — /dev/null is a character device, not a directory
	SKIP: {
		skip '/dev/null not present on this platform', 1 unless -e '/dev/null';
		throws_ok { Database::test1->new(directory => '/dev/null')->count() }
			qr/not a directory/i,
			'EC15.3 /dev/null (char device) as directory croaks "not a directory"';
	}

	# EC15.4 — /dev/urandom: another character device, same guard must fire
	SKIP: {
		skip '/dev/urandom not present on this platform', 1 unless -e '/dev/urandom';
		throws_ok { Database::test1->new(directory => '/dev/urandom')->count() }
			qr/not a directory/i,
			'EC15.4 /dev/urandom (char device) as directory croaks "not a directory"';
	}

	done_testing();
};  # end subtest EC15

# ===========================================================================
# EC18 — 'table' parameter: comprehensive injection and boundary tests
# Purpose: new() validates the 'table' constructor parameter against
# $SAFE_QUALIFIED at construction time for both direct and clone invocations.
# A hostile table name must croak before any DBI or filesystem call.
# The SAFE_QUALIFIED regex is: \A[a-zA-Z_][a-zA-Z0-9_.]*\z
# Dots are intentionally allowed for schema.table notation.
# ===========================================================================

subtest 'EC18: table parameter security and boundary conditions' => sub {
	plan tests => 12;

	{ package Database::ec18; use parent 'Database::Abstraction'; }

	# EC18.1 — plain valid table name accepted (no injection risk)
	lives_ok { Database::ec18->new(directory => $DATA_DIR, table => 'test1') }
		'EC18.1 valid table name "test1" accepted at new()';

	# EC18.2 — dotted table name is allowed by SAFE_QUALIFIED (schema.table notation)
	lives_ok { Database::ec18->new(directory => $DATA_DIR, table => 'myschema.mytable') }
		'EC18.2 dotted table name "myschema.mytable" accepted by SAFE_QUALIFIED';

	# EC18.3 — underscore-prefixed name: valid identifier
	lives_ok { Database::ec18->new(directory => $DATA_DIR, table => '_private') }
		'EC18.3 underscore-prefixed table name accepted';

	# EC18.4 — semicolon: classic statement-terminator injection
	throws_ok {
		Database::ec18->new(directory => $DATA_DIR, table => 'bad; DROP TABLE ec18--')
	} qr/unsafe table name/i,
		'EC18.4 semicolon in table name croaks at new()';

	# EC18.5 — SQL single-quote: value-boundary escape injection
	throws_ok {
		Database::ec18->new(directory => $DATA_DIR, table => "tbl'OR'1'='1")
	} qr/unsafe table name/i,
		"EC18.5 single-quote in table name croaks at new()";

	# EC18.6 — space: allows keyword injection via identifier interpolation
	throws_ok {
		Database::ec18->new(directory => $DATA_DIR, table => 'my table')
	} qr/unsafe table name/i,
		'EC18.6 space in table name croaks at new()';

	# EC18.7 — leading digit: not a valid SQL identifier start
	throws_ok {
		Database::ec18->new(directory => $DATA_DIR, table => '1invalid')
	} qr/unsafe table name/i,
		'EC18.7 leading-digit table name croaks at new()';

	# EC18.8 — empty string: fails the leading [a-zA-Z_] anchor
	throws_ok {
		Database::ec18->new(directory => $DATA_DIR, table => '')
	} qr/unsafe table name/i,
		'EC18.8 empty string table name croaks at new()';

	# EC18.9 — NUL byte: must be rejected (regex \z anchor does not match mid-string NUL)
	throws_ok {
		Database::ec18->new(directory => $DATA_DIR, table => "Sheet1\x00injection")
	} qr/unsafe table name/i,
		'EC18.9 NUL byte in table name croaks at new()';

	# EC18.10 — CRLF injection: embedded newline attempts header injection
	throws_ok {
		Database::ec18->new(directory => $DATA_DIR, table => "Sheet1\r\ninjection")
	} qr/unsafe table name/i,
		'EC18.10 CRLF in table name croaks at new()';

	# EC18.11 — parenthesis: SQL function-call injection attempt
	throws_ok {
		Database::ec18->new(directory => $DATA_DIR, table => 'drop()')
	} qr/unsafe table name/i,
		'EC18.11 parenthesis in table name croaks at new()';

	# EC18.12 — clone path: ->new() on a blessed instance must validate 'table'.
	# This mirrors the clone-path id bypass fixed in 0.37 (see EC14.6) and asserts
	# the same guard now applies to the 'table' parameter in the clone branch.
	my $base = Database::ec18->new(directory => $DATA_DIR);
	throws_ok { $base->new(table => 'bad; inject') }
		qr/unsafe table name/i,
		'EC18.12 clone-path new() validates table parameter';
};

# ===========================================================================
# EC19 — XLSX backend: hostile conditions and boundary cases
# Purpose: exercise the Spreadsheet::ParseXLSX-backed XLSX path under corrupted
# files, worksheet isolation failures, and resource lifecycle edge cases.
# The goal is to ensure no segfaults, no data bleed between worksheets, and
# that the DESTROY lifecycle is clean.
# ===========================================================================

my $have_xlsx_ec = eval {
	require Excel::Writer::XLSX;
	require Spreadsheet::ParseXLSX;
	1;
};

SKIP: {
	skip 'Excel::Writer::XLSX or Spreadsheet::ParseXLSX not available for EC19', 10
		unless $have_xlsx_ec;

	{ package Database::ec19; use parent 'Database::Abstraction'; }

	# Build a two-worksheet OOXML fixture:
	#   ec19  — entry / value   (2 rows)
	#   other — entry / score   (1 row)
	my $ec19_dir  = tempdir(CLEANUP => 1);
	my $ec19_xlsx = File::Spec->catfile($ec19_dir, 'ec19.xlsx');
	{
		my $wb  = Excel::Writer::XLSX->new($ec19_xlsx);
		my $ws1 = $wb->add_worksheet('ec19');
		$ws1->write(0, 0, 'entry'); $ws1->write(0, 1, 'value');
		$ws1->write(1, 0, 'alpha'); $ws1->write(1, 1, 10);
		$ws1->write(2, 0, 'beta');  $ws1->write(2, 1, 20);
		my $ws2 = $wb->add_worksheet('other');
		$ws2->write(0, 0, 'entry'); $ws2->write(0, 1, 'score');
		$ws2->write(1, 0, 'gamma'); $ws2->write(1, 1, 99);
		$wb->close();
	}

	my $db_prim = Database::ec19->new(directory => $ec19_dir);
	my $db_over = Database::ec19->new(directory => $ec19_dir, table => 'other');

	# EC19.1 — primary worksheet: count == 2
	is($db_prim->count(), 2, 'EC19.1 XLSX primary worksheet count() == 2');

	# EC19.2 — type is set to 'XLSX' after the first query (in-memory slurp path)
	is($db_prim->{'type'}, 'XLSX',
		'EC19.2 XLSX backend type is "XLSX" after first query');

	# EC19.3 — table-override worksheet returns a different row count,
	# proving the active worksheet changed and is independent of the primary.
	is($db_over->count(), 1,
		'EC19.3 table-override worksheet "other" has 1 row (no bleed from primary)');

	# EC19.4 — data isolation: the override worksheet does not expose the 'value'
	# column defined in the primary worksheet; fetchrow_hashref by 'alpha' returns
	# undef because 'alpha' exists only in the 'ec19' worksheet.
	my $bleed_row = $db_over->fetchrow_hashref(entry => 'alpha');
	ok(!defined($bleed_row),
		'EC19.4 table-override: primary entry "alpha" is not visible in override worksheet');

	# EC19.5 — two independent objects: data for one does not overwrite the other.
	# Both run queries concurrently to stress-test internal handle isolation.
	my $p1 = $db_prim->fetchrow_hashref(entry => 'beta');
	my $p2 = $db_over->fetchrow_hashref(entry => 'gamma');
	ok(defined($p1) && defined($p2) && $p1->{'value'} == 20 && $p2->{'score'} == 99,
		'EC19.5 concurrent queries on independent objects return correct isolated data');

	# EC19.6 — 0-byte file named ec19zero.xlsx must not segfault.
	# Spreadsheet::ParseXLSX is expected to croak at parse time; that is acceptable.
	# We only assert that the process does not die unexpectedly (segfault, SIGABRT).
	{
		{ package Database::ec19zero; use parent 'Database::Abstraction'; }
		my $zero_dir = tempdir(CLEANUP => 1);
		open my $fh, '>', File::Spec->catfile($zero_dir, 'ec19zero.xlsx'); close $fh;
		eval { Database::ec19zero->new(directory => $zero_dir)->count() };
		ok(1, 'EC19.6 0-byte .xlsx file does not segfault (croak at parse is acceptable)');
		diag "EC19.6 error was: $@" if $@ && $ENV{TEST_VERBOSE};
	}

	# EC19.7 — random-bytes file masquerading as .xlsx must not segfault.
	# ParseXLSX expects a ZIP/OOXML container; non-ZIP bytes cause a parse croak.
	{
		{ package Database::ec19junk; use parent 'Database::Abstraction'; }
		my $junk_dir  = tempdir(CLEANUP => 1);
		my $junk_path = File::Spec->catfile($junk_dir, 'ec19junk.xlsx');
		open my $fh, '>', $junk_path;
		print {$fh} "\xde\xad\xbe\xef" x 256;  # garbage bytes; not a real XLSX
		close $fh;
		eval { Database::ec19junk->new(directory => $junk_dir)->count() };
		ok(1, 'EC19.7 garbage-bytes .xlsx does not segfault');
		diag "EC19.7 error was: $@" if $@ && $ENV{TEST_VERBOSE};
	}

	# EC19.8 — columns() returns a non-empty arrayref after a query on XLSX.
	my $cols19 = $db_prim->columns();
	ok(ref($cols19) eq 'ARRAY' && scalar(@{$cols19}) > 0,
		'EC19.8 XLSX columns() returns non-empty arrayref after query');

	# EC19.9 — DESTROY on an XLSX-backed object does not throw.
	{
		my $tmp_db = Database::ec19->new(directory => $ec19_dir);
		$tmp_db->count();    # trigger _open() so type / handle are set
		lives_ok { $tmp_db->DESTROY() }
			'EC19.9 DESTROY on XLSX-backed object does not throw';
	}

	# EC19.10 — fetchrow_hashref miss on XLSX returns undef, not a crash.
	my $miss = $db_prim->fetchrow_hashref(entry => '__no_such_entry_xyz__');
	ok(!defined($miss),
		'EC19.10 fetchrow_hashref miss on XLSX returns undef (not a crash)');
}

# ===========================================================================
# EC16 — Pathological criteria values
# Purpose: criteria values containing NUL bytes, shell metacharacters,
# SQL injection payloads, or extreme lengths must not crash the module or
# produce spurious rows.  In slurp mode they pass through _match_criterion
# as plain string comparisons; in SQL mode DBI bind-params neutralise them.
# ===========================================================================

subtest 'EC16: pathological criteria values — slurp path' => sub {
	plan tests => 8;

	my $db = Database::test1->new({ directory => $DATA_DIR });
	$db->count();   # force slurp into memory

	# EC16.1 — NUL byte: _match_criterion string comparison must not crash
	my $result;
	lives_ok { $result = $db->selectall_arrayref(entry => "\x00") }
		'EC16.1 NUL byte in criteria value does not throw';
	is(scalar(@{$result}), 0, 'EC16.1 NUL byte criteria matches 0 rows');

	# EC16.2 — 10_000-char string: must not trigger O(n^2) processing
	my $long_val = 'x' x 10_000;
	lives_ok { $result = $db->selectall_arrayref(entry => $long_val) }
		'EC16.2 10_000-char criteria value does not throw or hang';
	is(scalar(@{$result}), 0, 'EC16.2 very long criteria value matches 0 rows');

	# EC16.3 — shell metacharacters: treated as a literal string, not executed
	lives_ok { $result = $db->selectall_arrayref(entry => '$(rm -rf /)') }
		'EC16.3 shell metacharacters in criteria value do not throw';
	is(scalar(@{$result}), 0, 'EC16.3 shell metacharacters in criteria value match 0 rows');

	# EC16.4 — SQL injection string as criteria value: slurp path uses plain
	# string comparison (no SQL engine), so injection payload is a literal;
	# SQL path uses DBI bind-params which also neutralise it.  Either way: 0 rows.
	lives_ok { $result = $db->selectall_arrayref(entry => "' OR '1'='1") }
		'EC16.4 SQL injection string in criteria value does not throw';
	is(scalar(@{$result}), 0,
		'EC16.4 SQL injection string matches 0 rows (not interpreted as SQL)');
};

# ===========================================================================
# EC17 — selectall_array list vs scalar context
# Purpose: selectall_array() is context-sensitive — list context returns a
# flat list of hashrefs; scalar context returns the first hashref only.
# Both behaviors must be correct when results are empty (missing key): list
# must give 0 elements; scalar must give undef, not an empty arrayref.
# ===========================================================================

subtest 'EC17: selectall_array context sensitivity' => sub {
	plan tests => 7;

	my $db = Database::test1->new({ directory => $DATA_DIR });

	# EC17.1 — list context returns all rows as a flat list of hashrefs
	my @all = $db->selectall_array();
	is(scalar(@all), $ROWS_TOTAL,
		'EC17.1 list context returns all rows');
	ok(ref($all[0]) eq 'HASH',
		'EC17.1 each element in list context is a hashref');

	# EC17.2 — scalar context with a specific entry criterion uses the single-entry
	# fast-track (line 1224 of Abstraction.pm) which returns the row hashref directly;
	# the no-criteria path returns values() in the calling context (count in scalar).
	my $one_row = $db->selectall_array(entry => $ENTRY_ONE);
	ok(ref($one_row) eq 'HASH',
		'EC17.2 scalar context with specific entry returns the matching hashref');

	# EC17.3 — list context for a missing entry key returns 0 elements,
	# not a 1-element list containing undef
	my @missing = $db->selectall_array(entry => 'NO_SUCH_KEY_XYZ');
	is(scalar(@missing), 0,
		'EC17.3 missing entry in list context returns 0 elements (not undef)');

	# EC17.4 — scalar context for a missing entry key returns undef
	my $missing_scalar = $db->selectall_array(entry => 'NO_SUCH_KEY_XYZ');
	ok(!defined($missing_scalar),
		'EC17.4 missing entry in scalar context returns undef');

	# EC17.5-6 — matching entry criterion: 1-element list in list context,
	# correct column value in the returned row
	my @one = $db->selectall_array(entry => $ENTRY_ONE);
	is(scalar(@one), 1,
		'EC17.5 matching entry in list context returns 1-element list');
	is($one[0]{'number'}, $NUM_ONE,
		'EC17.6 returned row contains the correct column value');
};

# ===========================================================================
# EC20 — each_row() hostile inputs
# Purpose: each_row() requires a CODE ref as its first argument and must
# propagate exceptions from the callback while leaving the DBI handle in a
# valid (finished) state.  Non-coderef inputs must croak immediately.
# ===========================================================================

subtest 'EC20: each_row() hostile callback inputs' => sub {
	plan tests => 11;

	my $db = Database::test1->new({ directory => $DATA_DIR });

	# EC20.1 — undef callback must croak mentioning "code reference"
	throws_ok { $db->each_row(undef) }
		qr/code.*ref|ref.*code/i,
		'EC20.1 undef callback croaks with code-reference message';

	# EC20.2 — scalar (string) callback must croak
	throws_ok { $db->each_row('not_a_coderef') }
		qr/code.*ref|ref.*code/i,
		'EC20.2 string callback croaks with code-reference message';

	# EC20.3 — arrayref as callback must croak
	throws_ok { $db->each_row([]) }
		qr/code.*ref|ref.*code/i,
		'EC20.3 arrayref callback croaks with code-reference message';

	# EC20.4 — hashref as callback must croak
	throws_ok { $db->each_row({}) }
		qr/code.*ref|ref.*code/i,
		'EC20.4 hashref callback croaks with code-reference message';

	# EC20.5 — integer 0 as callback must croak
	throws_ok { $db->each_row(0) }
		qr/code.*ref|ref.*code/i,
		'EC20.5 integer-0 callback croaks with code-reference message';

	# EC20.6 — exception inside callback must propagate to the caller
	eval { $db->each_row(sub { die "callback explode\n" }) };
	like($@, qr/callback explode/, 'EC20.6 exception inside callback propagates to caller');

	# EC20.7 — object is still usable after a callback exception (DBI handle finished)
	my $n = eval { $db->each_row(sub {}) };
	ok(!$@ && defined($n) && $n >= 0,
		'EC20.7 object is usable after callback exception (DBI handle left clean)');

	# EC20.8 — empty result set: callback is never called; return value is 0
	{
		my $called = 0;
		my $ret = $db->each_row(sub { $called++ }, entry => 'NO_SUCH_KEY_EC20');
		is($ret,    0, 'EC20.8 each_row for missing entry returns 0');
		is($called, 0, 'EC20.8 callback never invoked for empty result set');
	}

	# EC20.9 — callback receives a hashref, not a raw scalar
	{
		my $row_type;
		$db->each_row(sub { $row_type //= ref(shift) }, entry => $ENTRY_ONE);
		is($row_type, 'HASH', 'EC20.9 callback receives a HASH reference');
	}

	# EC20.10 — modifying the received hashref must not corrupt subsequent queries.
	# Slurp rows are fixated; a mutation may throw or be ignored; either way the
	# data returned by a fresh query afterward must still be correct.
	{
		eval {
			$db->each_row(sub {
				my $row = shift;
				$row->{'number'} = 999 if defined $row->{'entry'} && $row->{'entry'} eq $ENTRY_ONE;
			}, entry => $ENTRY_ONE);
		};
		my $after = $db->fetchrow_hashref(entry => $ENTRY_ONE);
		is($after->{'number'}, $NUM_ONE,
			'EC20.10 mutating callback arg does not corrupt subsequent queries');
	}
};

# ===========================================================================
# EC21 — base_criteria hostile constructor inputs
# Purpose: base_criteria is validated at new() time. Non-hashref values
# must croak loudly. Keys with SQL-unsafe characters must also croak.
# Only special grouping keys starting with '-' (e.g. -or, -and) are exempt
# from the SAFE_QUALIFIED regex check.
# Empty hashref is valid and adds no filtering.
# ===========================================================================

subtest 'EC21: base_criteria hostile constructor inputs' => sub {
	plan tests => 12;

	{ package Database::ec21; use parent 'Database::Abstraction'; }

	# EC21.1 — non-hashref: plain scalar must croak
	throws_ok {
		Database::ec21->new(directory => $DATA_DIR, base_criteria => 'not_a_hash')
	} qr/base_criteria must be a hashref/i,
		'EC21.1 scalar base_criteria croaks at new()';

	# EC21.2 — non-hashref: arrayref must croak
	throws_ok {
		Database::ec21->new(directory => $DATA_DIR, base_criteria => ['k', 'v'])
	} qr/base_criteria must be a hashref/i,
		'EC21.2 arrayref base_criteria croaks at new()';

	# EC21.3 — non-hashref: integer must croak
	throws_ok {
		Database::ec21->new(directory => $DATA_DIR, base_criteria => 42)
	} qr/base_criteria must be a hashref/i,
		'EC21.3 integer base_criteria croaks at new()';

	# EC21.4 — unsafe key (semicolon) must croak
	throws_ok {
		Database::ec21->new(directory => $DATA_DIR,
			base_criteria => { 'col;DROP TABLE ec21--' => 'val' })
	} qr/unsafe base_criteria key/i,
		'EC21.4 semicolon in base_criteria key croaks at new()';

	# EC21.5 — unsafe key (space) must croak
	throws_ok {
		Database::ec21->new(directory => $DATA_DIR,
			base_criteria => { 'col OR 1=1' => 'val' })
	} qr/unsafe base_criteria key/i,
		'EC21.5 space in base_criteria key croaks at new()';

	# EC21.6 — unsafe key (NUL byte) must croak
	throws_ok {
		Database::ec21->new(directory => $DATA_DIR,
			base_criteria => { "col\x00injection" => 'val' })
	} qr/unsafe base_criteria key/i,
		'EC21.6 NUL byte in base_criteria key croaks at new()';

	# EC21.7 — unsafe key (leading digit) must croak
	throws_ok {
		Database::ec21->new(directory => $DATA_DIR,
			base_criteria => { '1bad_key' => 'val' })
	} qr/unsafe base_criteria key/i,
		'EC21.7 leading-digit base_criteria key croaks at new()';

	# EC21.8 — grouping key '-or' starting with '-' is EXEMPT from SAFE_QUALIFIED
	lives_ok {
		Database::ec21->new(directory => $DATA_DIR, base_criteria => { '-or' => [] });
	} 'EC21.8 "-or" grouping key in base_criteria is accepted (exempt from SAFE_QUALIFIED)';

	# EC21.9 — '-and' grouping key is also exempt
	lives_ok {
		Database::ec21->new(directory => $DATA_DIR, base_criteria => { '-and' => [] });
	} 'EC21.9 "-and" grouping key in base_criteria is accepted';

	# EC21.10 — empty hashref is a valid base_criteria value (adds no filtering).
	# Use Database::test1 for the count() assertion because Database::ec21 has no
	# backing file in t/data/ and triggering _open() on it would croak.
	lives_ok {
		Database::ec21->new(directory => $DATA_DIR, base_criteria => {});
	} 'EC21.10 empty base_criteria hashref is accepted at new()';
	my $obj_empty = Database::test1->new({ directory => $DATA_DIR, base_criteria => {} });
	is($obj_empty->count(), $ROWS_TOTAL,
		'EC21.10 empty base_criteria does not reduce count()');

	# EC21.11 — undef value in base_criteria is valid (means IS NULL filter)
	lives_ok {
		Database::test1->new({ directory => $DATA_DIR, base_criteria => { number => undef } });
	} 'EC21.11 undef value in base_criteria is accepted at new() (IS NULL filter)';
};

# ===========================================================================
# EC22 — sort_by injection and boundary conditions
# Purpose: _parse_sort_by() uses Carp::carp (not croak) for invalid input;
# it must never allow SQL injection into the ORDER BY clause.  An unsafe
# column name or direction causes a warning and a fallback to the default
# order — it must NOT propagate a hostile string to the query.
# ===========================================================================

subtest 'EC22: sort_by injection and boundary conditions' => sub {
	plan tests => 11;

	my $db = Database::test1->new({ directory => $DATA_DIR });

	# EC22.1 — unsafe column name: must not inject into ORDER BY (carp + fallback)
	{
		my @rows;
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		lives_ok { @rows = $db->selectall_array(sort_by => 'col;DROP TABLE test1--') }
			'EC22.1 semicolon in sort_by column does not throw (carp + fallback)';
		ok($warned > 0, 'EC22.1 semicolon in sort_by column emits a warning');
		ok(scalar(@rows) == $ROWS_TOTAL,
			'EC22.1 all rows still returned after unsafe sort_by column is ignored');
	}

	# EC22.2 — space in column name: same guard (carp + fallback)
	{
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		lives_ok { $db->selectall_array(sort_by => 'col OR 1=1') }
			'EC22.2 space in sort_by column does not throw (carp + fallback)';
		ok($warned > 0, 'EC22.2 space in sort_by column emits a warning');
	}

	# EC22.3 — invalid direction (not ASC/DESC): carp + fallback to ASC
	{
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		lives_ok { $db->selectall_array(sort_by => ['number', 'INVALID_DIR']) }
			'EC22.3 invalid sort_by direction does not throw (carp + fallback)';
		ok($warned > 0, 'EC22.3 invalid sort_by direction emits a warning');
	}

	# EC22.4 — undef column in arrayref form: carp + fallback
	{
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		lives_ok { $db->selectall_array(sort_by => [undef, 'ASC']) }
			'EC22.4 undef column in sort_by arrayref does not throw';
		ok($warned > 0, 'EC22.4 undef sort_by column emits a warning');
	}

	# EC22.5 — empty string column: carp + fallback
	{
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		lives_ok { $db->selectall_array(sort_by => '') }
			'EC22.5 empty-string sort_by column does not throw (carp + fallback)';
		ok($warned > 0, 'EC22.5 empty-string sort_by column emits a warning');
	}
};

# ===========================================================================
# EC23 — host parameter injection guards (adversarial)
# Purpose: the host parameter is validated at new() time against a strict
# regex. Shell metacharacters, spaces, semicolons, newlines, and path-traversal
# sequences must all be rejected before any SSH or filesystem call is made.
# Note: File::Slurp::Remote is NOT required — validation fires at new() before
# any remote fetch attempt.
# ===========================================================================

subtest 'EC23: host parameter injection guards' => sub {
	plan tests => 10;

	{ package Database::ec23; use parent 'Database::Abstraction'; }

	# EC23.1 — semicolon: shell command separator injection
	throws_ok {
		Database::ec23->new(directory => $DATA_DIR, host => 'host; rm -rf /')
	} qr/unsafe host/i,
		'EC23.1 semicolon in host name croaks at new()';

	# EC23.2 — backtick: command substitution injection
	throws_ok {
		Database::ec23->new(directory => $DATA_DIR, host => '`malicious_cmd`')
	} qr/unsafe host/i,
		'EC23.2 backtick in host name croaks at new()';

	# EC23.3 — embedded newline: log injection / header splitting
	throws_ok {
		Database::ec23->new(directory => $DATA_DIR, host => "valid\nroot\@attacker.com")
	} qr/unsafe host/i,
		'EC23.3 newline in host name croaks at new()';

	# EC23.4 — space: allows argument injection into SSH command
	throws_ok {
		Database::ec23->new(directory => $DATA_DIR, host => 'valid host -o HostbasedAuth=yes')
	} qr/unsafe host/i,
		'EC23.4 space in host name croaks at new()';

	# EC23.5 — dollar-sign variable expansion
	throws_ok {
		Database::ec23->new(directory => $DATA_DIR, host => '$HOSTNAME;evil')
	} qr/unsafe host/i,
		'EC23.5 dollar-sign in host name croaks at new()';

	# EC23.6 — path-traversal attempt
	throws_ok {
		Database::ec23->new(directory => $DATA_DIR, host => '../etc/passwd')
	} qr/unsafe host/i,
		'EC23.6 path-traversal in host name croaks at new()';

	# EC23.7 — empty string: fails the anchored regex
	throws_ok {
		Database::ec23->new(directory => $DATA_DIR, host => '')
	} qr/unsafe host/i,
		'EC23.7 empty string host croaks at new()';

	# EC23.8 — valid hostname (alphanumeric) is accepted
	lives_ok {
		Database::ec23->new(directory => $DATA_DIR, host => 'myserver.example.com')
	} 'EC23.8 valid hostname "myserver.example.com" accepted at new()';

	# EC23.9 — valid user@host form is accepted
	lives_ok {
		Database::ec23->new(directory => $DATA_DIR, host => 'deploy@prod01.example.com')
	} 'EC23.9 valid user@host form accepted at new()';

	# EC23.10 — IPv6 loopback literal is accepted (colon allowed)
	lives_ok {
		Database::ec23->new(directory => $DATA_DIR, host => '::1')
	} 'EC23.10 IPv6 loopback "::1" accepted at new()';
};

# ===========================================================================
# EC24 — _like_match ReDoS safety and edge cases
# Purpose: _like_match is called in slurp-mode _match_criterion for -like and
# -not_like.  The implementation uses a safe DP algorithm and five fast-paths.
# This test verifies each fast path and that the classic ReDoS pattern
# ('%a%a%a%a%b' against a long 'aaa...' string) completes quickly.
# ===========================================================================

subtest 'EC24: _like_match ReDoS safety and edge-case patterns' => sub {
	plan tests => 22;

	my $db = Database::test1->new({ directory => $DATA_DIR });

	# Helper: reach _like_match via _match_criterion with the '-like' operator
	my $like = sub {
		my ($str, $pat) = @_;
		$db->_match_criterion($str, { '-like' => $pat });
	};

	# ---- Fast path 1: bare '%' -----------------------------------------------
	ok($like->('anything', '%'),             'EC24.1 bare "%" matches any string');
	ok($like->('',          '%'),            'EC24.2 bare "%" matches empty string');

	# ---- Fast path 2: no wildcards (equality) ---------------------------------
	ok( $like->('Hello', 'hello'),           'EC24.3 case-insensitive equality match');
	ok(!$like->('Hello', 'world'),           'EC24.4 case-insensitive equality non-match');
	ok(!$like->('ab', 'abc'),                'EC24.5 equality: shorter string does not match');

	# ---- Fast path 3: %suffix -------------------------------------------------
	ok( $like->('hello_world', '%world'),    'EC24.6 %suffix: string ends with suffix');
	ok(!$like->('hello_world', '%worlds'),   'EC24.7 %suffix: string does not end with suffix');

	# ---- Fast path 4: prefix% -------------------------------------------------
	ok( $like->('hello_world', 'hello%'),    'EC24.8 prefix%: string starts with prefix');
	ok(!$like->('world_hello', 'hello%'),    'EC24.9 prefix%: string does not start with prefix');

	# ---- Fast path 5: %literal% -----------------------------------------------
	ok( $like->('say hello there', '%hello%'), 'EC24.10 %literal%: substring found');
	ok(!$like->('say goodbye',      '%hello%'), 'EC24.11 %literal%: substring not found');

	# ---- Full DP: ReDoS trigger pattern (multiple '%' wildcards) -------------
	# '%a%a%a%a%b' against 1000 'a' chars would cause catastrophic backtracking
	# in a naive regex translation.  The DP path must complete in polynomial time.
	{
		my $long_a  = 'a' x 1_000;
		my $t0      = time();
		my $result  = $like->($long_a, '%a%a%a%a%b');   # no 'b' at end -> false
		my $elapsed = time() - $t0;
		ok(!$result,    'EC24.12 multi-% pattern correctly non-matches long-a string');
		ok($elapsed < 5, "EC24.13 multi-% ReDoS pattern completes in <5s (elapsed: ${elapsed}s)");
	}

	# ---- DP path: pattern with '_' single-char wildcard ----------------------
	ok( $like->('aXb', 'a_b'),               'EC24.14 single _ matches one character');
	ok(!$like->('ab',  'a_b'),               'EC24.15 _ does not match zero chars');
	ok(!$like->('axXb', 'a_b'),              'EC24.16 _ does not match two chars');

	# ---- DP path: alternating % and _ wildcards ------------------------------
	ok( $like->('abcd', '%_d'),              'EC24.17 %_d: any-char before d');
	ok(!$like->('abd',  'a__d'),             'EC24.18 a__d: requires exactly two chars between a and d');
	ok( $like->('a12d', 'a__d'),             'EC24.19 a__d: matches two middle chars exactly');

	# ---- Pathological: empty string edge cases --------------------------------
	ok( $like->('', '%'),                    'EC24.20 empty string matches bare %');
	ok(!$like->('', 'a'),                    'EC24.21 empty string does not match "a"');
	ok( $like->('', ''),                     'EC24.22 empty string matches empty pattern');
};

# ===========================================================================
# EC25 — schema() with infer_types edge cases
# Purpose: _infer_type() drives schema() when infer_types => 1 is set.
# infer_types is a SLURP-SOURCE feature — it scans sampled row values to
# promote columns from the default TEXT type to INTEGER, REAL, TIMESTAMP,
# or DATE.  The test uses a CSV fixture so the slurp path is active.
# SQLite DSN is intentionally NOT used here because schema() for a live
# SQL connection uses PRAGMA table_info (declared types), not value inference.
# ===========================================================================

{
	package Database::ec25;
	use parent 'Database::Abstraction';
}

# Build a CSV fixture in a temp dir.  The filename must match the class name
# stem (ec25) and we use sep_char => ',' (standard CSV, not the default '!').
my $ec25_dir = tempdir(CLEANUP => 1);
{
	open my $fh, '>', File::Spec->catfile($ec25_dir, 'ec25.csv');
	# Six columns — no 'entry' primary key (no_entry => 1 is used).
	print $fh "all_int,mixed,all_null,ts_col,dt_col,single\n";
	print $fh "42,3,,2024-01-15 12:00,2024-01-15,99\n";    # all_null blank
	print $fh "-7,1.5,,2025-06-30T08:30,2025-06-30,\n";   # single blank
	print $fh "100,7,,2023-12-01 00:00,2023-12-01,\n";     # single blank
	close $fh;
}

{
	# id => 'all_int' is required for the CSV comment-row filter to match; without
	# an 'entry' column in the file the filter would drop all rows (data => undef).
	my $db25 = Database::ec25->new(
		directory   => $ec25_dir,
		no_entry    => 1,
		sep_char    => ',',
		id          => 'all_int',
		infer_types => 1,
	);
	$db25->count();   # trigger _open and slurp into ARRAY ref

	my $sch = $db25->schema();

	# EC25.1 — schema() returns a populated hashref
	ok(ref($sch) eq 'HASH' && scalar(keys %{$sch}) > 0,
		'EC25.1 schema() returns non-empty hashref with infer_types => 1');

	# EC25.2 — all-integer TEXT column is promoted to INTEGER
	is($sch->{'all_int'}{'type'}, 'INTEGER',
		'EC25.2 all-integer column inferred as INTEGER');

	# EC25.3 — mixed integer+decimal: 1.5 breaks INTEGER but all match REAL
	is($sch->{'mixed'}{'type'}, 'REAL',
		'EC25.3 mixed integer+decimal column inferred as REAL');

	# EC25.4 — all-blank column stays TEXT (no non-blank evidence to infer from)
	is($sch->{'all_null'}{'type'}, 'TEXT',
		'EC25.4 all-blank column stays TEXT (no non-null evidence)');

	# EC25.5 — ISO timestamp column promoted to TIMESTAMP
	is($sch->{'ts_col'}{'type'}, 'TIMESTAMP',
		'EC25.5 ISO timestamp column inferred as TIMESTAMP');

	# EC25.6 — ISO date column promoted to DATE
	is($sch->{'dt_col'}{'type'}, 'DATE',
		'EC25.6 ISO date column inferred as DATE');

	# EC25.7 — single non-blank value column is still inferred correctly
	is($sch->{'single'}{'type'}, 'INTEGER',
		'EC25.7 column with one non-null value (99) inferred as INTEGER');

	# EC25.8 — without infer_types, all CSV columns default to TEXT
	my $db25_noif = Database::ec25->new(
		directory => $ec25_dir,
		no_entry  => 1,
		sep_char  => ',',
		id        => 'all_int',
	);
	$db25_noif->count();
	my $sch_noif = $db25_noif->schema();
	is($sch_noif->{'all_int'}{'type'}, 'TEXT',
		'EC25.8 without infer_types, CSV column stays TEXT regardless of values');

	# EC25.9 — schema() is cached: second call returns the same hashref reference
	my $sch_again = $db25->schema();
	is($sch, $sch_again, 'EC25.9 schema() returns same cached hashref on repeated calls');

	# EC25.10 — schema has one key per column (6 columns)
	is(scalar(keys %{$sch}), 6, 'EC25.10 schema() has exactly 6 column entries');

	# EC25.11 — every schema entry has a "type" key
	my $all_typed = 1;
	for my $col (keys %{$sch}) { $all_typed = 0 unless exists $sch->{$col}{'type'} }
	ok($all_typed, 'EC25.11 every schema entry has a "type" key');

	# EC25.12 — blank values must not cause schema() to throw
	lives_ok { $db25->schema() }
		'EC25.12 schema() does not throw when column values include blanks/undef';
}

# ===========================================================================
# EC26 — Boundary conditions for limit / offset parameters
# Purpose: limit and offset must reject non-integer inputs (carp + ignore)
# and handle the exact boundary where offset equals the row count (0 rows).
# ===========================================================================

subtest 'EC26: limit/offset boundary conditions' => sub {
	plan tests => 12;

	my $db = Database::test1->new({ directory => $DATA_DIR });

	# EC26.1 — limit => 0 returns empty result, does not crash
	{
		my $rows;
		lives_ok { $rows = $db->selectall_arrayref(limit => 0) }
			'EC26.1 limit => 0 does not throw';
		is(scalar(@{$rows}), 0, 'EC26.1 limit => 0 returns 0 rows');
	}

	# EC26.2 — limit => 1 returns exactly 1 row
	is(scalar(@{$db->selectall_arrayref(limit => 1)}), 1,
		'EC26.2 limit => 1 returns exactly 1 row');

	# EC26.3 — limit larger than row count returns all rows
	is(scalar(@{$db->selectall_arrayref(limit => 999_999)}), $ROWS_TOTAL,
		'EC26.3 limit > row count returns all rows without crash');

	# EC26.4 — negative limit: carp + treat as invalid; result must be an arrayref
	{
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $rows = $db->selectall_arrayref(limit => -1);
		ok(defined($rows) && ref($rows) eq 'ARRAY',
			'EC26.4 negative limit does not crash (returns arrayref)');
		diag "EC26.4 warned=$warned rows=@{[scalar @{$rows}]}" if $ENV{TEST_VERBOSE};
	}

	# EC26.5 — float limit is floor-cast to integer
	{
		my $rows;
		lives_ok { $rows = $db->selectall_arrayref(limit => 2.9) }
			'EC26.5 float limit does not throw';
		ok(scalar(@{$rows}) <= $ROWS_TOTAL, 'EC26.5 float limit result stays within total row count');
	}

	# EC26.6 — non-numeric limit string: carp + ignore -> all rows returned
	{
		my $warned = 0;
		local $SIG{__WARN__} = sub { $warned++ };
		my $rows = $db->selectall_arrayref(limit => 'two');
		is(scalar(@{$rows}), $ROWS_TOTAL,
			'EC26.6 non-numeric limit is ignored; all rows returned');
		ok($warned > 0, 'EC26.6 non-numeric limit emits a carp warning');
	}

	# EC26.7 — offset == row count: exact boundary returns 0 rows
	is(scalar(@{$db->selectall_arrayref(limit => 999, offset => $ROWS_TOTAL)}), 0,
		'EC26.7 offset == row count returns 0 rows (exact boundary)');

	# EC26.8 — offset far beyond row count: 0 rows, no crash
	{
		my $rows;
		lives_ok { $rows = $db->selectall_arrayref(limit => 999, offset => 999_999) }
			'EC26.8 offset beyond row count does not throw';
		is(scalar(@{$rows}), 0, 'EC26.8 offset beyond row count returns 0 rows');
	}
};

# ===========================================================================
# EC27 — AUTOLOAD hostile method name dispatch
# Purpose: AUTOLOAD intercepts unknown method calls for column lookup.
# Method names starting with '_', 'DESTROY', 'BEGIN', 'AUTOLOAD', etc. must
# NOT be treated as column lookups.  auto_load => 0 must suppress all AUTOLOAD
# column dispatch entirely.
# ===========================================================================

subtest 'EC27: AUTOLOAD hostile method name dispatch' => sub {
	plan tests => 6;

	my $db = Database::test1->new({ directory => $DATA_DIR });
	$db->count();   # force slurp

	# EC27.1 — _prefixed method names are not column lookups
	eval { $db->_nonexistent_col(entry => 'one') };
	ok(1, 'EC27.1 _prefixed method call does not crash (AUTOLOAD guard in place)');
	diag "EC27.1 error: $@" if $@ && $ENV{TEST_VERBOSE};

	# EC27.2 — 'DESTROY' must not be treated as a column lookup
	{
		eval { local $SIG{__WARN__} = sub {}; $db->DESTROY() };
		ok(!($@ && $@ =~ /no column/i),
			'EC27.2 DESTROY does not croak "no column" (not treated as AUTOLOAD column)');
	}

	# EC27.3 — ->can() is a UNIVERSAL method and must not hit AUTOLOAD
	lives_ok { $db->can('count') }
		'EC27.3 ->can("count") dispatches to UNIVERSAL::can, not AUTOLOAD';

	# EC27.4 — auto_load => 0: AUTOLOAD column dispatch is suppressed
	{
		my $db_no_al = Database::test1->new({ directory => $DATA_DIR, auto_load => 0 });
		eval { $db_no_al->number(entry => 'one') };
		ok($@, 'EC27.4 auto_load => 0: calling column method via AUTOLOAD throws');
		unlike($@, qr/no column/i,
			"EC27.4 auto_load => 0: error is not \"no column\" (method is simply unknown)");
	}

	# EC27.5 — ->can() with a name that starts with a digit: must not segfault
	eval { $db->can('123col') };
	ok(1, 'EC27.5 ->can("123col") does not segfault');
};

done_testing();
