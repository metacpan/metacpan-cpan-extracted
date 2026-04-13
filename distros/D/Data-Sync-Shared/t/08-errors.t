use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Sync::Shared;

# ============================================================
# Constructor error paths
# ============================================================

# Semaphore: max=0
eval { Data::Sync::Shared::Semaphore->new(undef, 0) };
like $@, qr/max must be/, 'sem max=0 croaks';

# Semaphore: initial > max
eval { Data::Sync::Shared::Semaphore->new(undef, 5, 10) };
like $@, qr/initial.*max/i, 'sem initial > max croaks';

# Barrier: parties=0
eval { Data::Sync::Shared::Barrier->new(undef, 0) };
like $@, qr/count must be/, 'barrier parties=0 croaks';

# Barrier: parties=1
eval { Data::Sync::Shared::Barrier->new(undef, 1) };
like $@, qr/count must be/, 'barrier parties=1 croaks';

# ============================================================
# Type mismatch on reopen
# ============================================================

{
    my $path = tmpnam() . '.shm';
    my $sem = Data::Sync::Shared::Semaphore->new($path, 5);

    eval { Data::Sync::Shared::Barrier->new($path, 3) };
    like $@, qr/invalid or incompatible/, 'type mismatch on reopen croaks';

    eval { Data::Sync::Shared::RWLock->new($path) };
    like $@, qr/invalid or incompatible/, 'rwlock on sem file croaks';

    eval { Data::Sync::Shared::Once->new($path) };
    like $@, qr/invalid or incompatible/, 'once on sem file croaks';

    $sem->unlink;
}

# ============================================================
# Invalid fd for new_from_fd
# ============================================================

eval { Data::Sync::Shared::Semaphore->new_from_fd(9999) };
like $@, qr/fstat/, 'invalid fd croaks with fstat error';

# ============================================================
# memfd: type mismatch on new_from_fd
# ============================================================

{
    my $sem = Data::Sync::Shared::Semaphore->new_memfd("test", 5);
    my $fd = $sem->memfd;

    eval { Data::Sync::Shared::Barrier->new_from_fd($fd) };
    like $@, qr/invalid or incompatible/, 'type mismatch on memfd croaks';
}

# ============================================================
# Unlink errors
# ============================================================

# unlink on anonymous
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 3);
    eval { $sem->unlink };
    like $@, qr/cannot unlink anonymous/, 'unlink anonymous croaks';
}

# Class-method unlink without path
eval { Data::Sync::Shared::Semaphore->unlink };
like $@, qr/Usage/, 'class unlink without path croaks';

# ============================================================
# Use after DESTROY
# ============================================================

{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 3);
    $sem->DESTROY;
    eval { $sem->value };
    like $@, qr/destroyed/, 'use after destroy croaks';
}

{
    my $rw = Data::Sync::Shared::RWLock->new(undef);
    $rw->DESTROY;
    eval { $rw->rdlock };
    like $@, qr/destroyed/, 'rwlock use after destroy croaks';
}

# ============================================================
# Concurrent open (validates flock init fix)
# ============================================================

{
    my $path = tmpnam() . '.shm';
    unlink $path if -f $path;

    my @pids;
    for (1..5) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            eval {
                my $sem = Data::Sync::Shared::Semaphore->new($path, 10);
                $sem->try_acquire;
                $sem->release;
            };
            _exit($@ ? 1 : 0);
        }
        push @pids, $pid;
    }

    my $ok = 1;
    for my $pid (@pids) {
        waitpid($pid, 0);
        $ok = 0 if ($? >> 8) != 0;
    }

    ok $ok, 'concurrent open: 5 processes opened same file';

    my $sem = Data::Sync::Shared::Semaphore->new($path, 10);
    is $sem->max, 10, 'concurrent open: header is valid';
    unlink $path;
}

done_testing;
