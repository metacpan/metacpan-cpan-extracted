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
		is(scalar(@{$rows}), 0, 'EC7.1 score > 1e308 returns 0 rows');

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
};

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

done_testing();
