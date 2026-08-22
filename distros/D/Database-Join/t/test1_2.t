#!perl -w

use strict;
use FindBin qw($Bin);

use Test::Most tests => 31;
use Test::NoWarnings;

BEGIN {
	eval { require DBD::SQLite; require Database::Abstraction };
	if ($@) {
		require Test::More;
		Test::More::plan(skip_all => 'DBD::SQLite and Database::Abstraction required');
	}
}

use lib 't/lib';
use DBI;
use File::Temp qw(tempdir);
use Database::test1;
use Database::test2;
use Database::Join;

# ---------------------------------------------------------------------------
# Fixtures
#
#   test1 (SQLite): entry (city) | statecode
#       Richmond      VA
#       Silver Spring MD
#       Laurel        MD
#       Leesburg      VA   <- same city name as below ...
#       Leesburg      FL   <- ... in a different state
#
#   Note: no PRIMARY KEY on test1.entry so duplicate city names are allowed.
#
#   test2 (SQLite): entry (statecode) | state
#       MD  Maryland
#       VA  Virginia
#       FL  Florida
#
#  The join key is test1.statecode = test2.entry.
#  join_column => 'statecode', join_map => { 1 => 'entry' }.
#
#  Expected result (5 rows, sorted by statecode then by city name):
#    { statecode=>'FL', entry=>'Leesburg',      state=>'Florida'  }
#    { statecode=>'MD', entry=>'Laurel',         state=>'Maryland' }
#    { statecode=>'MD', entry=>'Silver Spring',  state=>'Maryland' }
#    { statecode=>'VA', entry=>'Leesburg',       state=>'Virginia' }
#    { statecode=>'VA', entry=>'Richmond',       state=>'Virginia' }
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/test1.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	# No PRIMARY KEY → allows two rows with entry='Leesburg' (VA and FL)
	$dbh->do('CREATE TABLE test1 (entry TEXT, statecode TEXT)');
	$dbh->do(q{INSERT INTO test1 VALUES ('Richmond',     'VA')});
	$dbh->do(q{INSERT INTO test1 VALUES ('Silver Spring','MD')});
	$dbh->do(q{INSERT INTO test1 VALUES ('Laurel',       'MD')});
	$dbh->do(q{INSERT INTO test1 VALUES ('Leesburg',     'VA')});
	$dbh->do(q{INSERT INTO test1 VALUES ('Leesburg',     'FL')});
	$dbh->disconnect;
}

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/test2.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE test2 (entry TEXT PRIMARY KEY, state TEXT)');
	$dbh->do(q{INSERT INTO test2 VALUES ('MD','Maryland')});
	$dbh->do(q{INSERT INTO test2 VALUES ('VA','Virginia')});
	$dbh->do(q{INSERT INTO test2 VALUES ('FL','Florida')});
	$dbh->disconnect;
}

my $test1 = new_ok('Database::test1' => [$dir]);
my $test2 = new_ok('Database::test2' => [$dir]);

my $joined;
lives_ok {
	$joined = Database::Join->new(
		databases   => [ $test1, $test2 ],
		join_column => 'statecode',
		join_map    => { 1 => 'entry' },
	);
} 'Database::Join->new with join_map lives';

isa_ok($joined, 'Database::Join', 'result is a Database::Join');

# columns(): test2's local 'entry' (join alias) must not appear as a separate
# column; only the canonical 'statecode' is exposed.
is_deeply(
	$joined->columns(),
	[qw(entry state statecode)],
	'columns() has entry (from test1), state (test2), statecode (join key)'
);

my $rows = $joined->selectall_arrayref();

# 5 city rows total (Leesburg appears twice — once VA, once FL)
is(scalar @{$rows}, 5, 'five merged rows — Leesburg counted twice');

# Results are sorted by statecode (FL < MD < VA); within each statecode
# the secondary sort is alphabetical by entry (city name).
is($rows->[0]{statecode}, 'FL',        'row 0: statecode FL');
is($rows->[0]{state},     'Florida',   'row 0: state Florida');
is($rows->[0]{entry},     'Leesburg',  'row 0: city Leesburg (FL)');

is($rows->[1]{statecode}, 'MD',        'row 1: statecode MD');
is($rows->[1]{state},     'Maryland',  'row 1: state Maryland');
is($rows->[1]{entry},     'Laurel',    'row 1: city Laurel');

is($rows->[2]{statecode}, 'MD',        'row 2: statecode MD');
is($rows->[2]{state},     'Maryland',  'row 2: state Maryland');
is($rows->[2]{entry},     'Silver Spring', 'row 2: city Silver Spring');

is($rows->[3]{statecode}, 'VA',        'row 3: statecode VA');
is($rows->[3]{state},     'Virginia',  'row 3: state Virginia');
is($rows->[3]{entry},     'Leesburg',  'row 3: city Leesburg (VA)');

is($rows->[4]{statecode}, 'VA',        'row 4: statecode VA');
is($rows->[4]{state},     'Virginia',  'row 4: state Virginia');
is($rows->[4]{entry},     'Richmond',  'row 4: city Richmond');

# count()
is($joined->count(),                    5, 'count() without criteria is 5');
is($joined->count(state => 'Virginia'), 2, 'count() on secondary column: 2 VA cities');

# Criteria on the canonical join column
my $fl_rows = $joined->selectall_arrayref(statecode => 'FL');
is(scalar @{$fl_rows},     1,         'selectall on statecode=FL narrows to 1 row');
is($fl_rows->[0]{state},   'Florida', 'FL row has correct state');

# Criteria on a column owned by test2
my $md_rows = $joined->selectall_arrayref(state => 'Maryland');
is(scalar @{$md_rows},     2,         'selectall on state=Maryland returns both MD cities');

# AUTOLOAD with join_map — scalar context: single result
is($joined->state('Richmond'), 'Virginia', 'AUTOLOAD scalar: state for Richmond is Virginia');

# AUTOLOAD with join_map — list context: all matching rows
# Leesburg exists in both VA and FL so state() returns two values in list context.
my @leesburg_states = sort $joined->state('Leesburg');
is_deeply(\@leesburg_states, ['Florida', 'Virginia'],
	'AUTOLOAD list: state() for Leesburg returns Florida and Virginia');

# ---------------------------------------------------------------------------
# add_database with join_column — equivalent to join_map in the constructor
# ---------------------------------------------------------------------------

my $joined2 = Database::Join->new(
	databases   => [ $test1 ],
	join_column => 'statecode',
);
lives_ok {
	$joined2->add_database($test2, join_column => 'entry');
} 'add_database with join_column lives';

is(scalar @{ $joined2->selectall_arrayref() }, 5,
	'add_database(join_column) also returns 5 rows');

# Release DBI connections before File::Temp's cleanup END block fires.
# On Windows, SQLite keeps files locked until all handles are closed; file-scoped
# 'my' variables outlive END blocks, so we undef explicitly (joins first).
undef $_ for ($joined, $joined2, $test1, $test2);
