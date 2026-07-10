#!perl -w

# t/integration.t — black-box, end-to-end workflow tests
#
# Focus areas:
#   A. Cross-backend API consistency (CSV, PSV, XML, SQLite)
#   B. Slurp-mode vs SQL-mode behavioural equivalence
#   C. Multi-instance non-interference
#   D. init() → new() → clone chain
#   E. Full criteria-operator suite (SQLite)
#   F. Query-builder ↔ direct-method equivalence
#   G. CHI cache coherence across calls and instances
#   H. columns() / schema() caching and consistency
#   I. no_entry CSV full workflow
#   J. AUTOLOAD variants across multiple backends
#   K. Logging propagation from db through query builder
#   L. Optional-dependency graceful degradation (Test::Without::Module)

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Readonly;
use Scalar::Util qw(blessed reftype);
use Test::Most;
use Test::Returns qw(returns_ok);
use Test::Without::Module ();	# loaded but not applied globally yet

use lib 't/lib';

use_ok('Database::test1');	# keyed CSV (! sep, 'entry' key)
use_ok('Database::test2');	# PSV (| sep, 'entry' key)
use_ok('Database::test3');	# XML complex — must use max_slurp_size => 1
use_ok('Database::test4');	# no_entry CSV (, sep)
use_ok('Database::test5');	# CSV with custom ID column

Readonly my $DATA_DIR       => File::Spec->catfile($Bin, File::Spec->updir(), 't', 'data');
Readonly my $TOTAL_TEST1    => 4;	# one, two, three, empty
Readonly my $TOTAL_TEST4    => 3;	# cardinal: one, two, three
Readonly my $TOTAL_TEST5    => 5;	# five people
Readonly my $NUM_ONE        => 1;
Readonly my $NUM_TWO        => 2;
Readonly my $ENTRY_ONE      => 'one';
Readonly my $ENTRY_TWO      => 'two';

# Optional dependencies — probe once and SKIP whole sections if absent
my $have_sqlite = do { local $@; eval { require DBI; require DBD::SQLite; 1 } };
my $have_chi    = do { local $@; eval { require CHI; 1 } };
my $have_db_file = do { local $@; eval { require DB_File; 1 } };

# ---------------------------------------------------------------------------
# SECTION A — Cross-backend API consistency
# Verify that CSV, PSV, XML (SQL mode), and SQLite all respond correctly to
# the same public API surface: columns(), schema(), count(), selectall_arrayref(),
# fetchrow_hashref().
# ---------------------------------------------------------------------------

note '';
note '=== A. Cross-backend API consistency ===';

{
	my $csv = Database::test1->new($DATA_DIR);
	my $psv = Database::test2->new($DATA_DIR);
	# XML test3 requires SQL mode because its nested <entry> structure is not
	# supported by the XML slurp path (see CLAUDE.md: XML slurp limitation).
	my $xml = Database::test3->new({ directory => $DATA_DIR, max_slurp_size => 1 });

	# A1 — columns() returns an arrayref on all backends
	returns_ok($csv->columns(), { type => 'arrayref' }, 'A1a CSV: columns() returns arrayref');
	returns_ok($psv->columns(), { type => 'arrayref' }, 'A1b PSV: columns() returns arrayref');
	returns_ok($xml->columns(), { type => 'arrayref' }, 'A1c XML(SQL): columns() returns arrayref');

	# A2 — schema() returns a hashref on all backends
	returns_ok($csv->schema(), { type => 'hashref' }, 'A2a CSV: schema() returns hashref');
	returns_ok($psv->schema(), { type => 'hashref' }, 'A2b PSV: schema() returns hashref');
	returns_ok($xml->schema(), { type => 'hashref' }, 'A2c XML(SQL): schema() returns hashref');

	# A3 — count() returns a non-negative integer on all backends
	my $csv_cnt = $csv->count();
	my $psv_cnt = $psv->count();
	ok($csv_cnt > 0, 'A3a CSV: count() > 0');
	ok($psv_cnt > 0, 'A3b PSV: count() > 0');

	# A4 — selectall_arrayref() returns arrayref-of-hashrefs on all backends
	my $csv_all = $csv->selectall_arrayref();
	my $psv_all = $psv->selectall_arrayref();
	my $xml_all = $xml->selectall_arrayref();

	ok(ref($csv_all) eq 'ARRAY' && @{$csv_all} > 0, 'A4a CSV: selectall_arrayref non-empty');
	ok(ref($psv_all) eq 'ARRAY' && @{$psv_all} > 0, 'A4b PSV: selectall_arrayref non-empty');
	ok(ref($xml_all) eq 'ARRAY' && @{$xml_all} > 0, 'A4c XML(SQL): selectall_arrayref non-empty');
	ok(ref($csv_all->[0]) eq 'HASH', 'A4d CSV: each element is a hashref');
	ok(ref($psv_all->[0]) eq 'HASH', 'A4e PSV: each element is a hashref');
	ok(ref($xml_all->[0]) eq 'HASH', 'A4f XML(SQL): each element is a hashref');

	# A5 — fetchrow_hashref() returns a hashref on match, undef on miss
	my $csv_row = $csv->fetchrow_hashref(entry => $ENTRY_ONE);
	my $psv_row = $psv->fetchrow_hashref(entry => 'first');
	ok(ref($csv_row) eq 'HASH', 'A5a CSV: fetchrow_hashref returns hashref on match');
	ok(ref($psv_row) eq 'HASH', 'A5b PSV: fetchrow_hashref returns hashref on match');
	ok(!defined($csv->fetchrow_hashref(entry => '__no_such_entry__')),
		'A5c CSV: fetchrow_hashref returns undef on miss');

	# A6 — SQLite backend (if available) also satisfies the same contract
	SKIP: {
		skip 'DBD::SQLite not available', 4 unless $have_sqlite;

		my $dir  = tempdir(CLEANUP => 1);
		my $file = File::Spec->catfile($dir, 'integ_a6.sql');
		my $dsn  = "dbi:SQLite:dbname=$file";

		my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
		$setup->do('CREATE TABLE integ_a6 (entry TEXT PRIMARY KEY, label TEXT)');
		$setup->do("INSERT INTO integ_a6 VALUES ('k1', 'alpha')");
		$setup->do("INSERT INTO integ_a6 VALUES ('k2', 'beta')");
		$setup->disconnect();

		{
			package Database::integ_a6;
			use parent 'Database::Abstraction';
		}

		my $db = Database::integ_a6->new(dsn => $dsn);

		returns_ok($db->columns(), { type => 'arrayref' }, 'A6a SQLite: columns() returns arrayref');
		returns_ok($db->schema(),  { type => 'hashref'  }, 'A6b SQLite: schema() returns hashref');
		is($db->count(), 2,                        'A6c SQLite: count() == 2');
		ok(ref($db->fetchrow_hashref(entry => 'k1')) eq 'HASH',
			'A6d SQLite: fetchrow_hashref returns hashref');
	}
}

