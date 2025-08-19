#!perl

## Test asynchronous queries

use 5.008001;
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 't';
use Test::More;
use Time::HiRes qw/sleep/;
use DBD::PgAsync ':async';
require 'dbdpg_test_setup.pl';
select(($|=1,select(STDERR),$|=1)[1]);

my $dbh = connect_database({AutoCommit => 1});

if (! $dbh) {
    plan skip_all => 'Connection to database failed, cannot continue testing';
}

plan tests => 96;

isnt ($dbh, undef, 'Connect to database for async testing');

my ($t,$sth,$res);
my $pgversion = $dbh->{pg_server_version};

## First, test out do() in all its variants

$t=q{Method do() works as expected with no args };
eval {
    $res = $dbh->do('SELECT 123');
};
is ($@, q{}, $t);
is ($res, 1, $t);

$t=q{Method do() works as expected with an unused attribute };
eval {
    $res = $dbh->do('SELECT 123', {pg_nosuch => 'arg'});
};
is ($@, q{}, $t);
is ($res, 1, $t);

$t=q{Method do() works as expected with an unused attribute and a non-prepared param };
eval {
    $res = $dbh->do('SET random_page_cost TO ?', undef, '2.2');
};
is ($@, q{}, $t);
is ($res, '0E0', $t);

$t=q{Method do() works as expected with an unused attribute and multiple real bind params };
eval {
    $res = $dbh->do('SELECT count(*) FROM pg_class WHERE reltuples IN (?,?,?)', undef, 1,2,3);
};
is ($@, q{}, $t);
is ($res, 1, $t);

$t=q{Cancelling a non-async do() query gives an error };
eval {
    $res = $dbh->pg_cancel();
};
like ($@, qr{No asynchronous query is running}, $t);

$t=q{Method do() works as expected with an asychronous flag };
eval {
    $res = $dbh->do('SELECT 123', {pg_async => PG_ASYNC});
};
is ($@, q{}, $t);
is ($res, '0E0', $t);

$t=q{Database attribute "async_status" returns 1 after async query};
$res = $dbh->{pg_async_status};
is ($res, +1, $t);

$t=q{Cancelling an async do() query works };
eval {
    $res = $dbh->pg_cancel();
};
is ($@, q{}, $t);

$t=q{Database method pg_result works after cancel};
eval {
    $res = $dbh->pg_result();
};
is ($@, q{}, $t);


$t=q{Running do() after a cancelled query works};
eval {
    $res = $dbh->do('SELECT 123');
};
is ($@, q{}, $t);

$t=q{Database attribute "async_status" returns 0 after normal query run};
$res = $dbh->{pg_async_status};
is ($res, 0, $t);

$t=q{Method pg_ready() fails after a non-async query};
eval {
    $dbh->pg_ready();
};
like ($@, qr{No async}, $t);

$res = $dbh->do('SELECT 123', {pg_async => PG_ASYNC});
$t=q{Method pg_ready() works after a non-async query};
## Sleep a sub-second to make sure the server has caught up
sleep 0.2;
eval {
    $res = $dbh->pg_ready();
};
is ($@, q{}, $t);

$t=q{Database method pg_ready() returns 1 after a completed async do()};
is ($res, 1, $t);

$res = $dbh->pg_ready();
$t=q{Database method pg_ready() returns true when called a second time};
is ($res, 1, $t);

$t=q{Database method pg_ready() returns 1 after a completed async do()};
is ($res, 1, $t);
$t=q{Cancelling an async do() query works };
eval {
    $res = $dbh->pg_cancel();
};
is ($@, q{}, $t);

$dbh->pg_result();
$t=q{Method do() runs after pg_result has cleared the async query};
eval {
    $dbh->do('SELECT 456');
};
is ($@, q{}, $t);

$dbh->do(q{SELECT 'async2'}, {pg_async => PG_ASYNC});

