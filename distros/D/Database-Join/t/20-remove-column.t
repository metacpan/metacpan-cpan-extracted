use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
	eval { require DBD::SQLite; require Database::Abstraction };
	plan skip_all => 'DBD::SQLite and Database::Abstraction required' if $@;
	plan tests => 19;
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
#   djloyalty: entry | tier  | notes
# ---------------------------------------------------------------------------

my $dir = tempdir(CLEANUP => 1);

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/djcust.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE djcust (entry TEXT PRIMARY KEY, name TEXT, email TEXT)');
	$dbh->do(q{INSERT INTO djcust VALUES ('c001','Alice','alice@example.com')});
	$dbh->do(q{INSERT INTO djcust VALUES ('c002','Bob',  'bob@example.com')});
	$dbh->disconnect;
}

{
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/djloyalty.sql", '', '',
		{ RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE djloyalty (entry TEXT PRIMARY KEY, tier TEXT, notes TEXT)');
	$dbh->do(q{INSERT INTO djloyalty VALUES ('c001','gold',  'vip')});
	$dbh->do(q{INSERT INTO djloyalty VALUES ('c002','silver','regular')});
	$dbh->disconnect;
}

my $cust    = Database::djcust->new(directory    => $dir);
my $loyalty = Database::djloyalty->new(directory => $dir);

# ---------------------------------------------------------------------------
# remove_columns in constructor
# ---------------------------------------------------------------------------

my $join_rc;
lives_ok {
	$join_rc = Database::Join->new(
		databases      => [ $cust, $loyalty ],
		join_column    => 'entry',
		remove_columns => [ 'email', 'notes' ],
	);
} 'new() with remove_columns lives';

my @cols_rc = sort @{ $join_rc->columns() };
is_deeply(\@cols_rc, [qw(entry name tier)],
	'columns() excludes email and notes after constructor removal');

ok(!exists($join_rc->schema()->{email}),  'schema() excludes email');
ok(!exists($join_rc->schema()->{notes}),  'schema() excludes notes');
ok(exists($join_rc->schema()->{name}),    'schema() retains name');

my $rows_rc = $join_rc->selectall_arrayref();
ok(!exists($rows_rc->[0]{email}),  'returned rows have no email key');
ok(!exists($rows_rc->[0]{notes}),  'returned rows have no notes key');
ok(exists($rows_rc->[0]{name}),    'returned rows still have name');

# ---------------------------------------------------------------------------
# remove_column method (dynamic, after construction)
# ---------------------------------------------------------------------------

my $join = Database::Join->new(
	databases   => [ $cust, $loyalty ],
	join_column => 'entry',
);

# Baseline: all columns present before removal
my @before = sort @{ $join->columns() };
is_deeply(\@before, [qw(email entry name notes tier)],
	'all columns present before any removal');

my $ret;
lives_ok { $ret = $join->remove_column('email') } 'remove_column lives';
is(ref $ret, 'Database::Join', 'remove_column returns $self (chainable)');

my @after = sort @{ $join->columns() };
is_deeply(\@after, [qw(entry name notes tier)],
	'email absent from columns() after removal');

my $rows = $join->selectall_arrayref();
ok(!exists($rows->[0]{email}),  'email absent from row hashrefs after removal');
ok(exists($rows->[0]{name}),    'name still present after email removal');

# Chaining
lives_ok { $join->remove_column('notes')->remove_column('tier') }
	'chained remove_column calls live';
my @chained = sort @{ $join->columns() };
is_deeply(\@chained, [qw(entry name)], 'columns correct after chained removals');

# ---------------------------------------------------------------------------
# Error: cannot remove join_column
# ---------------------------------------------------------------------------

throws_ok {
	$join->remove_column('entry');
} qr/Cannot remove join_column/i, 'removing join_column croaks';

# ---------------------------------------------------------------------------
# Idempotence: removing a non-existent or already-removed column is safe
# ---------------------------------------------------------------------------

lives_ok { $join->remove_column('no_such_column') }
	'removing a non-existent column is silently ignored';

lives_ok { $join->remove_column('email') }
	'removing an already-removed column is idempotent';

# Release DBI connections before File::Temp's cleanup END block fires.
# On Windows, SQLite keeps files locked until all handles are closed; file-scoped
# 'my' variables outlive END blocks, so we undef explicitly (joins first).
undef $_ for ($join_rc, $join, $cust, $loyalty);