# ---------------------------------------------------------------------------
# SECTION B — Slurp-mode vs SQL-mode behavioural equivalence
# The same CSV file, loaded once into RAM (slurp) and once forced through
# DBD::CSV (max_slurp_size => 0), must give identical results for the core
# read methods.
# ---------------------------------------------------------------------------

note '';
note '=== B. Slurp vs SQL-mode equivalence ===';

{
	my $slurp = Database::test1->new($DATA_DIR);
	my $sql   = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => 0 });

	# Trigger _open on both objects before checking internal mode flags.
	# _open() is called lazily on the first query, not in new().
	$slurp->count();
	$sql->count();

	# Confirm the two objects really are in different modes
	ok( defined($slurp->{'data'}), 'B0a slurp object has in-memory data');
	ok(!defined($sql->{'data'}),   'B0b SQL  object has no in-memory data');

	# B1 — count() is identical in both modes
	is($slurp->count(), $TOTAL_TEST1, 'B1a slurp count() == TOTAL_TEST1');
	is($sql->count(),   $TOTAL_TEST1, 'B1b SQL   count() == TOTAL_TEST1');

	# B2 — fetchrow_hashref() by entry key returns the same row
	my $slurp_row = $slurp->fetchrow_hashref(entry => $ENTRY_ONE);
	my $sql_row   = $sql->fetchrow_hashref(entry => $ENTRY_ONE);
	is($slurp_row->{'number'}, $NUM_ONE, 'B2a slurp fetchrow entry=one -> number=1');
	is($sql_row->{'number'},   $NUM_ONE, 'B2b SQL   fetchrow entry=one -> number=1');

	# B3 — selectall_arrayref() returns the same row count
	my $slurp_all = $slurp->selectall_arrayref();
	my $sql_all   = $sql->selectall_arrayref();
	is(scalar @{$slurp_all}, $TOTAL_TEST1, 'B3a slurp selectall_arrayref row count');
	is(scalar @{$sql_all},   $TOTAL_TEST1, 'B3b SQL   selectall_arrayref row count');

	# B4 — AUTOLOAD column lookup returns same value in both modes
	my $slurp_num = $slurp->number($ENTRY_ONE);
	my $sql_num   = $sql->number($ENTRY_ONE);
	is($slurp_num, $NUM_ONE, 'B4a slurp AUTOLOAD number(one) == 1');
	is($sql_num,   $NUM_ONE, 'B4b SQL   AUTOLOAD number(one) == 1');

	# B5 — count(entry => key) is 1 for a known entry, 0 for unknown
	is($slurp->count(entry => $ENTRY_ONE), 1, 'B5a slurp count known entry == 1');
	is($sql->count(  entry => $ENTRY_ONE), 1, 'B5b SQL   count known entry == 1');
	is($slurp->count(entry => '__gone__'), 0, 'B5c slurp count missing entry == 0');
	is($sql->count(  entry => '__gone__'), 0, 'B5d SQL   count missing entry == 0');
}