$t=q{Method do() fails when async query has not been cleared};
eval {
    $dbh->do(q{SELECT 'async_blocks'});
};
like ($@, qr{wait for async}, $t);

$t=q{Database method pg_result works as expected};
eval {
    $res = $dbh->pg_result();
};
is ($@, q{}, $t);

$t=q{Database method pg_result() returns correct value};
is ($res, 1, $t);

$t=q{Database method pg_result() fails when called twice};
eval {
    $dbh->pg_result();
};
like ($@, qr{No async}, $t);

$t=q{Database method pg_cancel() fails when called after pg_result()};
eval {
    $dbh->pg_cancel();
};
like ($@, qr{No async}, $t);

$t=q{Database method pg_ready() fails when called after pg_result()};
eval {
    $dbh->pg_ready();
};
like ($@, qr{No async}, $t);

$t=q{Database method do() works after pg_result()};
eval {
    $dbh->do('SELECT 123');
};
is ($@, q{}, $t);

SKIP: {

    if ($pgversion < 80200) {
        skip ('Need pg_sleep() to perform rest of async tests: your Postgres is too old', 14);
    }

    eval {
        $dbh->do('SELECT pg_sleep(0)');
    };
    is ($@, q{}, 'Calling pg_sleep works as expected');

    my $time = time();
    eval {
        $res = $dbh->do('SELECT pg_sleep(2)', {pg_async => PG_ASYNC});
    };
    $time = time()-$time;
    $t = q{Database method do() returns right away when in async mode};
    cmp_ok ($time, '<=', 1, $t);

    $t=q{Method pg_ready() returns false when query is still running};
    $res = $dbh->pg_ready();
    is ($res, 0, $t);

    pass ('Sleeping to allow query to finish');
    sleep(3);
    $t=q{Method pg_ready() returns true when query is finished};
    $res = $dbh->pg_ready();
    ok ($res, $t);

    $t=q{Method do() will not work if async query not yet cleared};
    eval {
        $dbh->do('SELECT pg_sleep(2)', {pg_async => PG_ASYNC});
    };
    like ($@, qr{wait for async}, $t);

    $t=q{Database method pg_cancel() works while async query is running};
    eval {
        $res = $dbh->pg_cancel();
    };
    is ($@, q{}, $t);

    $dbh->pg_result();

    $dbh->do('SELECT pg_sleep(2)', {pg_async => PG_ASYNC});
    $t=q{Database method pg_result works when async query is still running};
    eval {
        $res = $dbh->pg_result();
    };
    is ($@, q{}, $t);

    ## Now throw in some execute after the do()
    $sth = $dbh->prepare('SELECT 567');

    $t = q{Running execute after async do() gives an error};
    $dbh->do('SELECT pg_sleep(10)', {pg_async => PG_ASYNC});
    eval {
        $res = $sth->execute();
    };
    like ($@, qr{wait for async}, $t);

    $t=q{Database method pg_result returns 0 after query was cancelled};
    $dbh->pg_cancel();
    $res = $dbh->pg_result();
    ok (defined($res) && (0 + $res == 0), $t);
} ## end of pg_sleep skip

$t=q{Method execute() works when prepare has PG_ASYNC flag};
$sth = $dbh->prepare('SELECT 123', {pg_async => PG_ASYNC});
eval {
    $sth->execute();
};
is ($@, q{}, $t);

$t=q{Database attribute "async_status" returns 1 after prepare async};
$res = $dbh->{pg_async_status};
is ($res, 1, $t);

$t=q{Method do() fails when previous async prepare has been executed};
eval {
    $dbh->do('SELECT 123');
};
like ($@, qr{wait for async}, $t);

$t=q{Method execute() fails when previous async prepare has been executed};
eval {
    $sth->execute();
};
like ($@, qr{wait for async}, $t);

$t=q{Database method pg_cancel works if async query has already finished};
sleep 0.5;
eval {
    $res = $sth->pg_cancel();
};
is ($@, q{}, $t);
$dbh->pg_result();

