use strict;
use warnings;

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use ExtUtils::testlib;

use omnithreads;

BEGIN {
    eval {
        require omnithreads::shared;
        import omnithreads::shared;
    };
    if ($@ || ! $omnithreads::shared::threads_shared) {
        print("1..0 # Skip: omnithreads::shared not available\n");
        exit(0);
    }

    $| = 1;
    print("1..53\n");   ### Number of tests that will be run ###
};

my $TEST;
BEGIN {
    share($TEST);
    $TEST = 1;
}

ok(1, 'Loaded');

sub ok {
    my ($ok, $name) = @_;

    lock($TEST);
    my $id = $TEST++;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
    }

    return ($ok);
}


### Start of Testing ###

my ($READY, $GO, $DONE) :shared = (0, 0, 0);

sub do_thread
{
    {
        lock($DONE);
        $DONE = 0;
        lock($READY);
        $READY = 1;
        cond_signal($READY);
    }

    lock($GO);
    while (! $GO) {
        cond_wait($GO);
    }
    $GO = 0;

    lock($READY);
    $READY = 0;
    lock($DONE);
    $DONE = 1;
    cond_signal($DONE);
}

sub wait_until_ready
{
    lock($READY);
    while (! $READY) {
        cond_wait($READY);
    }
}

sub thread_go
{
    {
        lock($GO);
        $GO = 1;
        cond_signal($GO);
    }

    {
        lock($DONE);
        while (! $DONE) {
            cond_wait($DONE);
        }
    }
    omnithreads->yield();
    sleep(1);
}


my $thr = omnithreads->create('do_thread');
wait_until_ready();
ok($thr->is_running(),    'thread running');
ok(omnithreads->list(omnithreads::running) == 1,  'thread running list');
ok(! $thr->is_detached(), 'thread not detached');
ok(! $thr->is_joinable(), 'thread not joinable');
ok(omnithreads->list(omnithreads::joinable) == 0, 'thread joinable list');
ok(omnithreads->list(omnithreads::all) == 1, 'thread list');

thread_go();
ok(! $thr->is_running(),  'thread not running');
ok(omnithreads->list(omnithreads::running) == 0,  'thread running list');
ok(! $thr->is_detached(), 'thread not detached');
ok($thr->is_joinable(),   'thread joinable');
ok(omnithreads->list(omnithreads::joinable) == 1, 'thread joinable list');
ok(omnithreads->list(omnithreads::all) == 1, 'thread list');

$thr->join();
ok(! $thr->is_running(),  'thread not running');
ok(omnithreads->list(omnithreads::running) == 0,  'thread running list');
ok(! $thr->is_detached(), 'thread not detached');
ok(! $thr->is_joinable(), 'thread not joinable');
ok(omnithreads->list(omnithreads::joinable) == 0, 'thread joinable list');
ok(omnithreads->list(omnithreads::all) == 0, 'thread list');

$thr = omnithreads->create('do_thread');
$thr->detach();
ok($thr->is_running(),    'thread running');
ok(omnithreads->list(omnithreads::running) == 0,  'thread running list');
ok($thr->is_detached(),   'thread detached');
ok(! $thr->is_joinable(), 'thread not joinable');
ok(omnithreads->list(omnithreads::joinable) == 0, 'thread joinable list');
ok(omnithreads->list(omnithreads::all) == 0, 'thread list');

thread_go();
ok(! $thr->is_running(),  'thread not running');
ok(omnithreads->list(omnithreads::running) == 0,  'thread running list');
ok($thr->is_detached(),   'thread detached');
ok(! $thr->is_joinable(), 'thread not joinable');
ok(omnithreads->list(omnithreads::joinable) == 0, 'thread joinable list');

$thr = omnithreads->create(sub {
    ok(! omnithreads->is_detached(), 'thread not detached');
    ok(omnithreads->list(omnithreads::running) == 1, 'thread running list');
    ok(omnithreads->list(omnithreads::joinable) == 0, 'thread joinable list');
    ok(omnithreads->list(omnithreads::all) == 1, 'thread list');
    omnithreads->detach();
    do_thread();
    ok(omnithreads->is_detached(),   'thread detached');
    ok(omnithreads->list(omnithreads::running) == 0, 'thread running list');
    ok(omnithreads->list(omnithreads::joinable) == 0, 'thread joinable list');
    ok(omnithreads->list(omnithreads::all) == 0, 'thread list');
});

wait_until_ready();
ok($thr->is_running(),    'thread running');
ok(omnithreads->list(omnithreads::running) == 0,  'thread running list');
ok($thr->is_detached(),   'thread detached');
ok(! $thr->is_joinable(), 'thread not joinable');
ok(omnithreads->list(omnithreads::joinable) == 0, 'thread joinable list');
ok(omnithreads->list(omnithreads::all) == 0, 'thread list');

thread_go();
ok(! $thr->is_running(),  'thread not running');
ok(omnithreads->list(omnithreads::running) == 0,  'thread running list');
ok($thr->is_detached(),   'thread detached');
ok(! $thr->is_joinable(), 'thread not joinable');
ok(omnithreads->list(omnithreads::joinable) == 0, 'thread joinable list');

$thr = omnithreads->create(sub {
    ok(! omnithreads->is_detached(), 'thread not detached');
    ok(omnithreads->list(omnithreads::running) == 1, 'thread running list');
    ok(omnithreads->list(omnithreads::joinable) == 0, 'thread joinable list');
    ok(omnithreads->list(omnithreads::all) == 1, 'thread list');
})->join();

# EOF