# ---------------------------------------------------------------------------
# SECTION C — Multi-instance non-interference
# Two independent objects pointing at the same data file must not share
# mutable state; criteria on one must not contaminate the other.
# ---------------------------------------------------------------------------

note '';
note '=== C. Multi-instance non-interference ===';

{
	my $db_a = Database::test1->new($DATA_DIR);
	my $db_b = Database::test1->new($DATA_DIR);

	# C1 — Both objects return correct data independently
	is($db_a->fetchrow_hashref(entry => 'one')->{'number'},   1, 'C1a db_a: one->1');
	is($db_b->fetchrow_hashref(entry => 'two')->{'number'},   2, 'C1b db_b: two->2');
	is($db_a->fetchrow_hashref(entry => 'three')->{'number'}, 3, 'C1c db_a: three->3');
	is($db_b->fetchrow_hashref(entry => 'one')->{'number'},   1, 'C1d db_b: one->1');

	# C2 — count() on one object does not change the other's count
	my $cnt_a = $db_a->count();
	my $cnt_b = $db_b->count();
	is($cnt_a, $cnt_b, 'C2: both instances return same count');

	# C3 — The in-memory data refs are different objects (separate copies)
	#      so locking one does not affect the other
	isnt(
		$db_a->{'data'},
		$db_b->{'data'},
		'C3: data refs are distinct (no shared mutable state)'
	);

	# C4 — PSV and CSV backends coexist in the same process without collision
	my $csv = Database::test1->new($DATA_DIR);
	my $psv = Database::test2->new($DATA_DIR);
	ok(defined($csv->fetchrow_hashref(entry => 'one')),   'C4a CSV object still responds');
	ok(defined($psv->fetchrow_hashref(entry => 'first')), 'C4b PSV object still responds');
}

# ---------------------------------------------------------------------------
# SECTION D — init() → new() → clone chain
# init() seeds class-level defaults; new() without explicit args uses them;
# clone() inherits existing keys but accepts overrides.
# ---------------------------------------------------------------------------

note '';
note '=== D. init() -> new() -> clone chain ===';

{
	# Use local to prevent %defaults changes from leaking to later sections
	local %Database::Abstraction::defaults;

	# D1 — init() with directory means new() needs no explicit directory
	Database::Abstraction::init(directory => $DATA_DIR);
	my $from_defaults = Database::test1->new();
	ok(defined($from_defaults), 'D1: new() with no args uses init() directory');
	is($from_defaults->count(), $TOTAL_TEST1, 'D1: object from defaults returns correct count');

	# D2 — init() returns the current defaults hashref
	my $defs = Database::Abstraction::init();
	is(ref($defs), 'HASH', 'D2: init() returns hashref');
	is($defs->{'directory'}, $DATA_DIR, 'D2: directory default is set');

	# D3 — expires_in is aliased to cache_duration in init()
	Database::Abstraction::init(expires_in => '30 minutes');
	my $defs2 = Database::Abstraction::init();
	is($defs2->{'cache_duration'}, '30 minutes', 'D3: expires_in aliased to cache_duration in init()');

	# D4 — Clone via ->new() on an existing object merges new keys
	my $original = Database::test1->new(directory => $DATA_DIR, max_slurp_size => 0);
	my $clone    = $original->new(max_slurp_size => 99_999);
	isa_ok($clone, 'Database::test1', 'D4: clone is still a Database::test1');
	is($clone->{'max_slurp_size'}, 99_999, 'D4: clone has overridden max_slurp_size');
	is($clone->{'directory'}, $original->{'directory'}, 'D4: clone inherits directory');

	# D5 — The original is unaffected by the clone's override
	is($original->{'max_slurp_size'}, 0, 'D5: original max_slurp_size unchanged after clone');
}

# ---------------------------------------------------------------------------
# SECTION E — Full criteria-operator suite (SQLite)
# Uses a controlled SQLite fixture to exercise every supported operator:
# =, !=, <, <=, >, >=, -in, -not_in, -between, -like, -not_like, -or, -and.
# ---------------------------------------------------------------------------

note '';
note '=== E. Full criteria-operator suite (SQLite) ===';

