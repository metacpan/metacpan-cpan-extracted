use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Sync::Shared;

my $path = tmpnam() . '.shm';
END { unlink $path if $path && -f $path }

# Basic create
my $sem = Data::Sync::Shared::Semaphore->new($path, 3);
ok $sem, 'created semaphore';
is $sem->max, 3, 'max is 3';
is $sem->value, 3, 'starts fully available';

# Acquire/release
ok $sem->try_acquire, 'try_acquire 1';
is $sem->value, 2, 'value 2';
ok $sem->try_acquire, 'try_acquire 2';
ok $sem->try_acquire, 'try_acquire 3';
is $sem->value, 0, 'value 0';
ok !$sem->try_acquire, 'try_acquire fails at 0';

$sem->release;
is $sem->value, 1, 'release -> 1';
$sem->release(2);
is $sem->value, 3, 'release(2) -> 3';

# Release clamps at max
$sem->release;
is $sem->value, 3, 'release clamps at max';

# Blocking acquire with timeout
$sem->try_acquire for 1..3;
is $sem->value, 0, 'drained';
my $t0 = time;
ok !$sem->acquire(0.1), 'acquire with timeout returns false';
ok time - $t0 < 2, 'did not hang';

$sem->release(3);

# Blocking acquire (infinite, but succeeds immediately)
ok $sem->acquire, 'blocking acquire succeeds when available';
is $sem->value, 2, 'value 2 after acquire';
$sem->release;

# Path
is $sem->path, $path, 'path correct';

# Reopen existing file
my $sem2 = Data::Sync::Shared::Semaphore->new($path, 3);
ok $sem2, 'reopened existing semaphore';
$sem->try_acquire;
is $sem2->value, 2, 'cross-handle visibility';
$sem->release;

# Stats
my $s = $sem->stats;
ok $s->{acquires} > 0, 'stats acquires';
ok $s->{releases} > 0, 'stats releases';
is $s->{max}, 3, 'stats max';

# Anonymous
my $asem = Data::Sync::Shared::Semaphore->new(undef, 2);
ok $asem, 'anonymous semaphore';
is $asem->path, undef, 'anonymous has no path';
ok $asem->try_acquire, 'anonymous acquire';
$asem->release;

# memfd
my $msem = Data::Sync::Shared::Semaphore->new_memfd("test_sem", 5);
ok $msem, 'memfd semaphore';
my $fd = $msem->memfd;
ok $fd >= 0, 'memfd returns valid fd';
my $msem2 = Data::Sync::Shared::Semaphore->new_from_fd($fd);
ok $msem2, 'new_from_fd';
$msem->try_acquire;
is $msem2->value, 4, 'memfd cross-handle visibility';

# Multiprocess
{
    my $mp = Data::Sync::Shared::Semaphore->new(undef, 1);
    $mp->try_acquire;  # take the only permit
    is $mp->value, 0, 'parent holds permit';

    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        # Child: try_acquire should fail
        my $got = $mp->try_acquire ? 1 : 0;
        _exit($got);
    }
    waitpid($pid, 0);
    is $? >> 8, 0, 'child could not acquire held semaphore';

    $mp->release;

    $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $got = $mp->try_acquire ? 1 : 0;
        _exit($got);
    }
    waitpid($pid, 0);
    is $? >> 8, 1, 'child acquired released semaphore';
}

# drain
{
    my $ds = Data::Sync::Shared::Semaphore->new(undef, 10);
    is $ds->drain, 10, 'drain returns all permits';
    is $ds->value, 0, 'drain leaves 0';
    is $ds->drain, 0, 'drain on empty returns 0';
    $ds->release(5);
    is $ds->drain, 5, 'drain after partial release';
}

# release(0) is a no-op
{
    my $rs = Data::Sync::Shared::Semaphore->new(undef, 3);
    $rs->try_acquire;
    is $rs->value, 2, 'before release(0)';
    $rs->release(0);
    is $rs->value, 2, 'release(0) is no-op';
}

# release_n overflow clamp
{
    my $os = Data::Sync::Shared::Semaphore->new(undef, 10);
    $os->try_acquire for 1..10;
    $os->release(0xFFFFFFFF);
    is $os->value, 10, 'release(huge) clamps at max';
}

# Unlink
$sem->unlink;
ok !-f $path, 'unlink removed file';

done_testing;
