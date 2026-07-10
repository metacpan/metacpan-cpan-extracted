# Comprehensive BerkeleyDB backend tests for Database::Abstraction.
#
# Verifies that:
#  - The keyed BerkeleyDB fast-paths work correctly.
#  - All relational methods (selectall_*, count, execute) croak with clear messages.
#  - columns() and schema() return the fixed BerkeleyDB schema.
#  - AUTOLOAD works in scalar and list context and returns undef for missing keys.
#  - Recent changes (no_entry slurp storage, AUTOLOAD wantarray/ARRAY fix) do not
#    affect BerkeleyDB, which exits early via its own `if($self->{'berkeley'})` guards.

use strict;
use warnings;

use Fcntl;
use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;

use Test::Needs 'DB_File';

BEGIN {
	package Database::Test;
	use base 'Database::Abstraction';
}

# ---------------------------------------------------------------------------
# Fixture: create a BerkeleyDB hash with three entries
# ---------------------------------------------------------------------------
my $dir = tempdir(CLEANUP => 1);
my $dbfile = File::Spec->catfile($dir, 'Test.db');

tie my %db, 'DB_File', $dbfile, O_CREAT|O_RDWR, 0644, $DB_File::DB_HASH
	or die "Cannot tie $dbfile: $!";
%db = (
	k1 => 'v1',
	k2 => 'v2',
	k3 => 'v3',
);
untie %db;

ok(-e $dbfile, 'BerkeleyDB file was created');

my $dao = new_ok('Database::Test' => [ directory => $dir ]);

# ---------------------------------------------------------------------------
# fetchrow_hashref — core key-value retrieval
# ---------------------------------------------------------------------------

my $row = $dao->fetchrow_hashref(entry => 'k1');
is_deeply($row, { entry => 'v1' }, 'fetchrow_hashref(entry =>...) returns {entry => value}');

my $row2 = $dao->fetchrow_hashref('k1');
is_deeply($row2, { entry => 'v1' }, 'fetchrow_hashref("key") bare-string shortcut works');

my $missing = $dao->fetchrow_hashref(entry => 'nokey');
is_deeply($missing, { entry => undef }, 'fetchrow_hashref returns {entry => undef} for missing key');

# fetchrow_hashref with no recognised pattern (multiple params) croaks with BerkeleyDB message.
# A single 'entry' param is the only pattern BerkeleyDB handles; anything else
# falls through to the "meaningless on a NoSQL database" croak.
throws_ok { $dao->fetchrow_hashref(foo => 'a', bar => 'b') }
	qr/meaningless on a NoSQL database/i,
	'fetchrow_hashref() with non-entry params croaks for BerkeleyDB';

# ---------------------------------------------------------------------------
# selectall_arrayref / selectall_array / count — now work via in-memory scan
# ---------------------------------------------------------------------------

my $all = $dao->selectall_arrayref();
is(ref($all), 'ARRAY', 'selectall_arrayref() returns an arrayref');
is(scalar @{$all}, 3, 'selectall_arrayref() returns all 3 rows');
my %by_entry = map { $_->{'entry'} => $_->{'value'} } @{$all};
is($by_entry{'k1'}, 'v1', 'selectall_arrayref row: k1 => v1');
is($by_entry{'k2'}, 'v2', 'selectall_arrayref row: k2 => v2');

# selectall_arrayref with scalar criteria
my $k1_rows = $dao->selectall_arrayref(entry => 'k1');
is(scalar @{$k1_rows}, 1,    'selectall_arrayref(entry=>...) returns 1 matching row');
is($k1_rows->[0]{'value'}, 'v1', 'selectall_arrayref criteria result has correct value');

# selectall_arrayref with operator-hash criteria (feature 4: operator-hash criteria)
my $ne_rows = $dao->selectall_arrayref(entry => { '!=' => 'k1' });
is(scalar @{$ne_rows}, 2, 'selectall_arrayref with operator criteria != returns 2 rows');

# selectall_arrayref with join param → croak (feature 5: joins unsupported)
throws_ok { $dao->selectall_arrayref(join => { table => 'other', on => 'a=b' }) }
	qr/BerkeleyDB does not support JOINs/i,
	'selectall_arrayref() with join croaks for BerkeleyDB';

# selectall_array
my @arr = $dao->selectall_array();
is(scalar @arr, 3, 'selectall_array() returns 3 rows in list context');

# selectall_hash is an alias for selectall_array
my @hash_arr = $dao->selectall_hash();
is(scalar @hash_arr, 3, 'selectall_hash() alias also returns 3 rows');

# count
is($dao->count(), 3, 'count() returns total row count');
is($dao->count(entry => 'k1'), 1, 'count(entry=>...) returns 1 for known key');
is($dao->count(entry => 'no_such'), 0, 'count(entry=>...) returns 0 for unknown key');
is($dao->count(value => 'v2'), 1, 'count(value=>...) filters by value column');

# execute() remains meaningless (it requires a SQL query string)
throws_ok { $dao->execute(query => 'SELECT 1') }
	qr/meaningless on a NoSQL database/i,
	'execute() croaks for BerkeleyDB (SQL not applicable)';

# ---------------------------------------------------------------------------
# Query builder (feature 6: chained Query builder now works for BerkeleyDB)
# ---------------------------------------------------------------------------