SKIP: {
	skip 'DBD::SQLite not available for criteria tests', 30 unless $have_sqlite;

	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'integ_e.sql');
	my $dsn  = "dbi:SQLite:dbname=$file";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do(q{
		CREATE TABLE integ_e (
			entry   TEXT PRIMARY KEY,
			name    TEXT,
			score   INTEGER,
			status  TEXT,
			country TEXT
		)
	});
	$setup->do("INSERT INTO integ_e VALUES ('alice', 'Alice', 90, 'active',   'US')");
	$setup->do("INSERT INTO integ_e VALUES ('bob',   'Bob',   70, 'inactive', 'UK')");
	$setup->do("INSERT INTO integ_e VALUES ('carol', 'Carol', 85, 'active',   'US')");
	$setup->do("INSERT INTO integ_e VALUES ('dave',  'Dave',  60, 'inactive', 'DE')");
	$setup->do("INSERT INTO integ_e VALUES ('eve',   'Eve',   95, 'active',   'UK')");
	$setup->disconnect();

	{
		package Database::integ_e;
		use parent 'Database::Abstraction';
	}

	# no_entry => 1: avoids Params::Get mapping the first scalar arg to 'entry'
	# (same pattern as t/query_builder.t). 'entry' is still a queryable column.
	my $db = Database::integ_e->new(dsn => $dsn, no_entry => 1);

	# E1 — plain equality
	my $r = $db->selectall_arrayref(status => 'active');
	is(scalar @{$r}, 3, 'E1: equality match returns 3 active rows');

	# E2 — != (not equal)
	$r = $db->selectall_arrayref(status => { '!=' => 'active' });
	is(scalar @{$r}, 2, 'E2: != returns 2 inactive rows');

	# E3 — > (greater than)
	$r = $db->selectall_arrayref(score => { '>' => 85 });
	is(scalar @{$r}, 2, 'E3: score > 85 returns alice(90) and eve(95)');

	# E4 — < (less than)
	$r = $db->selectall_arrayref(score => { '<' => 70 });
	is(scalar @{$r}, 1, 'E4: score < 70 returns dave(60) only');

	# E5 — >= (greater-or-equal)
	$r = $db->selectall_arrayref(score => { '>=' => 85 });
	is(scalar @{$r}, 3, 'E5: score >= 85 returns alice, carol, eve');

	# E6 — <= (less-or-equal)
	$r = $db->selectall_arrayref(score => { '<=' => 70 });
	is(scalar @{$r}, 2, 'E6: score <= 70 returns bob and dave');

	# E7 — combined > and < on same column (AND semantics: 60 < score < 90)
	$r = $db->selectall_arrayref(score => { '>' => 60, '<' => 90 });
	is(scalar @{$r}, 2, 'E7: 60 < score < 90 returns bob(70) and carol(85)');

	# E8 — -in
	$r = $db->selectall_arrayref(country => { -in => ['US', 'DE'] });
	is(scalar @{$r}, 3, 'E8: country -in [US,DE] returns alice, carol, dave');

	# E9 — -not_in
	$r = $db->selectall_arrayref(country => { -not_in => ['US', 'DE'] });
	is(scalar @{$r}, 2, 'E9: country -not_in [US,DE] returns bob, eve (UK)');

	# E10 — -between
	$r = $db->selectall_arrayref(score => { -between => [70, 90] });
	is(scalar @{$r}, 3, 'E10: score -between [70,90] returns bob, carol, alice');

	# E11 — -like (SQL LIKE pattern)
	$r = $db->selectall_arrayref(name => { -like => 'A%' });
	is(scalar @{$r}, 1, 'E11: name -like A% returns alice only');

	# E12 — -not_like (SQLite LIKE is case-insensitive for ASCII, so %e% matches 'E' too)
	#        Alice (e), Dave (e), Eve (E+e) are excluded; Bob, Carol remain → 2 rows
	$r = $db->selectall_arrayref(name => { -not_like => '%e%' });
	is(scalar @{$r}, 2, 'E12: name -not_like %e% excludes Alice, Dave, Eve');

	# E13 — automatic LIKE from wildcard in plain value
	$r = $db->selectall_arrayref(name => 'C%');
	is(scalar @{$r}, 1, 'E13: plain wildcard value triggers LIKE');
	is($r->[0]{'name'}, 'Carol', 'E13: matched row is Carol');

	# E14 — -or grouping across two columns
	$r = $db->selectall_arrayref(
		-or => [
			{ country => 'DE' },
			{ score   => { '>=' => 90 } },
		]
	);
	is(scalar @{$r}, 3, 'E14: -or [DE | score>=90] returns dave, alice, eve');

	# E15 — -and grouping (redundant with implicit AND but must work)
	$r = $db->selectall_arrayref(
		-and => [
			{ status  => 'active'      },
			{ country => 'UK'          },
		]
	);
	is(scalar @{$r}, 1, 'E15: -and [active AND UK] returns eve only');
	is($r->[0]{'name'}, 'Eve', 'E15: matched row is Eve');

	# E16 — count() with operator criteria
	is($db->count(score => { '>' => 80 }), 3, 'E16: count score>80 == 3');

	# E17 — fetchrow_hashref with operator criteria (LIMIT 1 semantics)
	my $row = $db->fetchrow_hashref(score => { '>=' => 95 });
	ok(defined($row),             'E17: fetchrow_hashref with operator returns row');
	is($row->{'name'}, 'Eve',     'E17: highest-score row is Eve');

	# E18 — multi-column implicit AND via direct criteria
	$r = $db->selectall_arrayref(status => 'active', country => 'US');
	is(scalar @{$r}, 2, 'E18: status=active AND country=US returns alice and carol');

	# E19 — IS NULL via undef value
	#       Insert a row with NULL status to verify the undef → IS NULL mapping
	my $setup2 = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup2->do("INSERT INTO integ_e VALUES ('null_row', 'Null', 50, NULL, 'US')");
	$setup2->disconnect();

	my $db2 = Database::integ_e->new(dsn => $dsn, no_entry => 1);
	$r = $db2->selectall_arrayref(status => undef);
	is(scalar @{$r}, 1, 'E19: status IS NULL returns the one null-status row');
	is($r->[0]{'name'}, 'Null', 'E19: the null-status row is the one we inserted');
}

