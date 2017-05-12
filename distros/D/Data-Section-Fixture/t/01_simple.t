use strict;
use warnings;
use DBI;
use Test::More;
use Test::mysqld;
use Data::Section::Fixture qw(with_fixture);
use Data::Dumper;

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip_networking' => '',
    }
) or plan skip_all => $Test::mysqld::errstr;

my $dbh = DBI->connect(
    $mysqld->dsn(dbname => 'test')
);
$dbh->do('CREATE TABLE t (a int)');

subtest 'fixture exists inside with_fixture' => sub {
    with_fixture($dbh, sub {
        my $rows = $dbh->selectall_arrayref('SELECT a FROM t ORDER BY a');
        is_deeply $rows, [[1], [2], [3]];
    });
};

subtest 'fixture does not exist outside with_fixture' => sub {
    my $rows = $dbh->selectall_arrayref('SELECT a FROM t');
    is_deeply $rows, [];

    with_fixture($dbh, sub {});

    $rows = $dbh->selectall_arrayref('SELECT a FROM t');
    is_deeply $rows, [];
};

done_testing;

__DATA__
@@ setup
INSERT INTO t (a) VALUES (1), (2), (3);

@@ teardown
DELETE FROM t;
