use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Sync::Shared;

my $path = tmpnam() . '.shm';
END { unlink $path if $path && -f $path }

# Basic create
my $rw = Data::Sync::Shared::RWLock->new($path);
ok $rw, 'created rwlock';

# Read lock
$rw->rdlock;
my $s = $rw->stats;
is $s->{state}, 'read_locked', 'state is read_locked';
is $s->{readers}, 1, '1 reader';

# Multiple readers
$rw->rdlock;
$s = $rw->stats;
is $s->{readers}, 2, '2 readers';
$rw->rdunlock;
$rw->rdunlock;

$s = $rw->stats;
is $s->{state}, 'unlocked', 'unlocked after rdunlock';

# Write lock
$rw->wrlock;
$s = $rw->stats;
is $s->{state}, 'write_locked', 'state is write_locked';
is $s->{readers}, 0, '0 readers during write';
$rw->wrunlock;

$s = $rw->stats;
is $s->{state}, 'unlocked', 'unlocked after wrunlock';

# try_rdlock / try_wrlock
ok $rw->try_rdlock, 'try_rdlock succeeds when free';
ok !$rw->try_wrlock, 'try_wrlock fails when readers hold';
$rw->rdunlock;

ok $rw->try_wrlock, 'try_wrlock succeeds when free';
ok !$rw->try_rdlock, 'try_rdlock fails when writer holds';
ok !$rw->try_wrlock, 'try_wrlock fails when writer holds';
$rw->wrunlock;

# Downgrade: wrlock -> rdlock
$rw->wrlock;
$s = $rw->stats;
is $s->{state}, 'write_locked', 'write_locked before downgrade';
$rw->downgrade;
$s = $rw->stats;
is $s->{state}, 'read_locked', 'read_locked after downgrade';
is $s->{readers}, 1, '1 reader after downgrade';
ok $rw->try_rdlock, 'can rdlock after downgrade';
$rw->rdunlock;
$rw->rdunlock;

# Path
is $rw->path, $path, 'path correct';

# Reopen existing
my $rw2 = Data::Sync::Shared::RWLock->new($path);
ok $rw2, 'reopened existing rwlock';
$rw->rdlock;
$s = $rw2->stats;
is $s->{readers}, 1, 'cross-handle visibility';
$rw->rdunlock;

# Multiprocess readers
{
    my $mp = Data::Sync::Shared::RWLock->new(undef);
    $mp->rdlock;

    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        # Child should also be able to rdlock
        my $got = $mp->try_rdlock ? 1 : 0;
        $mp->rdunlock if $got;
        _exit($got);
    }
    waitpid($pid, 0);
    is $? >> 8, 1, 'child acquired concurrent rdlock';
    $mp->rdunlock;
}

# Multiprocess writer exclusion
{
    my $mp = Data::Sync::Shared::RWLock->new(undef);
    $mp->wrlock;

    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $got = $mp->try_wrlock ? 1 : 0;
        $mp->wrunlock if $got;
        _exit($got);
    }
    waitpid($pid, 0);
    is $? >> 8, 0, 'child could not wrlock while parent holds';
    $mp->wrunlock;
}

# Stats
$s = $rw->stats;
ok $s->{acquires} > 0, 'stats acquires';
ok $s->{releases} > 0, 'stats releases';

# Anonymous
my $arw = Data::Sync::Shared::RWLock->new(undef);
ok $arw, 'anonymous rwlock';
is $arw->path, undef, 'anonymous has no path';

# memfd
my $mrw = Data::Sync::Shared::RWLock->new_memfd("test_rw");
ok $mrw, 'memfd rwlock';
ok $mrw->memfd >= 0, 'memfd returns valid fd';
my $mrw2 = Data::Sync::Shared::RWLock->new_from_fd($mrw->memfd);
ok $mrw2, 'new_from_fd';

# rdlock_timed / wrlock_timed — non-croaking timeout variants
{
    my $rw2 = Data::Sync::Shared::RWLock->new(undef);

    # Available → succeeds
    ok $rw2->rdlock_timed(0.1), 'rdlock_timed succeeds when free';
    $rw2->rdunlock;
    ok $rw2->wrlock_timed(0.1), 'wrlock_timed succeeds when free';
    $rw2->wrunlock;

    # Contended → returns false without croaking
    my $pid = fork // die;
    if ($pid == 0) {
        $rw2->wrlock;
        sleep 1;
        $rw2->wrunlock;
        _exit(0);
    }
    select(undef, undef, undef, 0.1);   # let child grab the lock
    ok !$rw2->rdlock_timed(0.1), 'rdlock_timed returns false on contention';
    ok !$rw2->wrlock_timed(0.1), 'wrlock_timed returns false on contention';
    waitpid($pid, 0);
    # After child releases, locks are available again
    ok $rw2->wrlock_timed(0.1), 'wrlock_timed succeeds after contender releases';
    $rw2->wrunlock;
}

# Unlink
$rw->unlink;
ok !-f $path, 'unlink removed file';

done_testing;
