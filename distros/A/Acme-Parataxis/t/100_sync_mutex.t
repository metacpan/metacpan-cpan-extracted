use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield await_sleep with_timeout];
use Acme::Parataxis::Sync::Mutex;
use Test2::V1 -ipP;
$|++;
subtest 'mutual exclusion: N fibers increment a shared counter' => sub {
    my $m     = Acme::Parataxis::Sync::Mutex->new;
    my $count = 0;
    async {
        my @fs = map {
            fiber {
                $m->lock;
                my $v = $count;
                yield;
                $count = $v + 1;
                $m->unlock;
            }
        } 1 .. 10;
        $_->await for @fs;
        is $count, 10, 'all 10 increments landed with no lost updates';
        ok !defined $m->owner, 'owner is cleared once everyone releases';
    };
};
subtest 'contention: waiters are handed the lock in FIFO order' => sub {
    my $m   = Acme::Parataxis::Sync::Mutex->new;
    my $log = '';
    async {
        my $a = fiber {
            $m->lock;
            await_sleep(10);    # hold the lock across a park so the others pile up
            $log .= 'A';
            $m->unlock;
        };
        my @bs = map {
            my $i = $_;
            fiber {
                $m->lock;
                $log .= "B$i";
                $m->unlock;
            }
        } 1 .. 3;
        is $m->waiters, 3, 'three fibers are parked on the lock while A holds it';
        $a->await;
        $_->await for @bs;
        is $log, 'AB1B2B3', 'holders ran strictly one at a time in FIFO order';
    };
};
subtest 'try_lock is non-blocking and never steals' => sub {
    my $m = Acme::Parataxis::Sync::Mutex->new;
    async {
        my $a = fiber {
            $m->lock;
            await_sleep(10);
            $m->unlock;
        };
        ok !$m->try_lock, 'try_lock returns 0 while another fiber holds the lock';
        is $m->owner, $a->fid, 'the lock still belongs to its owner';
        $a->await;
        ok $m->try_lock, 'try_lock succeeds once the lock is free';
        is $m->owner, Acme::Parataxis->current_fid, 'and takes ownership for this fiber';
        $m->unlock;
    };
};
subtest 'releasing from a non-owner croaks; the owner still releases' => sub {
    my $m = Acme::Parataxis::Sync::Mutex->new;
    my ( $foreign, $owner_ok, $usable );
    async {
        my $a = fiber {
            $m->lock;
            my $b = fiber {
                $foreign = dies { $m->unlock };
                await_sleep(1);    # hang around a moment as a live non-owner
            };
            $b->await;
            $owner_ok = dies { $m->unlock };
            my $c = fiber { $m->lock; $m->unlock; 1 };
            $usable = $c->await;
        };
        $a->await;
    };
    like $foreign, qr/not the owner/, 'a non-owner fiber cannot release the lock';
    ok !$owner_ok, 'the true owner can';
    is $usable, 1, 'the lock is fully usable again after the failed foreign release';
};
subtest 'unlocking a free mutex and relocking the same fiber croak' => sub {
    my $m = Acme::Parataxis::Sync::Mutex->new;
    async {
        like dies { $m->unlock }, qr/not locked/, 'unlock on a free mutex croaks';
        $m->lock;
        like dies { $m->lock },     qr/not reentrant/, 'holding the lock already croaks a second lock()';
        like dies { $m->try_lock }, qr/not reentrant/, 'try_lock also croaks when this fiber holds it';
        $m->unlock;
    };
};
subtest 'the guard auto-releases at end of scope, including on an exception' => sub {
    my $m = Acme::Parataxis::Sync::Mutex->new;
    async {
        {
            my $guard = $m->guard;
            ok defined $m->owner, 'guard holds the lock';
        }
        ok !defined $m->owner, 'lock released when the guard goes out of scope';
        {
            my $guard = $m->guard;
            eval { die 'boom' };
        }
        ok !defined $m->owner, 'lock released even when the scope unwinds on an exception';
    };
};
subtest 'an interrupted lock() unregisters so the next holder is served' => sub {
    my $m   = Acme::Parataxis::Sync::Mutex->new;
    my $log = '';
    my $err;
    async {
        my $a = fiber {

            # A long hold widens the scheduling margin so the 10ms deadline in the
            # with_timeout below cannot lose the race: the block must never acquire
            # the lock (it finishes without unlocking, stranding the owner on a dead
            # fiber and deadlocking the next waiter). macOS/Windows flakes fired the
            # timer up to ~24ms late, right as a 30ms hand-off completed (pthread
            # deadlock here, "not reentrant" on fid reuse there).
            $m->lock;
            await_sleep(2000);
            $log .= 'A';
            $m->unlock;
        };
        $err = dies {
            with_timeout( 10, sub { $m->lock; $log .= 'B' } );
        };
        is $m->waiters, 0, 'the timed-out waiter removed itself from the queue';
        my $c = fiber {
            $m->lock;
            $log .= 'C';
            $m->unlock;
        };
        $a->await;
        $c->await;
    };
    ok ref($err) && $err->isa('Acme::Parataxis::Error::Timeout'), 'the block timed out instead of deadlocking';
    is $log, 'AC', 'the cancelled waiter got no lock; the next waiter did';
};
subtest 'lock/try_lock/unlock croak outside a scheduled fiber' => sub {
    my $m = Acme::Parataxis::Sync::Mutex->new;
    like dies { $m->lock },     qr/scheduled fiber/, 'lock croaks';
    like dies { $m->try_lock }, qr/scheduled fiber/, 'try_lock croaks';
    like dies { $m->unlock },   qr/scheduled fiber/, 'unlock croaks';
    like dies { $m->guard },    qr/scheduled fiber/, 'guard croaks';
};
#
done_testing;