$t=q{Method do() fails when previous execute async has not been cleared};
$sth->execute();
eval {
    $dbh->do('SELECT 345');
};
like ($@, qr{wait for async}, $t);

$dbh->pg_result();

$t=q{Method execute() works when prepare has PG_ASYNC flag};
eval {
    $sth->execute();
};
is ($@, q{}, $t);

$t=q{After async execute, pg_async_status is 1};
is ($dbh->{pg_async_status}, 1, $t);

$t=q{Method pg_result works after a prepare/execute call};
eval {
    $res = $dbh->pg_result;
};
is ($@, q{}, $t);

$t=q{Method pg_result() returns expected result after prepare/execute select};
is ($res, 1, $t);

$t=q{Method fetchall_arrayref works after pg_result};
eval {
    $res = $sth->fetchall_arrayref();
};
is ($@, q{}, $t);

$t=q{Method fetchall_arrayref returns correct result after pg_result};
is_deeply ($res, [[123]], $t);

$sth->execute();
$t=q{Fetch on non-active statement handle fails};
eval {
    $sth->fetch();
};
like ($@, qr{statement not active}, $t);
$dbh->pg_result();
$sth->finish();

$t=q{Statement method pg_result works on async statement handle};
$dbh->do('CREATE TABLE dbd_pg_test5(id INT, t TEXT)');
my $sth2 = $dbh->prepare('INSERT INTO dbd_pg_test5(id) SELECT 123 UNION SELECT 456', {pg_async => PG_ASYNC});
$sth2->execute();
eval {
    $res = $sth2->pg_result();
};
is ($@, q{}, $t);

$t=q{Statement method pg_result returns correct result after execute};
is ($res, 2, $t);

$sth2->execute();

$t=q{Database method pg_result works on async statement handle};
eval {
    $res = $sth2->pg_result();
};
is ($@, q{}, $t);
$t=q{Database method pg_result returns correct result after execute};
is ($res, 2, $t);

{
    $t=q{Database method pg_result works after async prepare};
    my $sth = $dbh->prepare('select pg_sleep(?)', { pg_async => 1, pg_prepare_now => 1 });
    eval {
        $res = $dbh->pg_result();
    };
    is ($@, q{}, $t);
    is (0+$res, 0, $t);

    $t=q{Can prepare another statement after waiting for an async prepare via pg_result};
    my $sth2;
    eval {
        $sth2 = $dbh->prepare('select pg_sleep(?)', { pg_prepare_now => 1 });
    };
    is ($@, q{}, $t);
}

{
    $t=q{Database method pg_result blocks until query done in face of prep statements};
    $dbh->{AutoCommit} = 0;
    $dbh->{ReadOnly} = 1;
    # randomly generated 8-byte number to ensure that it's not the result of some other command
    my $sth = $dbh->prepare('select  \'34c8e7d61b71de8d\'', { pg_async => 1 });
    $sth->execute();
    my $rows = $dbh->pg_result();
    is (0+$rows, 1, $t);
    is ($sth->fetchrow_arrayref()->[0], '34c8e7d61b71de8d', $t);

    $dbh->rollback();
    $dbh->{AutoCommit} = 1;
}

