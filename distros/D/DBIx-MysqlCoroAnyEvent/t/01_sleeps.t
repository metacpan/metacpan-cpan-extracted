use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/../t";
use Test::More;
use DBI;
use Coro;
use AnyEvent;
use Coro::AnyEvent;
use Time::HiRes 'time';
use Test::mysqld;
use feature 'say';

SKIP: {
    my $mysqld = Test::mysqld->new(
        my_cnf => {
            'skip-networking' => '',    # no TCP socket
        }
    ) or skip "no MySQL found";

    sub db_connect {
        DBI->connect(
            $mysqld->dsn(),
            undef, undef,
            {   AutoCommit => 1,
                RootClass  => 'DBIx::MysqlCoroAnyEvent'
            }
        );
    }

    my $cv         = AE::cv;
    my $start_time = time;

    ok(my $dbh = db_connect(), 'connected');
    ok(my $sth = $dbh->prepare('select sleep(2)'), 'prepared');
    $start_time = time;
    ok($sth->execute(), 'executed');
    my $duration = time - $start_time;
    ok(($duration > 1 && $duration < 3), 'slept');
    is(ref($dbh), 'DBIx::MysqlCoroAnyEvent::db', 'dbh class');
    is(ref($sth), 'DBIx::MysqlCoroAnyEvent::st', 'sth class');

    for my $t (1 .. 10) {
        my $timer;
        $cv->begin;
        $timer = AE::timer 0.01 + $t / 100, 0, unblock_sub {
            ok(my $dbh = db_connect(), "connected $t");
            ok(my $sth = $dbh->prepare('select sleep(' . $t . ')'), "prepared $t");
            my $start_time = time;
            ok($sth->execute(), "executed $t");
            my $duration = time - $start_time;
            ok(($duration > $t - 1 && $duration < $t + 1), "slept $t");
            print "duration: $t: $duration\n";
            $cv->end;
            undef $timer;
        };
    }
    $cv->recv;

    print "total run time: " . (time - $start_time) . " sec\n";
}
done_testing();
