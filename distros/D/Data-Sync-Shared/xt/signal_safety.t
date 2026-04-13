use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(ualarm);

use Data::Sync::Shared;

# ============================================================
# SIGALRM during futex wait — verify no corruption
#
# The futex syscall returns EINTR on signal delivery.
# Our wait loops must handle this without corrupting state.
# ============================================================

# 1. Semaphore: SIGALRM during acquire
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 1, 0);
    my $alarms = 0;

    local $SIG{ALRM} = sub { $alarms++ };

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        # release after 200ms
        select(undef, undef, undef, 0.2);
        $sem->release;
        _exit(0);
    }

    # fire SIGALRM every 10ms while we wait
    ualarm(10_000, 10_000);
    my $ok = $sem->acquire(5.0);
    ualarm(0);

    waitpid($pid, 0);
    ok $ok, 'sem acquire survived SIGALRM interrupts';
    ok $alarms > 0, "received $alarms SIGALRM during wait";
    is $sem->value, 0, 'sem value correct after SIGALRM';
}

# 2. RWLock: SIGALRM during wrlock (contended)
{
    my $rw = Data::Sync::Shared::RWLock->new(undef);
    my $alarms = 0;

    local $SIG{ALRM} = sub { $alarms++ };

    $rw->rdlock;  # hold rdlock so wrlock blocks

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        select(undef, undef, undef, 0.2);
        $rw->rdunlock;
        _exit(0);
    }

    # fire SIGALRM every 10ms
    ualarm(10_000, 10_000);
    $rw->wrlock(5.0);
    ualarm(0);
    $rw->wrunlock;

    waitpid($pid, 0);
    ok $alarms > 0, "rwlock: received $alarms SIGALRM during wait";
    my $s = $rw->stats;
    is $s->{state}, 'unlocked', 'rwlock state clean after SIGALRM';
}

# 3. Condvar: SIGALRM during wait
{
    my $cv = Data::Sync::Shared::Condvar->new(undef);
    my $alarms = 0;

    local $SIG{ALRM} = sub { $alarms++ };

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        select(undef, undef, undef, 0.2);
        $cv->lock;
        $cv->signal;
        $cv->unlock;
        _exit(0);
    }

    $cv->lock;
    ualarm(10_000, 10_000);
    my $ok = $cv->wait(5.0);
    ualarm(0);
    $cv->unlock;

    waitpid($pid, 0);
    ok $ok, 'condvar wait survived SIGALRM';
    ok $alarms > 0, "condvar: received $alarms SIGALRM during wait";
}

# 4. Barrier: SIGALRM during wait
{
    my $bar = Data::Sync::Shared::Barrier->new(undef, 2);
    my $alarms = 0;

    local $SIG{ALRM} = sub { $alarms++ };

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        select(undef, undef, undef, 0.2);
        $bar->wait(5.0);
        _exit(0);
    }

    ualarm(10_000, 10_000);
    my $r = $bar->wait(5.0);
    ualarm(0);

    waitpid($pid, 0);
    ok $r >= 0, 'barrier wait survived SIGALRM';
    ok $alarms > 0, "barrier: received $alarms SIGALRM during wait";
    is $bar->generation, 1, 'barrier generation correct after SIGALRM';
}

# 5. Once: SIGALRM during enter (waiting for initializer)
{
    my $once = Data::Sync::Shared::Once->new(undef);
    my $alarms = 0;

    local $SIG{ALRM} = sub { $alarms++ };

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $once->enter;
        select(undef, undef, undef, 0.2);
        $once->done;
        _exit(0);
    }

    select(undef, undef, undef, 0.05);  # let child claim initializer
    ualarm(10_000, 10_000);
    my $r = $once->enter(5.0);
    ualarm(0);

    waitpid($pid, 0);
    ok !$r, 'once enter returned false (waited)';
    ok $once->is_done, 'once is done after SIGALRM';
    ok $alarms > 0, "once: received $alarms SIGALRM during wait";
}

done_testing;
