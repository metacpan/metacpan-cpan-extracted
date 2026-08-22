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
use Database::Join;

# ---------------------------------------------------------------------------
# Fixtures
#
#   djcust:    entry | name  | email
#              c001  | Alice | alice@example.com
#              c002  | Bob   | bob@example.com
#              c003  | Carol | carol@example.com
#
#   djloyalty: entry | tier
#              c001  | gold
#              c002  | silver
#              (c003 has no loyalty record)
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/djcust.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE djcust (entry TEXT PRIMARY KEY, name TEXT, email TEXT)');
	$dbh->do(q{INSERT INTO djcust VALUES ('c001','Alice','alice@example.com')});
	$dbh->do(q{INSERT INTO djcust VALUES ('c002','Bob',  'bob@example.com')});
	$dbh->do(q{INSERT INTO djcust VALUES ('c003','Carol','carol@example.com')});
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

my $cust    = Database::djcust->new(directory    => $dir);
my $loyalty = Database::djloyalty->new(directory => $dir);

# ---------------------------------------------------------------------------
# Helper: build a join with a given join_type
# ---------------------------------------------------------------------------

sub make_join {
	my ($type) = @_;
	return Database::Join->new(
		databases   => [ $cust, $loyalty ],
		join_column => 'entry',
		join_type   => $type,
	);
}

# ---------------------------------------------------------------------------
# LEFT JOIN (default): all customers, loyalty data where present
# ---------------------------------------------------------------------------

my $left = make_join('left');

my $rows;
lives_ok { $rows = $left->selectall_arrayref() } 'left join: selectall_arrayref lives';

is(ref $rows, 'ARRAY', 'selectall_arrayref returns arrayref');
is(scalar @{$rows}, 3, 'left join: 3 customers (Carol included without tier)');

my ($carol_row) = grep { $_->{name} eq 'Carol' } @{$rows};
ok(defined $carol_row,      'Carol present in left join');
ok(!defined $carol_row->{tier}, 'Carol has no tier in left join (undef)');

my ($alice_row) = grep { $_->{name} eq 'Alice' } @{$rows};
is($alice_row->{tier}, 'gold', 'Alice has gold tier in left join');

# ---------------------------------------------------------------------------
# INNER JOIN: only customers with loyalty records
# ---------------------------------------------------------------------------

my $inner = make_join('inner');

lives_ok { $rows = $inner->selectall_arrayref() } 'inner join: selectall_arrayref lives';
is(scalar @{$rows}, 2, 'inner join: 2 rows (Alice and Bob only)');

my @names_inner = sort map { $_->{name} } @{$rows};
is_deeply(\@names_inner, [qw(Alice Bob)], 'inner join: correct names');

# ---------------------------------------------------------------------------
# OUTER JOIN: all rows from either database
# ---------------------------------------------------------------------------

my $outer = make_join('outer');

lives_ok { $rows = $outer->selectall_arrayref() } 'outer join: selectall_arrayref lives';
is(scalar @{$rows}, 3, 'outer join: 3 rows (all customers)');

# ---------------------------------------------------------------------------
# Criteria routing: column from secondary database
# ---------------------------------------------------------------------------

lives_ok {
	$rows = $left->selectall_arrayref(tier => 'gold');
} 'criteria on secondary-database column lives';

is(scalar @{$rows}, 1, 'tier => gold yields 1 row');
is($rows->[0]{name}, 'Alice', 'correct customer returned for tier=gold');

# ---------------------------------------------------------------------------
# Criteria routing: column from primary database
# ---------------------------------------------------------------------------

lives_ok {
	$rows = $left->selectall_arrayref(name => 'Bob');
} 'criteria on primary-database column lives';

is(scalar @{$rows}, 1, 'name => Bob yields 1 row');
is($rows->[0]{tier}, 'silver', 'Bob has silver tier');

# ---------------------------------------------------------------------------
# fetchrow_hashref: key lookup
# ---------------------------------------------------------------------------

my $row;
lives_ok { $row = $left->fetchrow_hashref(entry => 'c001') } 'fetchrow_hashref lives';
is($row->{name}, 'Alice', 'fetchrow_hashref returns correct row');
is($row->{tier}, 'gold',  'fetchrow_hashref merges tier correctly');

# ---------------------------------------------------------------------------
# count
# ---------------------------------------------------------------------------

is($left->count(), 3, 'count() returns total merged row count');

# Release DBI connections before File::Temp's cleanup END block fires.
# On Windows, SQLite keeps files locked until all handles are closed; file-scoped
# 'my' variables outlive END blocks, so we undef explicitly (joins first).
undef $_ for ($left, $inner, $outer, $cust, $loyalty);