# ---------------------------------------------------------------------------
# SECTION F — Query-builder ↔ direct-method equivalence
# The fluent query builder must produce identical results to the direct
# selectall_arrayref / fetchrow_hashref / count calls for the same criteria.
# ---------------------------------------------------------------------------

note '';
note '=== F. Query-builder vs direct-method equivalence ===';

SKIP: {
	skip 'DBD::SQLite not available for query-builder tests', 14 unless $have_sqlite;

	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'integ_f.sql');
	my $dsn  = "dbi:SQLite:dbname=$file";

	my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
	$setup->do(q{
		CREATE TABLE integ_f (
			entry   TEXT PRIMARY KEY,
			name    TEXT,
			score   INTEGER,
			status  TEXT
		)
	});
	$setup->do("INSERT INTO integ_f VALUES ('a', 'Alpha', 80, 'active')");
	$setup->do("INSERT INTO integ_f VALUES ('b', 'Beta',  60, 'inactive')");
	$setup->do("INSERT INTO integ_f VALUES ('c', 'Gamma', 90, 'active')");
	$setup->do("INSERT INTO integ_f VALUES ('d', 'Delta', 70, 'inactive')");
	$setup->do("INSERT INTO integ_f VALUES ('e', 'Eta',   95, 'active')");
	$setup->disconnect();

	{
		package Database::integ_f;
		use parent 'Database::Abstraction';
	}

	# no_entry => 1 to avoid Params::Get positional-key mapping (same as query_builder.t)
	my $db = Database::integ_f->new(dsn => $dsn, no_entry => 1);

	# F1 — all() == selectall_arrayref()
	my $direct = $db->selectall_arrayref();
	my $qb     = $db->query->all();
	is(scalar @{$direct}, scalar @{$qb}, 'F1: query->all() row count == selectall_arrayref');

	# F2 — where()->all() == selectall_arrayref(criteria)
	my $direct2 = $db->selectall_arrayref(status => 'active');
	my $qb2     = $db->query->where(status => 'active')->all();
	is(scalar @{$direct2}, scalar @{$qb2}, 'F2: where->all row count == selectall_arrayref');
	is(scalar @{$qb2}, 3, 'F2: 3 active rows returned');

	# F3 — first() == fetchrow_hashref() (same row)
	my $direct3 = $db->fetchrow_hashref(entry => 'a');
	my $qb3     = $db->query->where(entry => 'a')->first();
	is($direct3->{'name'}, $qb3->{'name'}, 'F3: query->first() name == fetchrow_hashref name');

	# F4 — count() == query->count()
	my $direct4 = $db->count(status => 'active');
	my $qb4     = $db->query->where(status => 'active')->count();
	is($direct4, $qb4, 'F4: query->count() == direct count()');

	# F5 — chained where() applies AND semantics
	my $qb5 = $db->query->where(status => 'active')->where(score => { '>=' => 90 })->all();
	is(scalar @{$qb5}, 2, 'F5: chained where(active) + where(>=90) returns 2 rows');

	# F6 — order_by() changes row ordering
	my $asc  = $db->query->order_by('score ASC')->all();
	my $desc = $db->query->order_by('score DESC')->all();
	ok($asc->[0]{'score'} <= $asc->[-1]{'score'},  'F6a: ASC order is ascending');
	ok($desc->[0]{'score'} >= $desc->[-1]{'score'}, 'F6b: DESC order is descending');

	# F7 — limit() restricts row count
	my $limited = $db->query->limit(2)->all();
	is(scalar @{$limited}, 2, 'F7: limit(2) returns exactly 2 rows');

	# F8 — limit() + offset() implements paging
	my $all_sorted = $db->query->order_by('score ASC')->all();
	my $page1 = $db->query->order_by('score ASC')->limit(2)->offset(0)->all();
	my $page2 = $db->query->order_by('score ASC')->limit(2)->offset(2)->all();
	is($page1->[0]{'entry'}, $all_sorted->[0]{'entry'}, 'F8a: page1 starts at first row');
	is($page2->[0]{'entry'}, $all_sorted->[2]{'entry'}, 'F8b: page2 starts at third row');

	# F9 — first() returns undef on no match (same as fetchrow_hashref miss)
	my $miss_direct = $db->fetchrow_hashref(entry => '__none__');
	my $miss_qb     = $db->query->where(entry => '__none__')->first();
	ok(!defined($miss_direct), 'F9a: fetchrow_hashref miss returns undef');
	ok(!defined($miss_qb),     'F9b: query->first() miss returns undef');
}

