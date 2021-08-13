use 5.24.0;

use strict;
use warnings;

use DBI;
use DBIx::Schema::Migration;
use Test::SQLite;

use Test::Simple tests => 4;

# Use an in-memory test db.
my $sqlite = Test::SQLite->new(
    memory   => 1,
    db_attrs => { RaiseError => 1, AutoCommit => 1 },
);

my $dbh = $sqlite->dbh;

my $migrations = DBIx::Schema::Migration->new( {
        dbh => $dbh,
        dir => 'migrations',
} );

# TEST 1
# Testing applied_migration table creation.
$migrations->init;

my $sth = $dbh->table_info( '%', '%', 'applied_migrations', 'TABLE' );
my @row = $sth->fetchrow_array;

$sth->finish;

ok( @row, 'Table applied_migrations does not exists' );

# TEST 2
# Testing migrations run.
# We will try to fetch data, which was populated.
$migrations->up;

$sth = $dbh->prepare('SELECT * FROM users WHERE name = ?');
$sth->execute('Jane');
my $row = $sth->fetchrow_hashref;

$sth->finish;

ok( $row->{surname} eq 'Mashkova', 'User Jane Mashkova does not exists' );

# TEST 3
# Testing migrations rollback by 1.
# Will fetch table user info and it should be there.
$migrations->down(1);
$sth = $dbh->table_info( '%', '%', 'users', 'TABLE' );
@row = $sth->fetchrow_array;

$sth->finish;

ok(@row, 'Table users does not exists' );

# TEST 4
# Testing migrations rollback by 1.
# Will fetch table user info and no table should be.
$migrations->down(1);
$sth = $dbh->table_info( '%', '%', 'users', 'TABLE' );
@row = $sth->fetchrow_array;

$sth->finish;

ok( !@row, 'Table users still exists' );

# Close in-memory test db.
$dbh->disconnect;
