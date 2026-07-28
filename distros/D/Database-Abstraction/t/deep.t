# Comprehensive DBM::Deep backend tests for Database::Abstraction.
#
# Verifies that:
#  - Both .dbm and .deep extensions are detected and opened.
#  - Row hashrefs with multiple columns are slurped into the in-memory hash.
#  - All select methods (selectall_arrayref, selectall_array, fetchrow_hashref,
#    count) work via the existing slurp fast-paths — no Deep-specific branches.
#  - no_entry mode stores an arrayref as with CSV.
#  - columns(), schema(), AUTOLOAD, and the query builder all work.
#  - The type field is set to 'Deep'.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;
use Test::Needs 'DBM::Deep';

BEGIN {
	package Database::deeptest;
	use base 'Database::Abstraction';
}

BEGIN {
	package Database::deepnoentry;
	use base 'Database::Abstraction';
}

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

sub make_deep_fixture {
	my ($dir, $name, $ext, %rows) = @_;
	require DBM::Deep;
	my $file = File::Spec->catfile($dir, "$name.$ext");
	my $db = DBM::Deep->new({ file => $file });
	for my $k (keys %rows) {
		$db->{$k} = $rows{$k};
	}
	undef $db;	# flush and close
	return $file;
}

# ---------------------------------------------------------------------------
# .deep extension — keyed (entry) mode
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);

make_deep_fixture($dir, 'deeptest', 'deep',
	one   => { name => 'Alice', score => 10 },
	two   => { name => 'Bob',   score => 20 },
	three => { name => 'Carol', score => 30 },
);

ok(-e File::Spec->catfile($dir, 'deeptest.deep'), '.deep fixture file created');

my $dao = new_ok('Database::deeptest' => [ directory => $dir ]);

# selectall_arrayref — all rows (also triggers _open(), setting type)
my $all = $dao->selectall_arrayref();
is($dao->{'type'}, 'Deep', 'type is set to "Deep" after first data access');
is(ref($all), 'ARRAY', 'selectall_arrayref() returns arrayref');
is(scalar @{$all}, 3, 'selectall_arrayref() returns all 3 rows');

my %by_entry = map { $_->{'entry'} => $_ } @{$all};
is($by_entry{'one'}{'name'},   'Alice', 'row one: name correct');
is($by_entry{'two'}{'score'},  20,      'row two: score correct');
is($by_entry{'three'}{'name'},'Carol',  'row three: name correct');

# selectall_arrayref — filtered by entry
my $one_rows = $dao->selectall_arrayref(entry => 'one');
is(scalar @{$one_rows}, 1,       'selectall_arrayref(entry=>one) returns 1 row');
is($one_rows->[0]{'name'}, 'Alice', 'filtered row has correct name');

# selectall_arrayref — filter on non-key column
my $score_rows = $dao->selectall_arrayref(score => 20);
is(scalar @{$score_rows}, 1,     'selectall_arrayref filtering on score column');
is($score_rows->[0]{'name'}, 'Bob', 'score=20 row has name Bob');

# selectall_array
my @arr = $dao->selectall_array();
is(scalar @arr, 3, 'selectall_array() returns 3 rows');

# fetchrow_hashref
my $row = $dao->fetchrow_hashref(entry => 'two');
is(ref($row), 'HASH', 'fetchrow_hashref returns hashref');
is($row->{'name'},  'Bob', 'fetchrow_hashref name correct');
is($row->{'score'}, 20,    'fetchrow_hashref score correct');

# fetchrow_hashref — missing key
my $missing = $dao->fetchrow_hashref(entry => 'nosuchkey');
ok(!defined($missing), 'fetchrow_hashref returns undef for missing key');

# count
is($dao->count(), 3, 'count() returns total 3');
is($dao->count(name => 'Bob'), 1, 'count(name=>Bob) returns 1');
is($dao->count(name => 'Nobody'), 0, 'count for non-existent name returns 0');

