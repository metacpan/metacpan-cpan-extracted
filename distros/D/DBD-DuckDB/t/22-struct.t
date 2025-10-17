#perl -T

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use DuckDBTest;

my $dbh = connect_ok;

my $sql = <<'END_SQL';
CREATE TABLE t1 AS (
    SELECT row('a', 42)::STRUCT(v VARCHAR, i INTEGER)
)
END_SQL

ok $dbh->do($sql) == 1, 'Create struct table with select/insert';

my $sth = $dbh->prepare('SELECT * FROM t1');
$sth->execute;

my $row = $sth->fetchrow_arrayref;

diag explain $row;

TODO: {

    local $TODO = 'Fail in CI';

    is $row->[0]->{v}, 'a';
    is $row->[0]->{i}, 42;

}

done_testing;