{
    $t=q{Database method pg_cancel doesn't work after async prepare};
    my $sth = $dbh->prepare('select pg_sleep(?)', { pg_async => 1, pg_prepare_now => 1 });
    eval {
        $dbh->pg_cancel();
    };
    isnt ($@, q{}, $t);
}

{
    $t=q{Database method pg_result returns cancelled after query with prep statments was cancelled};
    $dbh->{AutoCommit} = 0;
    $dbh->{ReadOnly} = 1;
    my $sth = $dbh->prepare('select 123', { pg_async => 1});
    $sth->execute();
    $dbh->pg_cancel();
    my $rows = $dbh->pg_result();
    is (0+$rows, 0, $t);
    is ($dbh->state(), '57014', $t);

    $dbh->rollback();
    $dbh->{AutoCommit} = 1;
}

{
    $t=q{Using pg_ready & pg_result works correctly for cancelled query with prep statements};
    $dbh->{AutoCommit} = 0;
    $dbh->{ReadOnly} = 1;
    my $sth = $dbh->prepare('select 123', { pg_async => 1});
    $sth->execute();
    $dbh->pg_cancel();

    my $rin;
    while (!$dbh->pg_ready()) {
        vec($rin, $$dbh{pg_socket}, 1) = 1;
        select($rin, undef, undef, undef);
    }

    my $rows = $dbh->pg_result();
    is (0+$rows, 0, $t);
    is ($dbh->state(), '57014', $t);

    $dbh->rollback();
    $$dbh{ReadOnly} = 0;
    $$dbh{AutoCommit} = 1;
}

{
    $t=q{Rollback/commit throws an error when an async query is running};
    $dbh->begin_work();
    $dbh->do('select 123', { pg_async => 1 });

    eval {
        $dbh->rollback();
    };
    like ($@, qr/^Must wait/, $t);

    $dbh->pg_result();
    $dbh->rollback();
}

{
    $t=q{Dbh async status is 1 after async rollback/commit};
    $dbh->{pg_use_async} = 1;
    $dbh->begin_work();
    $dbh->do('select 123');
    $dbh->pg_result();
    $dbh->rollback();
    is ($dbh->{pg_async_status}, 1, $t);

    $t=q{Database method pg_result works after async rollback/commit};
    eval {
        $dbh->pg_result();
    };
    is ($@, q{}, $t);

    $dbh->{pg_use_async} = 0;
}

{
    # savepoint tests
    #
    $t=q{Dbh async status is 1 after async savepoint};
    $$dbh{pg_use_async} = 1;
    $$dbh{AutoCommit} = 0;
    $dbh->pg_savepoint('a');
    is ($$dbh{pg_async_status}, 1, $t);

    $t=q{Savepoint not recorded before waiting for result};
    my @a = $dbh->pg_savepoints();
    is (scalar(@a), 0, $t);

    $t=q{Database method pg_result works after async savepoint};
    eval {
        $dbh->pg_result();
    };
    is ($@, q{}, $t);

    $t=q{Savepoint recorded after waiting for result};
    my @b = $dbh->pg_savepoints();
    is_deeply (\@b, ['a'], $t);

    # rollback_to tests
    #
    $t=q{Dbh async status is 1 after async rollback_to};
    $dbh->pg_rollback_to('a');
    is ($$dbh{pg_async_status}, 1, $t);

    $t=q{Savepoint recorded before waiting for result};
    @a = $dbh->pg_savepoints();
    is_deeply (\@a, ['a'], $t);

    $t=q{Database method pg_result works after async rollback_to};
    eval {
        $dbh->pg_result();
    };
    is ($@, q{}, $t);

    $t=q{Savepoint gone after waiting for result};
    @b = $dbh->pg_savepoints();
    is (scalar(@b), 0, $t);

    $$dbh{pg_use_async} = 0;
    $$dbh{AutoCommit} = 1;

    #
    # no tests for async release as that 100% the same code
    # as rollback_to
    #
}

{
    my $rc;

    $$dbh{pg_use_async} = 1;
    $$dbh{AutoCommit} = 0;

    $dbh->do('select 123');

    $t=q{pg_ping returns 2 when async query is active};
    is ($dbh->pg_ping(), 2, $t);

    $dbh->pg_result();

    $t=q{Dbh async status is 1 after async ping};
    $rc = $dbh->pg_ping();
    is ($$dbh{pg_async_status}, 1, $t);

    $t=q{Async pg_ping returned 1};
    is ($rc, 1, $t);

    $t=q{Database method pg_result works after async ping};
    eval {
        $rc = $dbh->pg_result();
    };
    is ($@, q{}, $t);

    $t=q{Async ping result is 3 when idle in txn};
    is ($rc, 3, $t);

    $$dbh{pg_use_async} = 0;
    $$dbh{AutoCommit} = 1;
}

{
    $t=q{Sychronous rollback on disconnect even if async mode is enabled};

    my ($dbh2, $dbh3, $rc);

    $dbh2 = $dbh->clone();
    $dbh3 = $dbh2->clone();

    $dbh2->do('create table t (x int)');

    $$dbh3{AutoCommit} = 0;
    $dbh3->do('insert into t (x) values (1)');

    $$dbh3{pg_use_async} = 0;
    $dbh3->disconnect();

    $rc = $dbh2->do('select * from t');
    is (0 + $rc, 0, $t);
}

{
    $t=q{pg_ready works without prep statements};
    $$dbh{pg_use_async} = 1;
    my $sth = $dbh->prepare('select 123');
    $sth->execute();
    1 until $dbh->pg_ready();
    my $rows = $dbh->pg_result();
    is ($rows, 1, $t);

    my $row = $sth->fetchrow_arrayref();
    is_deeply ($row, ['123'], $t);

    $$dbh{pg_use_async} = 0;
}

{
    $t=q{pg_ready works with prep statements};
    $$dbh{pg_use_async} = 1;
    $$dbh{AutoCommit} = 0;
    $$dbh{ReadOnly} = 1;

    my $sth = $dbh->prepare('select 123');
    $sth->execute();
    1 until $dbh->pg_ready();
    my $rows = $dbh->pg_result();
    is ($rows, 1, $t);

    my $row = $sth->fetchrow_arrayref();
    is_deeply ($row, ['123'], $t);

    $$dbh{pg_use_async} = 0;
    $$dbh{ReadOnly} = 0;
    $$dbh{AutoCommit} = 1;
}

{
    #
    # test async execute of non-async statements when pg_use_async is true
    #

    my $sth = $dbh->prepare('select 123');

    $$dbh{pg_use_async} = 1;
    $sth->execute();
    is($$sth{pg_async_status}, 1, 'sth async status is 1 after execute when use_async was set');
    is($$dbh{pg_async_status}, 1, 'dbh async status is 1 after execute when use_async was set');

    eval {
        $dbh->pg_ready();
    };
    is ($@, q{}, 'Database method pg_ready works after execute when use_async was set');

    eval {
        $dbh->pg_result();
    };
    is ($@, q{}, 'Database method pg_result works after execute when use_async was set');

    $$dbh{pg_use_async} = 0;
}

{
    my $sth1 = $dbh->prepare('select name from pg_prepared_statements', { pg_prepare_now => 1 });
    my $sth2 = $dbh->prepare('select statement from pg_prepared_statements', { pg_prepare_now => 1 });
    my $sth3 = $dbh->prepare('select count(*) from pg_prepared_statements', { pg_prepare_now => 1 });
    my ($prepd0, $prepd1);
    my ($queued0, $queued1);

    $sth3->execute();
    $prepd0 = $sth3->fetchrow_arrayref()->[0];

    $$dbh{pg_use_async} = 1;

    $queued0 = $dbh->pg_deallocs_queued();
    $sth1 = $sth2 = undef;
    $queued1 = $dbh->pg_deallocs_queued();
    is ($queued1, $queued0 + 2, '# of queued deallocs increased as expected');

    $sth3->execute();
    $queued0 = $dbh->pg_deallocs_queued();
    is ($queued0, $queued1 - 2, '# of queued deallocs decreased as expected');

    $dbh->pg_result();
    $prepd1 = $sth3->fetchrow_arrayref()->[0];
    is ($prepd1, $prepd0 - 2, '# of prepared statements decreased as expected');

    $$dbh{pg_use_async} = 0;
}

$dbh->do('DROP TABLE dbd_pg_test5');

## TODO: More pg_sleep tests with execute

cleanup_database($dbh,'test');
$dbh->disconnect;
