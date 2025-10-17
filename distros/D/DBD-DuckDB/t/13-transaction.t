#perl -T

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use DuckDBTest;

SCOPE: {

    my $dbh = connect_ok(RaiseError => 1);

    ok $dbh->do('CREATE TABLE t1 (id INTEGER, name VARCHAR)') == 0, 'Create table';

    $dbh->{AutoCommit} = 0;

    ok(!$dbh->{AutoCommit}, 'AutoCommit is off');


    ok $dbh->do("INSERT INTO t1 VALUES (1, 'foo')") == 1, 'Insert row';

    ok @{$dbh->selectall_arrayref('SELECT * FROM t1')} == 1, 'found 1 row';

    ok $dbh->rollback == 1, 'Rollback';

    ok @{$dbh->selectall_arrayref('SELECT * FROM t1')} == 0, 'found 0 row';


    ok $dbh->do("INSERT INTO t1 VALUES (1, 'foo')") == 1, 'Insert row';

    ok @{$dbh->selectall_arrayref('SELECT * FROM t1')} == 1, 'found 1 row';

    ok $dbh->commit() == 1, 'Commit transaction';

    ok @{$dbh->selectall_arrayref('SELECT * FROM t1')} == 1, 'found 1 row';

    $dbh->disconnect;

}

SCOPE: {

    my $dbh = connect_ok(RaiseError => 1);

    ok $dbh->do('CREATE TABLE t1 (id INTEGER, name VARCHAR)') == 0, 'Create table';

    ok $dbh->begin_work;

    eval {
        my $sth = $dbh->prepare("INSERT INTO t1 VALUES(1, 'foo')");
        $sth->execute;
        ok $dbh->commit == 1, 'Commit transaction';
    };

    ok !$dbh->rollback, 'Rollback failed';

}

done_testing();
