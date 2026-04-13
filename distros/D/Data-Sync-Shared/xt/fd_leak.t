use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use Data::Sync::Shared;

sub fd_count {
    opendir my $dh, "/proc/$$/fd" or die "opendir /proc/$$/fd: $!";
    my @fds = grep { /^\d+$/ } readdir $dh;
    closedir $dh;
    scalar @fds;
}

plan skip_all => 'requires /proc/self/fd' unless -d "/proc/$$/fd";

my $N = 2000;

# Baseline fd count
my $base = fd_count();
diag "baseline fd count: $base";

# ============================================================
# 1. Anonymous primitives: no fd leak
# ============================================================
{
    for (1..$N) {
        my $sem = Data::Sync::Shared::Semaphore->new(undef, 10);
        $sem->try_acquire;
        $sem->release;
    }
    my $after = fd_count();
    ok $after <= $base + 5, "anonymous sem: no fd leak ($after fds, base=$base)";
}

{
    for (1..$N) {
        my $rw = Data::Sync::Shared::RWLock->new(undef);
        $rw->rdlock;
        $rw->rdunlock;
    }
    my $after = fd_count();
    ok $after <= $base + 5, "anonymous rwlock: no fd leak ($after fds)";
}

{
    for (1..$N) {
        my $cv = Data::Sync::Shared::Condvar->new(undef);
        $cv->lock;
        $cv->unlock;
    }
    my $after = fd_count();
    ok $after <= $base + 5, "anonymous condvar: no fd leak ($after fds)";
}

{
    for (1..$N) {
        my $bar = Data::Sync::Shared::Barrier->new(undef, 2);
    }
    my $after = fd_count();
    ok $after <= $base + 5, "anonymous barrier: no fd leak ($after fds)";
}

{
    for (1..$N) {
        my $once = Data::Sync::Shared::Once->new(undef);
        $once->enter;
        $once->done;
    }
    my $after = fd_count();
    ok $after <= $base + 5, "anonymous once: no fd leak ($after fds)";
}

# ============================================================
# 2. File-backed: no fd leak
# ============================================================
{
    my $path = tmpnam() . '.shm';
    for (1..$N) {
        my $sem = Data::Sync::Shared::Semaphore->new($path, 10);
    }
    unlink $path;
    my $after = fd_count();
    ok $after <= $base + 5, "file-backed sem: no fd leak ($after fds)";
}

# ============================================================
# 3. memfd: no fd leak
# ============================================================
{
    for (1..$N) {
        my $sem = Data::Sync::Shared::Semaphore->new_memfd("test", 10);
    }
    my $after = fd_count();
    ok $after <= $base + 5, "memfd sem: no fd leak ($after fds)";
}

# ============================================================
# 4. memfd + new_from_fd: no fd leak
# ============================================================
{
    for (1..$N) {
        my $sem = Data::Sync::Shared::Semaphore->new_memfd("test", 10);
        my $fd = $sem->memfd;
        my $sem2 = Data::Sync::Shared::Semaphore->new_from_fd($fd);
    }
    my $after = fd_count();
    ok $after <= $base + 5, "memfd new_from_fd: no fd leak ($after fds)";
}

# ============================================================
# 5. eventfd: no fd leak
# ============================================================
{
    for (1..$N) {
        my $sem = Data::Sync::Shared::Semaphore->new(undef, 10);
        $sem->eventfd;
        $sem->notify;
        $sem->eventfd_consume;
    }
    my $after = fd_count();
    ok $after <= $base + 5, "eventfd: no fd leak ($after fds)";
}

# ============================================================
# 6. Error paths: no fd leak
# ============================================================
{
    for (1..$N) {
        eval { Data::Sync::Shared::Semaphore->new_from_fd(9999) };
    }
    my $after = fd_count();
    ok $after <= $base + 5, "error path new_from_fd: no fd leak ($after fds)";
}

{
    my $path = tmpnam() . '.shm';
    my $sem = Data::Sync::Shared::Semaphore->new($path, 5);
    for (1..$N) {
        eval { Data::Sync::Shared::Barrier->new($path, 3) };  # type mismatch
    }
    unlink $path;
    my $after = fd_count();
    ok $after <= $base + 5, "error path type mismatch: no fd leak ($after fds)";
}

diag "final fd count: " . fd_count();

done_testing;
