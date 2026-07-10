#!perl -w

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;
use Test::NoWarnings;

eval { require DBI; require DBD::SQLite };
if ($@) {
	plan skip_all => 'DBD::SQLite not available';
} else {
	plan tests => 38;
}

# ---- SQLite fixture ----

{
	package Database::qbtest;
	use base 'Database::Abstraction';
}

my $dir  = tempdir(CLEANUP => 1);
my $file = File::Spec->catfile($dir, 'qbtest.sql');
my $dsn  = "dbi:SQLite:dbname=$file";

my $setup = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
$setup->do(q{
	CREATE TABLE qbtest (
		id INTEGER PRIMARY KEY,
		name TEXT NOT NULL,
		score REAL,
		status TEXT
	)
});
# id  name   score  status
# 1   Alice  9.5    active
# 2   Bob    7.0    inactive
# 3   Carol  8.5    active
# 4   Dave   6.0    inactive
# 5   Eve   10.0    active
$setup->do(q{INSERT INTO qbtest VALUES (1,'Alice', 9.5,'active')});
$setup->do(q{INSERT INTO qbtest VALUES (2,'Bob',   7.0,'inactive')});
$setup->do(q{INSERT INTO qbtest VALUES (3,'Carol', 8.5,'active')});
$setup->do(q{INSERT INTO qbtest VALUES (4,'Dave',  6.0,'inactive')});
$setup->do(q{INSERT INTO qbtest VALUES (5,'Eve',  10.0,'active')});
$setup->disconnect();

my $db = Database::qbtest->new(dsn => $dsn, no_entry => 1);

# ---- Part A: operator-hash criteria ----

# '>' operator — Alice(9.5), Carol(8.5), Eve(10.0) = 3
my $rows = $db->selectall_arrayref(score => { '>' => 8 });
is(scalar @{$rows}, 3, '>8 gives 3 rows');
ok((grep { $_->{name} eq 'Alice' } @{$rows}), '>8 includes Alice');
ok((grep { $_->{name} eq 'Carol' } @{$rows}), '>8 includes Carol');
ok((grep { $_->{name} eq 'Eve'   } @{$rows}), '>8 includes Eve');

# '<' operator — Dave(6.0), Bob(7.0) = 2
$rows = $db->selectall_arrayref(score => { '<' => 7.5 });
is(scalar @{$rows}, 2, '<7.5 gives 2 rows');

# '>=' operator — Eve(10.0) = 1
$rows = $db->selectall_arrayref(score => { '>=' => 10.0 });
is(scalar @{$rows}, 1, '>=10 gives 1 row');
is($rows->[0]{name}, 'Eve', '>=10 is Eve');

# '<=' operator — Dave(6.0) = 1
$rows = $db->selectall_arrayref(score => { '<=' => 6.0 });
is(scalar @{$rows}, 1, '<=6 gives 1 row');
is($rows->[0]{name}, 'Dave', '<=6 is Dave');

# '!=' operator — Bob, Dave = 2
$rows = $db->selectall_arrayref(status => { '!=' => 'active' });
is(scalar @{$rows}, 2, '!= active gives 2 rows');

# -in operator
$rows = $db->selectall_arrayref(name => { -in => ['Alice', 'Eve'] });
is(scalar @{$rows}, 2, '-in [Alice,Eve] gives 2 rows');

# -not_in operator
$rows = $db->selectall_arrayref(name => { -not_in => ['Alice', 'Eve'] });
is(scalar @{$rows}, 3, '-not_in gives 3 rows');

# -between — Bob(7.0), Carol(8.5) = 2
$rows = $db->selectall_arrayref(score => { -between => [7.0, 9.0] });
is(scalar @{$rows}, 2, '-between [7,9] gives 2 rows (Bob,Carol)');

# -like operator
$rows = $db->selectall_arrayref(name => { -like => 'A%' });
is(scalar @{$rows}, 1, '-like A% gives 1 row');
is($rows->[0]{name}, 'Alice', '-like A% is Alice');

# -not_like operator
$rows = $db->selectall_arrayref(name => { -not_like => 'A%' });
is(scalar @{$rows}, 4, '-not_like A% gives 4 rows');

# Multiple ops on one column (AND): score > 7.0 AND < 9.5 → Carol(8.5) = 1
$rows = $db->selectall_arrayref(score => { '>' => 7.0, '<' => 9.5 });
is(scalar @{$rows}, 1, 'score >7 AND <9.5 → 1 row');
is($rows->[0]{name}, 'Carol', 'score >7 AND <9.5 is Carol');

# -or grouping
$rows = $db->selectall_arrayref(
	-or => [
		{ name => 'Alice' },
		{ name => 'Eve'   },
	]
);
is(scalar @{$rows}, 2, '-or [Alice,Eve] gives 2 rows');

# -or with operator inside: active OR score<7 → Alice,Carol,Eve,Dave = 4
$rows = $db->selectall_arrayref(
	-or => [
		{ status => 'active'         },
		{ score  => { '<' => 7.0 }   },
	]
);
is(scalar @{$rows}, 4, '-or active|score<7 gives 4 rows');

# Combined plain + operator: status=active AND score>9 → Alice(9.5), Eve(10.0) = 2
$rows = $db->selectall_arrayref(status => 'active', score => { '>' => 9 });
is(scalar @{$rows}, 2, 'status=active AND score>9 gives 2 rows');

# fetchrow_hashref with operator
my $row = $db->fetchrow_hashref(score => { '>=' => 10 });
is($row->{name}, 'Eve', 'fetchrow_hashref with >= operator');

# count with operator
is($db->count(status => 'active'),         3, 'count(status=active)');
is($db->count(score  => { '>' => 8 }),     3, 'count(score>8)');

# ---- Part B: chained Query builder ----

use_ok('Database::Abstraction::Query');

my $q = $db->query();
isa_ok($q, 'Database::Abstraction::Query', 'query() returns Query object');

# all() — no criteria
my $all = $db->query->all();
is(scalar @{$all}, 5, 'query->all() returns all 5 rows');

# where + all
my $active = $db->query->where(status => 'active')->all();
is(scalar @{$active}, 3, 'query->where(status=active)->all()');

# where with operator hash
my $high = $db->query->where(score => { '>' => 9 })->all();
is(scalar @{$high}, 2, 'query->where(score>9)->all()');

# chained where (AND semantics): active AND score>9 = 2
my $act_high = $db->query->where(status => 'active')->where(score => { '>' => 9 })->all();
is(scalar @{$act_high}, 2, 'chained where AND');

# first()
my $first = $db->query->where(name => 'Bob')->first();
is($first->{name}, 'Bob', 'query->where->first()');

# count()
is($db->query->count(),                        5, 'query->count()');
is($db->query->where(status => 'active')->count(), 3, 'query->where->count()');

# order_by + limit
my $limited = $db->query->order_by('score DESC')->limit(2)->all();
is(scalar @{$limited}, 2, 'limit(2) returns 2 rows');
is($limited->[0]{name}, 'Eve', 'order_by score DESC, first is Eve');

# select specific columns
my $names = $db->query->select('name')->where(status => 'active')->all();
is(scalar @{$names}, 3, 'select(name) with where gives 3 rows');
ok(exists $names->[0]{name}, 'selected rows have name key');
