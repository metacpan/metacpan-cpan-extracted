use DBI;
use DBIx::OpenTracing;
use OpenTracing::Implementation qw/Test/;
use Test::Most;
use Test::OpenTracing::Integration;

use lib 't/lib';
use Test::DBIx::OpenTracing;

my $mysqld = eval {
    no warnings 'once';
    require Test::mysqld;
    Test::mysqld->new(my_cnf => { 'skip-networking' => '' })
        or die $Test::mysqld::errstr;
} or do {
    diag $@;
    plan skip_all => 'mysqld is not available';
};

my $dsn = $mysqld->dsn();
my $dbh = DBI->connect($dsn);

Test::DBIx::OpenTracing::test_database(
    dbh        => $dbh,
    db_name    => 'test',
    statements => {
        create => 'CREATE TABLE things (id INTEGER PRIMARY KEY, description VARCHAR(256))',
        insert => q[
          INSERT INTO things (id, description)
          VALUES
              (1, 'some thing'),
              (2, 'other thing'),
              (3, 'this is a thing'),
              (4, 'cool thing'),
              (5, 'very cool thing')
        ],
        delete            => 'DELETE FROM things WHERE id IN (4, 5)',
        select_all_multi  => 'SELECT * FROM things WHERE id IN (1, 3, 10)',
        select_all_single => 'SELECT * FROM things WHERE id = 2',
        select_column_multi => 'SELECT description FROM things WHERE id IN (2, 3, 10)',
        invalid => 'SELET id FORRM things',
        simple  => 'SELECT 1',
        bind => [ 'SELECT id, description FROM things WHERE id IN (?, ?)', 1, 3 ],
    },
);
done_testing();
