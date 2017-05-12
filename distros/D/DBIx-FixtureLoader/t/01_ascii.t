use strict;
use warnings;
use Test::More;
use DBI;
use DBIx::FixtureLoader;
use Test::Requires 'DBD::SQLite';

my $dbh = DBI->connect("dbi:SQLite::memory:", '', '', {RaiseError => 1}) or die 'cannot connect to db';
$dbh->do(q{
    CREATE TABLE item (
        id   INTEGER PRIMARY KEY,
        name VARCHAR(255)
    );
});

my $m = DBIx::FixtureLoader->new(
    dbh => $dbh,
);

isa_ok $m, 'DBIx::FixtureLoader';
is $m->_driver_name, 'SQLite';
ok !$m->bulk_insert;

$m->load_fixture('t/data/item-ascii.csv');

my $result = $dbh->selectrow_arrayref('SELECT COUNT(*) FROM item ORDER BY id;');
is $result->[0], 2;

my $rows = $dbh->selectall_arrayref('SELECT * FROM item ORDER BY id;', {Slice => {}});
is scalar @$rows, 2;
is $rows->[0]{name}, 'Samurai Sword';

done_testing;