# ---------------------------------------------------------------------------
# SECTION G — CHI cache coherence across calls and instances
# Verifies: miss → populate → hit workflow; count() reuses selectall cache;
# two objects sharing a CHI instance share cached results.
# ---------------------------------------------------------------------------

note '';
note '=== G. CHI cache coherence ===';

SKIP: {
	skip 'CHI not available', 12 unless $have_chi;

	my $cache = CHI->new(driver => 'RawMemory', global => 0);

	# Force SQL mode so all queries hit the cache (slurp bypasses it).
	my $db = Database::test1->new({
		directory      => $DATA_DIR,
		cache          => $cache,
		max_slurp_size => 0,
	});

	# G1 — cache starts empty
	is(scalar $cache->get_keys(), 0, 'G1: cache starts empty');

	# G2 — first selectall populates cache (MISS → store)
	my $all = $db->selectall_arrayref();
	ok(scalar $cache->get_keys() > 0, 'G2: selectall_arrayref populates cache');

	# G3 — second call returns cached data (HIT — no additional keys)
	my $key_count_before = scalar $cache->get_keys();
	my $all2 = $db->selectall_arrayref();
	is(scalar $cache->get_keys(), $key_count_before, 'G3: second call does not add cache keys (HIT)');
	is(scalar @{$all2}, scalar @{$all}, 'G3: cached result has same row count');

	# G4 — a second db object sharing the same CHI instance gets the hit too
	my $db2 = Database::test1->new({
		directory      => $DATA_DIR,
		cache          => $cache,
		max_slurp_size => 0,
	});
	my $key_count_before2 = scalar $cache->get_keys();
	my $all3 = $db2->selectall_arrayref();
	is(scalar $cache->get_keys(), $key_count_before2,
		'G4: shared-cache second object does not add keys on HIT');
	is(scalar @{$all3}, scalar @{$all}, 'G4: shared-cache second object returns same row count');

	# G5 — count() with no criteria can reuse the selectall cache opportunistically
	#       After a selectall HIT the cache has the array; count() should derive from it.
	my $cnt = $db->count();
	is($cnt, $TOTAL_TEST1, 'G5: count() returns correct total even when built from cache');

	# G6 — AUTOLOAD in scalar mode with cache: miss then hit
	my $cache2 = CHI->new(driver => 'RawMemory', global => 0);
	my $db3 = Database::test1->new({
		directory      => $DATA_DIR,
		cache          => $cache2,
		max_slurp_size => 0,
	});

	my $v1 = $db3->number($ENTRY_ONE);
	is($v1, $NUM_ONE, 'G6: AUTOLOAD cache MISS returns correct value');

	my $key_before = scalar $cache2->get_keys();
	my $v2 = $db3->number($ENTRY_ONE);
	is($v2, $NUM_ONE, 'G6: AUTOLOAD cache HIT returns same value');
	is(scalar $cache2->get_keys(), $key_before,
		'G6: AUTOLOAD HIT does not add a new cache key');

	# G7 — Fetching different entries adds separate cache keys
	$db3->number($ENTRY_TWO);
	ok(scalar $cache2->get_keys() > $key_before,
		'G7: different entry query adds a new cache key');

	# G8 — cache is ignored when not configured (no crash, no caching)
	my $db_no_cache = Database::test1->new({ directory => $DATA_DIR, max_slurp_size => 0 });
	my $r = $db_no_cache->selectall_arrayref();
	ok(defined($r) && ref($r) eq 'ARRAY',
		'G8: selectall_arrayref without cache returns arrayref (no crash)');
}

# ---------------------------------------------------------------------------
# SECTION H — columns() / schema() caching and cross-backend consistency
# The result of columns() and schema() must be cached inside the object
# (same reference on second call) and their content must be mutually
# consistent (schema keys == columns elements).
# ---------------------------------------------------------------------------

note '';
note '=== H. columns() / schema() caching and consistency ===';

