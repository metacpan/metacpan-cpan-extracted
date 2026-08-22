use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
	eval { require DBD::SQLite; require Database::Abstraction };
	plan skip_all => 'DBD::SQLite and Database::Abstraction required' if $@;
	plan tests => 8;
}

use lib 't/lib';
use DBI;
use File::Temp qw(tempdir);
use Database::djcust;
use Database::djloyalty;
use Database::Join;

# ---------------------------------------------------------------------------
# Build minimal SQLite fixtures
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);

my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/djcust.sql", '', '',
	{ RaiseError => 1, PrintError => 0 });
$dbh->do('CREATE TABLE djcust (entry TEXT PRIMARY KEY, name TEXT)');
$dbh->do(q{INSERT INTO djcust VALUES ('c001','Alice')});
$dbh->disconnect;

$dbh = DBI->connect("dbi:SQLite:dbname=$dir/djloyalty.sql", '', '',
	{ RaiseError => 1, PrintError => 0 });
$dbh->do('CREATE TABLE djloyalty (entry TEXT PRIMARY KEY, tier TEXT)');
$dbh->do(q{INSERT INTO djloyalty VALUES ('c001','gold')});
$dbh->disconnect;

my $cust    = Database::djcust->new(directory    => $dir);
my $loyalty = Database::djloyalty->new(directory => $dir);

# ---------------------------------------------------------------------------
# Happy path
# ---------------------------------------------------------------------------

my $join;
lives_ok {
	$join = Database::Join->new(databases => [ $cust, $loyalty ]);
} 'new() with valid Database::Abstraction objects succeeds';

isa_ok($join, 'Database::Join', 'new() returns a Database::Join');

is($join->{_join_col},  'entry', 'default join_column is "entry"');
is($join->{_join_type}, 'left',  'default join_type is "left"');

# ---------------------------------------------------------------------------
# Error paths
# ---------------------------------------------------------------------------

throws_ok {
	Database::Join->new(databases => []);
} qr/At least one/i, 'empty databases arrayref is rejected';

throws_ok {
	Database::Join->new(databases => ['not an object']);
} qr/not a Database::Abstraction/i, 'non-object element is rejected';

throws_ok {
	Database::Join->new(databases => [ $cust, $loyalty ], join_type => 'bad');
} qr/must be one of/i, 'invalid join_type is rejected';

# ---------------------------------------------------------------------------
# columns() merges correctly at construction
# ---------------------------------------------------------------------------

my @cols = sort @{ $join->columns() };
is_deeply(\@cols, [qw(entry name tier)], 'columns() returns union of all databases');

# Release DBI connections before File::Temp's cleanup END block fires.
# On Windows, SQLite keeps files locked until all handles are closed; file-scoped
# 'my' variables outlive END blocks, so we undef explicitly (joins first).
undef $_ for ($join, $cust, $loyalty);