my $q_all = $dao->query()->all();
is(ref($q_all), 'ARRAY', 'query()->all() returns arrayref for BerkeleyDB');
is(scalar @{$q_all}, 3, 'query()->all() returns all 3 rows');

my $q_where = $dao->query()->where(entry => 'k2')->all();
is(scalar @{$q_where}, 1, 'query()->where()->all() filters correctly');
is($q_where->[0]{'value'}, 'v2', 'query()->where()->all() correct value');

my $q_count = $dao->query()->where(value => 'v3')->count();
is($q_count, 1, 'query()->where()->count() returns 1 for matching value');

my $q_first = $dao->query()->where(entry => 'k1')->first();
is(ref($q_first), 'HASH', 'query()->where()->first() returns hashref');
is($q_first->{'value'}, 'v1', 'query()->where()->first() correct value');

# order_by + limit + offset applied in Perl
my $q_sorted = $dao->query()->order_by('entry')->all();
is($q_sorted->[0]{'entry'}, 'k1', 'query()->order_by() sorts ascending correctly');
is($q_sorted->[-1]{'entry'}, 'k3', 'query()->order_by() last entry is k3');

my $q_limited = $dao->query()->order_by('entry')->limit(2)->all();
is(scalar @{$q_limited}, 2, 'query()->limit(2) returns 2 rows');
is($q_limited->[0]{'entry'}, 'k1', 'query()->limit(2) first entry is k1');

my $q_offset = $dao->query()->order_by('entry')->offset(1)->limit(1)->all();
is($q_offset->[0]{'entry'}, 'k2', 'query()->offset(1)->limit(1) returns second entry');

# query()->join() must croak for BerkeleyDB
throws_ok { $dao->query()->join({table=>'t', on=>'a=b'})->all() }
	qr/JOINs is not supported on BerkeleyDB/i,
	'query()->join()->all() croaks for BerkeleyDB';

# ---------------------------------------------------------------------------
# columns() — fixed schema for BerkeleyDB
# ---------------------------------------------------------------------------

my $cols = $dao->columns();
is(ref($cols), 'ARRAY', 'columns() returns an arrayref');
is_deeply([sort @{$cols}], ['entry', 'value'], 'columns() returns [entry, value] for BerkeleyDB');

# Cached second call returns same ref
is($dao->columns(), $cols, 'columns() is cached: same ref on second call');

# ---------------------------------------------------------------------------
# schema() — fixed introspection for BerkeleyDB
# ---------------------------------------------------------------------------

my $schema = $dao->schema();
is(ref($schema), 'HASH', 'schema() returns a hashref');
ok(exists $schema->{'entry'}, 'schema has entry column');
ok(exists $schema->{'value'}, 'schema has value column');
is($schema->{'entry'}{'pk'}, 1, 'entry column is primary key');
is($schema->{'entry'}{'nullable'}, 0, 'entry column is not nullable');
is($schema->{'value'}{'pk'}, 0, 'value column is not a primary key');
is($schema->{'value'}{'nullable'}, 1, 'value column is nullable');

# Cached second call returns same ref
is($dao->schema(), $schema, 'schema() is cached: same ref on second call');

# ---------------------------------------------------------------------------
# AUTOLOAD — scalar context
# ---------------------------------------------------------------------------

# The BerkeleyDB AUTOLOAD path ignores the column name and returns the stored
# value for the given key.  Both 'entry' and 'value' lookups return the same
# thing because BerkeleyDB stores a single value per key.
is($dao->entry('k2'), 'v2', 'AUTOLOAD entry("k2") returns stored value');
is($dao->value('k2'), 'v2', 'AUTOLOAD value("k2") also returns stored value (key-value agnosticism)');
is($dao->entry('k3'), 'v3', 'AUTOLOAD entry("k3") returns stored value');

# Missing key returns undef without dying
is($dao->entry('no_such_key'), undef, 'AUTOLOAD returns undef for missing key');

# Named-param form
is($dao->entry(entry => 'k1'), 'v1', 'AUTOLOAD with named param (entry =>...) returns stored value');

# ---------------------------------------------------------------------------
# AUTOLOAD — list context
# BerkeleyDB exits before the wantarray/ARRAY change (lines 1763-1770), so
# list context still works (returns the single looked-up value in a 1-element list).
# ---------------------------------------------------------------------------

my @vals = $dao->entry('k2');
is(scalar @vals, 1, 'AUTOLOAD in list context returns a 1-element list for BerkeleyDB');
is($vals[0], 'v2', 'AUTOLOAD list context value is correct');

# ---------------------------------------------------------------------------
# DESTROY — object cleanup does not crash, and a new object can be created
# ---------------------------------------------------------------------------

{
	my $local_dao = Database::Test->new(directory => $dir);
	ok($local_dao->fetchrow_hashref(entry => 'k1'), 'fetchrow_hashref works on second object');
}	# DESTROY fires here

my $dao2 = new_ok('Database::Test' => [ directory => $dir ], 'new object after DESTROY');
is($dao2->fetchrow_hashref(entry => 'k1')->{entry}, 'v1',
	'fetchrow_hashref still works after a previous object was destroyed');

done_testing();
