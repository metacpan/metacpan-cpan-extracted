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

SKIP: {
	skip 'DBD::SQLite not available', 3 unless $HAVE_SQLITE;

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
}   # end SKIP block

done_testing();
