use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
	eval { require DBD::SQLite; require Database::Abstraction };
	plan skip_all => 'DBD::SQLite and Database::Abstraction required' if $@;
	plan tests => 21;
}

use lib 't/lib';
use DBI;
use File::Temp qw(tempdir);
use Database::djcust;
use Database::djloyalty;
use Database::djscore;
use Database::Join;

# ---------------------------------------------------------------------------
# Fixtures
#
#   djcust:    entry | name
#   djloyalty: entry | tier
#   djscore:   entry | score | internal
#
# The join is built with only the first two databases, then djscore is added.
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/djcust.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE djcust (entry TEXT PRIMARY KEY, name TEXT)');
	$dbh->do(q{INSERT INTO djcust VALUES ('c001','Alice')});
	$dbh->do(q{INSERT INTO djcust VALUES ('c002','Bob')});
	$dbh->disconnect;
}

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/djloyalty.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE djloyalty (entry TEXT PRIMARY KEY, tier TEXT)');
	$dbh->do(q{INSERT INTO djloyalty VALUES ('c001','gold')});
	$dbh->do(q{INSERT INTO djloyalty VALUES ('c002','silver')});
	$dbh->disconnect;
}

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/djscore.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE djscore (entry TEXT PRIMARY KEY, score INTEGER, internal TEXT)');
	$dbh->do(q{INSERT INTO djscore VALUES ('c001', 95, 'x')});
	$dbh->do(q{INSERT INTO djscore VALUES ('c002', 70, 'y')});
	$dbh->disconnect;
}

my $cust    = Database::djcust->new(directory    => $dir);
my $loyalty = Database::djloyalty->new(directory => $dir);
my $score   = Database::djscore->new(directory   => $dir);

# ---------------------------------------------------------------------------
# Baseline: two-database join before add_database
# ---------------------------------------------------------------------------

my $join = Database::Join->new(
	databases   => [ $cust, $loyalty ],
	join_column => 'entry',
);

my @cols_before = sort @{ $join->columns() };
is_deeply(\@cols_before, [qw(entry name tier)],
	'baseline: two databases have name and tier');

my $rows_before = $join->selectall_arrayref();
ok(!exists($rows_before->[0]{score}), 'score absent before add_database');

# ---------------------------------------------------------------------------
# add_database — positional form
# ---------------------------------------------------------------------------

my $ret;
lives_ok { $ret = $join->add_database($score) } 'add_database (positional) lives';
is(ref $ret, 'Database::Join', 'add_database returns $self (chainable)');

my @cols_after = sort @{ $join->columns() };
is_deeply(\@cols_after, [qw(entry internal name score tier)],
	'columns() includes new columns after add_database');

my $rows_after = $join->selectall_arrayref();
is(scalar @{$rows_after}, 2, 'row count unchanged after add_database');
is($rows_after->[0]{name},  'Alice', 'name still correct after add_database');
is($rows_after->[0]{score}, 95,      'score now present after add_database');
is($rows_after->[0]{tier},  'gold',  'tier still present after add_database');

# ---------------------------------------------------------------------------
# add_database — named form
# ---------------------------------------------------------------------------

my $join2 = Database::Join->new(databases => [$cust, $loyalty], join_column => 'entry');

lives_ok {
	$join2->add_database(database => $score);
} 'add_database (named form) lives';

my @cols2 = sort @{ $join2->columns() };
is_deeply(\@cols2, [qw(entry internal name score tier)],
	'named form produces same column set');

# ---------------------------------------------------------------------------
# add_database with remove_columns
# ---------------------------------------------------------------------------

my $join3 = Database::Join->new(databases => [$cust, $loyalty], join_column => 'entry');

lives_ok {
	$join3->add_database($score, remove_columns => ['internal']);
} 'add_database with remove_columns lives';

my @cols3 = sort @{ $join3->columns() };
is_deeply(\@cols3, [qw(entry name score tier)],
	'internal excluded when passed in remove_columns to add_database');

my $rows3 = $join3->selectall_arrayref();
ok(!exists($rows3->[0]{internal}), 'internal absent from row hashrefs');
ok(exists($rows3->[0]{score}),     'score present in row hashrefs');

# ---------------------------------------------------------------------------
# Chaining: add two databases in one expression
# ---------------------------------------------------------------------------

my $join4 = Database::Join->new(databases => [$cust], join_column => 'entry');

lives_ok {
	$join4->add_database($loyalty)->add_database($score);
} 'chained add_database calls live';

my @cols4 = sort @{ $join4->columns() };
is_deeply(\@cols4, [qw(entry internal name score tier)],
	'chained add_database builds correct column set');

# ---------------------------------------------------------------------------
# Error: object is not a Database::Abstraction subclass
# ---------------------------------------------------------------------------

throws_ok {
	$join->add_database('not_an_object');
} qr/not a Database::Abstraction/i, 'non-object argument is rejected';

# ---------------------------------------------------------------------------
# Error: new database lacks join_column
# ---------------------------------------------------------------------------

# Create a database whose table has no 'entry' column
{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/djscore.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	# djscore already has 'entry' — use a separate join object that
	# requires a missing column to trigger the error.
}

throws_ok {
	Database::Join->new(
		databases   => [ $score ],
		join_column => 'nonexistent_key',
	);
} qr/join_column "nonexistent_key" is absent/i,
	'join_column missing from database is rejected at new()';

# ---------------------------------------------------------------------------
# criteria on a new database's column work after add_database
# ---------------------------------------------------------------------------

my $join6 = Database::Join->new(databases => [$cust, $loyalty], join_column => 'entry');
$join6->add_database($score);

my $high = $join6->selectall_arrayref(score => { '>' => 80 });
is(scalar @{$high}, 1,       'criteria on new database column works');
is($high->[0]{name}, 'Alice', 'correct row returned for score > 80');

# Release DBI connections before File::Temp's cleanup END block fires.
# On Windows, SQLite keeps files locked until all handles are closed; file-scoped
# 'my' variables outlive END blocks, so we undef explicitly (joins first).
undef $_ for ($join, $join2, $join3, $join4, $join6, $cust, $loyalty, $score);
