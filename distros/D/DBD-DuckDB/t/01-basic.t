#perl -T

use strict;
use warnings;

use Test::More;
use DBI ':sql_types';

my $dbh = DBI->connect('dbi:DuckDB:dbname=:memory:');

ok($dbh->do('CREATE TABLE t (id INTEGER)') == 0, '->do return 0E0 rows changed');

my $sth = $dbh->prepare('INSERT INTO t(id) VALUES(?)');

ok $sth, '->prepare INSERT statement';

$sth->execute($_) for (1 .. 1_000);

is scalar(@{$dbh->selectall_arrayref('SELECT * FROM t')}),               1_000, '->selectall_arrayref';
is $dbh->selectrow_arrayref('SELECT COUNT(id) AS total FROM t')->[0],    1_000, '->selectrow_arrayref';
is $dbh->selectrow_hashref('SELECT COUNT(id) AS total FROM t')->{total}, 1_000, '->selectrow_hashref';

SCOPE: {
    my $sth = $dbh->prepare('SELECT * FROM t');
    $sth->execute;

    is $sth->rows, 1000, '->rows';
}

done_testing;
