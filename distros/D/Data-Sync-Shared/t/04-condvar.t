use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Sync::Shared;

my $path = tmpnam() . '.shm';
END { unlink $path if $path && -f $path }

# Basic create
my $cv = Data::Sync::Shared::Condvar->new($path);
ok $cv, 'created condvar';

# Lock/unlock
$cv->lock;
ok 1, 'lock acquired';
$cv->unlock;
ok 1, 'unlock done';

# try_lock
ok $cv->try_lock, 'try_lock succeeds';
$cv->unlock;

# try_lock fails when held
{
    my $c = Data::Sync::Shared::Condvar->new(undef);
    $c->lock;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $got = $c->try_lock ? 1 : 0;
        $c->unlock if $got;
        _exit($got);
    }
    waitpid($pid, 0);
    is $? >> 8, 0, 'try_lock fails when another process holds';
    $c->unlock;
}

# wait(0) is non-blocking
{
    my $c = Data::Sync::Shared::Condvar->new(undef);
    $c->lock;
    my $t0 = time;
    my $r = $c->wait(0);
    ok !$r, 'wait(0) returns false immediately';
    ok time - $t0 < 0.1, 'wait(0) did not block';
    $c->unlock;
}

# Wait with timeout (no signal, should timeout)
$cv->lock;
my $t0 = time;
my $r = $cv->wait(0.1);
ok !$r, 'wait timeout returns false';
cmp_ok time - $t0, '<', 30, 'wait returned (not hung)';
$cv->unlock;

# Signal wakes waiter
{
    my $c = Data::Sync::Shared::Condvar->new(undef);

    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        $c->lock;
        my $got = $c->wait(5.0);
        $c->unlock;
        _exit($got ? 0 : 1);
    }

    # Give child time to enter wait
    select(undef, undef, undef, 0.1);

    $c->lock;
    $c->signal;
    $c->unlock;

    waitpid($pid, 0);
    is $? >> 8, 0, 'child was signaled';
}

# Broadcast wakes all waiters
{
    my $c = Data::Sync::Shared::Condvar->new(undef);
    my @pids;

    for my $i (1..3) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            $c->lock;
            my $got = $c->wait(5.0);
            $c->unlock;
            _exit($got ? 0 : 1);
        }
        push @pids, $pid;
    }

    select(undef, undef, undef, 0.1);

    $c->lock;
    $c->broadcast;
    $c->unlock;

    for my $pid (@pids) {
        waitpid($pid, 0);
        is $? >> 8, 0, "child $pid woke from broadcast";
    }
}

# Path
is $cv->path, $path, 'path correct';

# Reopen existing
my $cv2 = Data::Sync::Shared::Condvar->new($path);
ok $cv2, 'reopened existing condvar';

# Stats
my $s = $cv->stats;
ok defined $s->{waiters}, 'stats has waiters';
ok defined $s->{signals}, 'stats has signals';

# Anonymous
my $acv = Data::Sync::Shared::Condvar->new(undef);
ok $acv, 'anonymous condvar';
is $acv->path, undef, 'anonymous has no path';

# memfd
my $mcv = Data::Sync::Shared::Condvar->new_memfd("test_cv");
ok $mcv, 'memfd condvar';
ok $mcv->memfd >= 0, 'memfd returns valid fd';

# Unlink
$cv->unlink;
ok !-f $path, 'unlink removed file';

done_testing;