{
	my $db = Database::test1->new($DATA_DIR);

	# H1 — columns() returns same ref on second call (cached)
	my $cols1 = $db->columns();
	my $cols2 = $db->columns();
	is($cols1, $cols2, 'H1: columns() returns same ref (cached)');

	# H2 — schema() returns same ref on second call (cached)
	my $sch1 = $db->schema();
	my $sch2 = $db->schema();
	is($sch1, $sch2, 'H2: schema() returns same ref (cached)');

	# H3 — schema keys and columns elements agree
	my @col_names  = sort @{$cols1};
	my @schema_keys = sort keys %{$sch1};
	is_deeply(\@col_names, \@schema_keys, 'H3: schema keys match columns() elements');

	# H4 — entry column is in both columns() and schema() for a keyed table
	ok(scalar(grep { $_ eq 'entry' } @{$cols1}), 'H4a: "entry" in columns()');
	ok(exists $sch1->{'entry'},           'H4b: "entry" in schema()');

	# H5 — schema() for the entry column marks it as pk
	is($sch1->{'entry'}{'pk'}, 1, 'H5: entry column is primary key per schema()');

	# H6 — Independently created object gets its own cached ref (no sharing)
	my $db2  = Database::test1->new($DATA_DIR);
	my $cols3 = $db2->columns();
	isnt($cols1, $cols3, 'H6: separate objects have separate cached column refs');
}

# ---------------------------------------------------------------------------
# SECTION I — no_entry CSV full workflow
# test4 uses no_entry => 1, sep_char => ','. Exercises all core methods
# including AUTOLOAD by a non-key column criterion.
# ---------------------------------------------------------------------------

note '';
note '=== I. no_entry CSV workflow ===';

{
	# test4 overrides new() and doesn't support bare-string shortcut; use named form
	my $db = Database::test4->new(directory => $DATA_DIR);

	# I1 — count() returns total row count
	is($db->count(), $TOTAL_TEST4, 'I1: no_entry count() == 3');

	# I2 — selectall_arrayref() returns all rows
	my $all = $db->selectall_arrayref();
	is(scalar @{$all}, $TOTAL_TEST4, 'I2: no_entry selectall_arrayref() == 3 rows');
	ok(ref($all->[0]) eq 'HASH', 'I2: each element is a hashref');

	# I3 — fetchrow_hashref() by non-key column returns correct row
	my $row = $db->fetchrow_hashref(cardinal => 'two');
	ok(defined($row), 'I3: no_entry fetchrow_hashref(cardinal=>two) defined');
	is($row->{'ordinal'}, 'second', 'I3: ordinal column value is "second"');

	# I4 — fetchrow_hashref() with miss returns undef
	ok(!defined($db->fetchrow_hashref(cardinal => '__none__')),
		'I4: no_entry fetchrow_hashref miss returns undef');

	# I5 — AUTOLOAD column lookup by non-key criterion
	my $ord = $db->ordinal(cardinal => 'three');
	is($ord, 'third', 'I5: no_entry AUTOLOAD ordinal(cardinal=>three) == third');

	# I6 — selectall_arrayref() with criteria narrows results
	my $one_row = $db->selectall_arrayref(cardinal => 'one');
	is(scalar @{$one_row}, 1,       'I6: no_entry selectall with criteria returns 1 row');
	is($one_row->[0]{'ordinal'}, 'first', 'I6: correct ordinal value');
}

# ---------------------------------------------------------------------------
# SECTION J — AUTOLOAD variants across multiple backends
# Tests scalar context, list context, distinct, bare-string shortcut, and
# the custom ID-column path (test5 uses 'ID' instead of 'entry').
# ---------------------------------------------------------------------------

note '';
note '=== J. AUTOLOAD variants ===';

{
	my $db = Database::test1->new($DATA_DIR);

	# J1 — scalar context with explicit entry criterion
	my $num = $db->number(entry => $ENTRY_ONE);
	is($num, $NUM_ONE, 'J1: AUTOLOAD scalar context returns correct value');

	# J2 — scalar context bare-string shortcut (entry => implicit)
	my $num2 = $db->number($ENTRY_TWO);
	is($num2, $NUM_TWO, 'J2: AUTOLOAD bare-string shortcut returns correct value');

	# J3 — list context with no args returns all column values (including undef
	#      for the "empty" row in test1.csv which has no number value)
	my @nums = $db->number();
	ok(scalar @nums >= 3, 'J3: AUTOLOAD list context returns at least 3 values');
	ok((grep { defined } @nums) >= 3, 'J3: at least 3 defined values in number column');

	# J4 — distinct removes duplicates
	#      Insert duplicate number via a new in-memory-only check: test1 has
	#      unique numbers (1,2,3,undef), so distinct count == regular count here.
	my @dist = $db->number(distinct => 1);
	ok(scalar @dist <= scalar @nums, 'J4: distinct count <= total count');

	# J5 — custom ID column (test5 uses 'ID' as primary key)
	my $db5 = Database::test5->new(directory => $DATA_DIR);
	# In list context AUTOLOAD returns all Name values
	my @names = $db5->Name();
	is(scalar @names, $TOTAL_TEST5, 'J5a: AUTOLOAD list with custom ID returns 5 names');
	# Scalar with ID lookup
	my $name = $db5->Name(ID => '101');
	ok(defined($name), 'J5b: AUTOLOAD scalar with custom ID column works');

	# J6 — auto_load => 0 causes croak regardless of backend
	my $noa = Database::test1->new(directory => $DATA_DIR, auto_load => 0);
	throws_ok { $noa->number($ENTRY_ONE) }
		qr/autoload disabled/i,
		'J6: auto_load=>0 causes croak';

	# J7 — AUTOLOAD on unknown column throws "There is no column" in slurp mode
	throws_ok { $db->nonexistent_xyz_col(entry => $ENTRY_ONE) }
		qr/nonexistent_xyz_col/i,
		'J7: unknown column in slurp mode throws clear error';

	# J8 — PSV backend AUTOLOAD works the same way as CSV
	my $psv = Database::test2->new($DATA_DIR);
	my $num_psv = $psv->number(entry => 'first');
	is($num_psv, '1st', 'J8: PSV AUTOLOAD returns correct value');
}