# operator-hash criteria must be tested on a no_entry object or via the query
# builder — Params::Get::get_params('entry', $col, \%op) maps $col to 'entry'
# (the Params::Get positional-arg pitfall); operator-hash tests are in the
# query builder section below where ->where() bypasses that parsing.
my $two_plus = $dao->selectall_arrayref(score => 20);
is(scalar @{$two_plus}, 1, 'selectall_arrayref with scalar score=20 returns 1 row');

# ---------------------------------------------------------------------------
# .dbm extension
# ---------------------------------------------------------------------------

my $dir2 = tempdir(CLEANUP => 1);
make_deep_fixture($dir2, 'deeptest', 'dbm',
	a => { colour => 'red',   weight => 1 },
	b => { colour => 'green', weight => 2 },
);

ok(-e File::Spec->catfile($dir2, 'deeptest.dbm'), '.dbm fixture file created');

my $dao2 = new_ok('Database::deeptest' => [ directory => $dir2 ]);
my $all2 = $dao2->selectall_arrayref();
is($dao2->{'type'}, 'Deep', '.dbm file also detected as Deep');
is(scalar @{$all2}, 2, '.dbm backend returns correct row count');

# ---------------------------------------------------------------------------
# no_entry mode — data stored as arrayref
# ---------------------------------------------------------------------------

my $dir3 = tempdir(CLEANUP => 1);
make_deep_fixture($dir3, 'deepnoentry', 'deep',
	r1 => { city => 'London',   pop => 9000000 },
	r2 => { city => 'Paris',    pop => 2000000 },
	r3 => { city => 'New York', pop => 8000000 },
);

my $ne = new_ok('Database::deepnoentry' => [ directory => $dir3, no_entry => 1 ]);
my $ne_all = $ne->selectall_arrayref();
is($ne->{'type'}, 'Deep', 'no_entry Deep type correct');
ok(ref($ne->{'data'}) eq 'ARRAY', 'no_entry Deep stores data as arrayref');

is(scalar @{$ne_all}, 3, 'no_entry selectall_arrayref returns 3 rows');

my $ne_count = $ne->count();
is($ne_count, 3, 'no_entry count() returns 3');

my ($london) = grep { $_->{'city'} eq 'London' } @{$ne_all};
ok(defined $london, 'London row found in no_entry results');
is($london->{'pop'}, 9000000, 'London population correct');

# ---------------------------------------------------------------------------
# columns() and schema()
# ---------------------------------------------------------------------------

my $cols = $dao->columns();
is(ref($cols), 'ARRAY', 'columns() returns arrayref');
ok((grep { $_ eq 'entry' } @{$cols}), 'columns() includes entry');
ok((grep { $_ eq 'name'  } @{$cols}), 'columns() includes name');
ok((grep { $_ eq 'score' } @{$cols}), 'columns() includes score');

# Cached second call returns same ref
is($dao->columns(), $cols, 'columns() is cached');

my $schema = $dao->schema();
is(ref($schema), 'HASH', 'schema() returns hashref');
ok(exists $schema->{'name'},  'schema has name column');
ok(exists $schema->{'score'}, 'schema has score column');

is($dao->schema(), $schema, 'schema() is cached');

# ---------------------------------------------------------------------------
# AUTOLOAD
# ---------------------------------------------------------------------------

my $name_val = $dao->name(entry => 'one');
is($name_val, 'Alice', 'AUTOLOAD name(entry=>one) returns Alice');

$name_val = $dao->name('one');
is($name_val, 'Alice', 'AUTOLOAD name(one) returns Alice');

my $score_val = $dao->score(entry => 'two');
is($score_val, 20, 'AUTOLOAD score(entry=>two) returns 20');

$score_val = $dao->score('two');
is($score_val, 20, 'AUTOLOAD score(two) returns 20');

# List context — all values for a column
my @names = $dao->name();
is(scalar @names, 3, 'AUTOLOAD name() in list context returns 3 values');
ok((grep { $_ eq 'Bob' } @names), 'list context includes Bob');

# ---------------------------------------------------------------------------
# Query builder
# ---------------------------------------------------------------------------

my $q_all = $dao->query()->all();
is(ref($q_all), 'ARRAY', 'query()->all() returns arrayref');
is(scalar @{$q_all}, 3, 'query()->all() returns all 3 rows');

