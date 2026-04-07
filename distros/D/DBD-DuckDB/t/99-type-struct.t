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

SCOPE: {

    my $sth = $dbh->prepare('SELECT * FROM t1');
    $sth->execute;

    my $row = $sth->fetchrow_arrayref;

    diag explain $row;

TODO: {

        local $TODO = "$^O doesn't work yet. :(" if $^O eq 'darwin';

        is $row->[0]->{v}, 'a';
        is $row->[0]->{i}, 42;

    }

}

SCOPE: {

    my $sth = $dbh->prepare('INSERT INTO t1 VALUES(?)');
    $sth->execute({v => 'b', i => 84});

    ok !$dbh->errstr, 'Bind HASH';

    my $rows = $dbh->selectall_arrayref('SELECT * FROM t1');

    diag explain $rows;


}


done_testing;