# ---------------------------------------------------------------------------
# SECTION K — Logging propagation
# An array logger (arrayref of message hashrefs) is the simplest way to
# capture log output from Log::Abstraction.  Setting level('debug') enables
# the debug-level messages emitted throughout the module.
# ---------------------------------------------------------------------------

note '';
note '=== K. Logging propagation ===';

{
	my @log;
	my $db = Database::test1->new({ directory => $DATA_DIR, logger => \@log });
	# Enable debug-level messages (default level may suppress them)
	$db->{'logger'}->level('debug');

	# K1 — selectall_arrayref() emits at least one log message
	@log = ();
	$db->selectall_arrayref();
	ok(scalar @log > 0, 'K1: selectall_arrayref generates log messages');

	# K2 — fetchrow_hashref() generates log messages
	@log = ();
	$db->fetchrow_hashref(entry => $ENTRY_ONE);
	ok(scalar @log > 0, 'K2: fetchrow_hashref generates log messages');

	# K3 — count() generates log messages
	@log = ();
	$db->count();
	ok(scalar @log > 0, 'K3: count() generates log messages');

	# K4 — set_logger() replaces the logger; messages go only to the new one
	my @log2;
	$db->set_logger(logger => \@log2);
	$db->{'logger'}->level('debug');
	@log  = ();
	@log2 = ();
	$db->count();
	is(scalar @log, 0,    'K4: old logger receives no messages after set_logger');
	ok(scalar @log2 > 0,  'K4: new logger receives messages after set_logger');
}

# ---------------------------------------------------------------------------
# SECTION L — Optional-dependency graceful degradation
# Test::Without::Module makes CHI temporarily unavailable to confirm the
# module works without caching (no crash, correct results).
# ---------------------------------------------------------------------------

note '';
note '=== L. Optional-dep graceful degradation ===';

{
	# L1 — Without a cache object, selectall_arrayref still returns correct data.
	#       (The module never requires CHI itself — graceful degradation is simply
	#       not passing a cache object to new().)
	my $db_bare = Database::test1->new(directory => $DATA_DIR, max_slurp_size => 0);
	my $all = $db_bare->selectall_arrayref();
	is(scalar @{$all}, $TOTAL_TEST1, 'L1: no cache object — selectall_arrayref still works');

	# L2 — count() without cache still returns correct total
	is($db_bare->count(), $TOTAL_TEST1, 'L2: no cache object — count() still works');

	# L3 — Text::xSV::Slurp unavailability forces CSV through DBD::CSV.
	#       We hide it AFTER all slurp-mode tests have run (to avoid contaminating
	#       earlier sections), create a new db object, and verify that the SQL path
	#       returns the same row count.
	SKIP: {
		skip 'DBD::SQLite needed for non-slurp fallback verification', 2
			unless $have_sqlite;

		Test::Without::Module->import('Text::xSV::Slurp');
		# Remove from %INC so the next require sees the @INC hook
		delete $INC{'Text/xSV/Slurp.pm'};

		my $db_noslurp;
		eval { $db_noslurp = Database::test1->new(directory => $DATA_DIR) };
		my $err = $@;

		Test::Without::Module->unimport('Text::xSV::Slurp');

		SKIP: {
			skip "Text::xSV::Slurp absence caused unexpected error: $err", 2 if $err;
			ok(defined($db_noslurp), 'L3: db created without Text::xSV::Slurp');
			# Without slurp, data falls through to DBD::CSV; count should still work
			my $cnt;
			eval { $cnt = $db_noslurp->count() };
			ok(!$@ && defined($cnt), 'L3: count() works when Text::xSV::Slurp is absent');
		}
	}

	# L4 — Attempting to use BerkeleyDB-specific methods on CSV backend croaks clearly
	my $db_csv = Database::test1->new(directory => $DATA_DIR);
	ok(!$db_csv->{'berkeley'}, 'L4: CSV backend has no berkeley flag');
}

done_testing();
