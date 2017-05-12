
use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;

use App::OverWatch;
use App::OverWatch::ServiceLock;

binmode Test::More->builder->output, ":encoding(UTF-8)";
binmode Test::More->builder->failure_output, ":encoding(UTF-8)"; 
binmode Test::More->builder->todo_output, ":encoding(UTF-8)";

sub get_servicelock {
    my $config = shift;

    my $OverWatch = App::OverWatch->new();
    lives_ok {
        $OverWatch->load_config($config);
    } 'load_config lives';

    my $ServiceLock = $OverWatch->servicelock();
    isa_ok($ServiceLock, "App::OverWatch::ServiceLock");
    return $ServiceLock;
}

sub run_servicelock_tests {
    my $ServiceLock = shift;

    ## Create table
    is($ServiceLock->create_table(), 1, "Create servicelocks table");

    my $s = 'systemname';
    my $s2 = 'differentsystem';
    my $w = 'aworker';
    my $t = 'some text for the lock';
    my $w2 = 'differentworker';

    ## Create lock
    is($ServiceLock->create_lock({ system => $s }), 1, "Create $s lock");

    ## Lock it
    is($ServiceLock->try_lock({ system => $s, worker => $w, text => $t }), 1, "Get lock (succeed)");

    ## Fail to lock with a different worker
    is($ServiceLock->try_lock({ system => $s, worker => $w2, text => $t }), 0, "Get lock (fail)");

    ## Try unlocking
    is($ServiceLock->try_unlock({ system => $s, worker => $w }), 1, "Unlock (succeed)");

    ## Try unlocking
    is($ServiceLock->try_unlock({ system => $s, worker => $w }), 0, "Unlock (fail)");

    my $rh_lock = $ServiceLock->get_lock({ system => $s });
    isa_ok($rh_lock, 'App::OverWatch::Lock');
    is($rh_lock->status, 'UNLOCKED', 'Lock is UNLOCKED');
    ## Try locking again
    is($ServiceLock->try_lock({ system => $s, worker => $w, text => $t }), 1, "Get lock (succeed)");

    ## Get all locks
    my @Locks = $ServiceLock->get_all_locks();
    is(scalar @Locks, 1, "get_all_locks() returns single lock");
    isa_ok($Locks[0], 'App::OverWatch::Lock');

    ## Create second lock
    is($ServiceLock->create_lock({ system => $s2 }), 1, "Create $s2 lock");

    ## Get all locks
    @Locks = $ServiceLock->get_all_locks();
    is(scalar @Locks, 2, "get_all_locks() returns 2 locks");

    ## Force unlock
    is($ServiceLock->force_unlock({ system => $s }), 1, "Force unlock (succeed)");

    ## Force unlock an already unlocked lock
    is($ServiceLock->force_unlock({ system => $s2 }), 0, "Force unlock (fail as lock not locked)");

    ## utf8 tests
    {
        my $char_str = "à á â ã ä å æ ç è é ê ë ì í î ï ð ñ ò ó ô õ ö ÷ ø ù ú û ü ý þ ÿ";
        is($ServiceLock->try_lock({ system => $s, worker => $w, text => $char_str }), 1, "Get lock (succeed)");
        my $rh_lock = $ServiceLock->get_lock({ system => $s });
        isa_ok($rh_lock, 'App::OverWatch::Lock');
        is($rh_lock->status, 'LOCKED', 'Lock is LOCKED');
        is($rh_lock->text, $char_str, 'Character string is as expected');
    }
}

1;