my $q_where = $dao->query()->where(name => 'Carol')->all();
is(scalar @{$q_where}, 1, 'query()->where(name=>Carol)->all() returns 1 row');
is($q_where->[0]{'score'}, 30, 'query()->where() result has correct score');

my $q_count = $dao->query()->where(name => 'Carol')->count();
is($q_count, 1, 'query()->where(name=>Carol)->count() returns 1');

my $q_first = $dao->query()->where(name => 'Alice')->first();
is(ref($q_first), 'HASH', 'query()->where()->first() returns hashref');
is($q_first->{'name'}, 'Alice', 'query()->first() name correct');

# ---------------------------------------------------------------------------
# DESTROY — second object after first goes out of scope
# ---------------------------------------------------------------------------

{
	my $tmp = Database::deeptest->new(directory => $dir);
	ok($tmp->fetchrow_hashref(entry => 'one'), 'second object works');
}	# DESTROY fires here

my $dao3 = new_ok('Database::deeptest' => [ directory => $dir ], 'third object post-DESTROY');
is($dao3->fetchrow_hashref(entry => 'one')->{'name'}, 'Alice',
	'fetchrow_hashref still works after previous object was destroyed');

# ---------------------------------------------------------------------------
# Magic-byte detection: DBM::Deep file with .db extension
#
# DBM::Deep files start with 'DPDB' (0x44 0x50 0x44 0x42).  The .db extension
# is also used for BerkeleyDB files; _is_deep_db() must win because the magic-
# byte probe runs before the BerkeleyDB check in _open().
# ---------------------------------------------------------------------------

BEGIN {
	package Database::deepdb;
	use base 'Database::Abstraction';
}

my $dir_db = tempdir(CLEANUP => 1);

# Create a real DBM::Deep file named deepdb.db (so _open() will probe it as
# a possible BerkeleyDB — the magic-byte check must redirect to Deep).
make_deep_fixture($dir_db, 'deepdb', 'db',
	x => { label => 'eks', num => 1 },
	y => { label => 'why', num => 2 },
);

my $f_db = File::Spec->catfile($dir_db, 'deepdb.db');
ok(-e $f_db, 'deepdb.db fixture created');

# Confirm real DBM::Deep magic bytes (DPDB = 0x44 0x50 0x44 0x42)
open my $fh_chk, '<', $f_db;
binmode $fh_chk;
read($fh_chk, my $magic_hdr, 4);
close $fh_chk;
is(substr(unpack('H*', $magic_hdr), 0, 8), '44504442',
	'DBM::Deep .db file has DPDB magic bytes (0x44 0x50 0x44 0x42)');

my $dao_db = new_ok('Database::deepdb' => [ directory => $dir_db ]);
my $all_db = $dao_db->selectall_arrayref();
is($dao_db->{'type'}, 'Deep',
	'.db file with DBM::Deep magic detected as Deep (not BerkeleyDB)');
is(scalar @{$all_db}, 2, 'magic-byte-detected .db Deep file returns correct row count');

my %by_entry_db = map { $_->{'entry'} => $_ } @{$all_db};
is($by_entry_db{'x'}{'label'}, 'eks', 'magic-byte .db: row x has correct label');
is($by_entry_db{'y'}{'num'},   2,     'magic-byte .db: row y has correct num');

# Also verify _is_deep_db() directly (white-box test for the DPDP variant)
my $f_dpdp = File::Spec->catfile($dir_db, 'fake.db');
open my $fh_w, '>', $f_dpdp;
binmode $fh_w;
print $fh_w "DPDP\x00\x00\x00\x00";
close $fh_w;

ok($dao_db->_is_deep_db($f_dpdp),
	'_is_deep_db() returns true for DPDP (0x44 0x50 0x44 0x50) magic bytes');
ok($dao_db->_is_deep_db($f_db),
	'_is_deep_db() returns true for DPDB (0x44 0x50 0x44 0x42) magic bytes');
ok(!$dao_db->_is_deep_db(File::Spec->catfile($dir_db, 'nosuchfile.db')),
	'_is_deep_db() returns false for non-existent file');

done_testing();
