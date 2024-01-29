use DBI;
use DBIx::OpenTracing;
use OpenTracing::Implementation qw/Test/;
use Test::Most;
use Test::OpenTracing::Integration;

use lib 't/lib';
use Test::DBIx::OpenTracing;

my $db_name = 'test_db';
my $dbh     = DBI->connect(
    "dbi:Mem(PrintError=0):$db_name",    # PrintError can't be set later
);

Test::DBIx::OpenTracing::test_database(
    dbh        => $dbh,
    db_name    => $db_name,
    statements => {
        create => 'CREATE TABLE things (id INTEGER PRIMARY KEY, description VARCHAR(256))',
        insert => q[
          INSERT INTO things
          VALUES
              (1, 'some thing'),
              (2, 'other thing'),
              (3, 'this is a thing'),
              (4, 'cool thing'),
              (5, 'very cool thing')
        ],
        delete            => 'DELETE FROM things WHERE id IN (4, 5)',
        clear             => 'DELETE FROM things',
        select_all_multi  => 'SELECT * FROM things WHERE id IN (1, 3, 10)',
        select_all_single => 'SELECT * FROM things WHERE id = 2',
        select_column_multi => 'SELECT description FROM things WHERE id IN (2, 3, 10)',
        select_empty      => 'SELECT * FROM things WHERE id = 999',
        invalid => 'SELET id FORRM things',
        simple  => 'SELECT 1',
        bind => [ 'SELECT id, description FROM things WHERE id IN (?, ?)', 1, 3 ],
    },
    error_detection => {
        sqlstate    => 'S1000',
        err         => '2000000000',
    },
);

done_testing();
