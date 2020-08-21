use DBI;
use DBIx::OpenTracing;
use OpenTracing::Implementation qw/Test/;
use Test::Most;
use Test::OpenTracing::Integration;

use lib 't/lib';
use Test::DBIx::OpenTracing;

my $BS = '\\';

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
        clear             => 'DELETE FROM things',
        select_all_multi  => 'SELECT * FROM things WHERE id IN (1, 3, 10)',
        select_all_single => 'SELECT * FROM things WHERE id = 2',
        select_column_multi => 'SELECT description FROM things WHERE id IN (2, 3, 10)',
        invalid => 'SELET id FORRM things',
        simple  => 'SELECT 1',
        bind => [ 'SELECT id, description FROM things WHERE id IN (?, ?)', 1, 3 ],
        comments => [
            [
                'double dash' =>
                    ('SELECT 1 -- wdffdsfdfdfdf', 'SELECT 1 ')
            ],
            [
                'double dash inside a double-quoted string' =>
                    ('SELECT id FROM things WHERE description = "--dash"')
                    x 2
            ],
            [
                'double dash inside a single-quoted string' =>
                    (q[SELECT id FROM things WHERE description = '--dash']) x 2
            ],
            [
                'hash until end of line' => (
                    q[INSERT INTO things VALUES (10, 'xxx') # hello there],
                    q[INSERT INTO things VALUES (10, 'xxx') ],
                ),
            ],
            [
                'two strings' => (
                    q[INSERT INTO things VALUES ('11', '# value') # hello there],
                    q[INSERT INTO things VALUES ('11', '# value') ],
                ),
            ],
            [
                'multi-line c-style comment' => (
                    q[/*
                            ho
                            ho
                            ho
                      */SELECT * FROM things],
                     q[SELECT * FROM things],
                ),
            ],
            [
                'embedded c-style comment' => (
                    q[SELECT /* hoho */ * FROM things WHERE description = "/* * */"],
                    q[SELECT  * FROM things WHERE description = "/* * */"],
                ),
            ],
            [
                'escaped quote inside a string' => (
                    qq[SELECT * FROM things WHERE description = "$BS" -- comment"],
                    qq[SELECT * FROM things WHERE description = "$BS" -- comment"],
                ),
            ],
            [
                'escaped quote inside a string (triple backslash)' => (
                    qq[SELECT * FROM things WHERE description = "$BS$BS$BS" -- comment"],
                    qq[SELECT * FROM things WHERE description = "$BS$BS$BS" -- comment"],
                ),
            ],
            [
                'double backslash at the end of string' => (
                    qq[SELECT * FROM things WHERE description = "# whatever $BS$BS"],
                    qq[SELECT * FROM things WHERE description = "# whatever $BS$BS"],
                ),
            ],
        ],
    },
);
done_testing();
