use strict;
use warnings;
use Test::More;

use Data::Sync::Shared;

# ============================================================
# 1. Rapid create/destroy cycles — Semaphore
# ============================================================
{
    for my $round (1..5000) {
        my $sem = Data::Sync::Shared::Semaphore->new(undef, 10);
        $sem->try_acquire;
        $sem->release;
        # $sem goes out of scope — DESTROY fires
    }
    pass 'semaphore: 5000 create/destroy cycles';
}

# ============================================================
# 2. Rapid create/destroy cycles — RWLock
# ============================================================
{
    for my $round (1..5000) {
        my $rw = Data::Sync::Shared::RWLock->new(undef);
        $rw->rdlock;
        $rw->rdunlock;
        $rw->wrlock;
        $rw->wrunlock;
    }
    pass 'rwlock: 5000 create/destroy cycles';
}

# ============================================================
# 3. Rapid create/destroy cycles — Condvar
# ============================================================
{
    for my $round (1..5000) {
        my $cv = Data::Sync::Shared::Condvar->new(undef);
        $cv->lock;
        $cv->unlock;
    }
    pass 'condvar: 5000 create/destroy cycles';
}

# ============================================================
# 4. Rapid create/destroy cycles — Barrier
# ============================================================
{
    for my $round (1..5000) {
        my $bar = Data::Sync::Shared::Barrier->new(undef, 2);
    }
    pass 'barrier: 5000 create/destroy cycles';
}

# ============================================================
# 5. Rapid create/destroy cycles — Once
# ============================================================
{
    for my $round (1..5000) {
        my $once = Data::Sync::Shared::Once->new(undef);
        $once->enter;
        $once->done;
    }
    pass 'once: 5000 create/enter/done/destroy cycles';
}

# ============================================================
# 6. Multiple handles to same file — Semaphore
# ============================================================
{
    use File::Temp qw(tmpnam);
    my $path = tmpnam() . '.shm';

    my $sem1 = Data::Sync::Shared::Semaphore->new($path, 5);
    my @handles;
    for (1..100) {
        push @handles, Data::Sync::Shared::Semaphore->new($path, 5);
    }

    $sem1->try_acquire;
    is $handles[-1]->value, 4, 'multi-handle: cross-handle visibility';

    @handles = ();  # destroy all
    pass 'multi-handle: 100 handles destroyed without crash';

    # original still works
    $sem1->release;
    is $sem1->value, 5, 'multi-handle: original functional after mass destroy';

    $sem1->unlink;
}

# ============================================================
# 7. Use after explicit undef — should croak, not crash
# ============================================================
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 3);
    $sem->DESTROY;  # explicitly destroy, nullifies inner pointer

    eval { $sem->value };
    ok $@, 'use-after-destroy: croak not crash';
    like $@, qr/destroyed/, 'use-after-destroy: error mentions destroyed';
}

# ============================================================
# 8. eventfd lifecycle — create, use, destroy
# ============================================================
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 10);
    is $sem->fileno, -1, 'eventfd: -1 before create';

    my $fd = $sem->eventfd;
    ok $fd >= 0, 'eventfd: valid fd after create';
    is $sem->fileno, $fd, 'eventfd: fileno returns created fd';

    ok $sem->notify, 'eventfd: notify succeeds';
    my $v = $sem->eventfd_consume;
    is $v, 1, 'eventfd: consume returns 1';

    # Second create replaces the old one
    my $fd2 = $sem->eventfd;
    ok $fd2 >= 0, 'eventfd: second create works';
    is $sem->fileno, $fd2, 'eventfd: fileno returns new fd';
}

# ============================================================
# 9. memfd lifecycle — create, open, use, destroy
# ============================================================
{
    my $sem = Data::Sync::Shared::Semaphore->new_memfd("lifecycle_test", 5);
    my $fd = $sem->memfd;
    ok $fd >= 0, 'memfd: valid fd';

    my $sem2 = Data::Sync::Shared::Semaphore->new_from_fd($fd);
    $sem->try_acquire;
    is $sem2->value, 4, 'memfd: cross-handle via fd';

    undef $sem;  # destroy original
    is $sem2->value, 4, 'memfd: handle survives after original destroy';

    $sem2->release;
    is $sem2->value, 5, 'memfd: ops work after original destroyed';
}

done_testing;
