use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield await_sleep with_timeout];
use Acme::Parataxis::Sync::RwLock;
use Test2::V1 -ipP;
$|++;
subtest 'concurrent readers run together, then all release' => sub {
    my $rw     = Acme::Parataxis::Sync::RwLock->new;
    my $inside = 0;
    my $max    = 0;
    async {
        my @rs = map {
            fiber {
                $rw->read_lock;
                $inside++;
                $max = $inside if $inside > $max;
                yield;    # stay inside the read section across a park
                $inside--;
                $rw->read_unlock;
            }
        } 1 .. 3;
        is $rw->readers,      3, 'three fibers hold the lock shared at the same time';
        is $rw->read_holders, 3, 'for three distinct fibers';
        is $rw->waiters,      0, 'nobody had to park to get in';
        $_->await for @rs;
        is $rw->readers, 0, 'every read hold was released';
        is $inside,      0, 'and the critical sections all unwound';
    };
    is $max, 3, 'all three readers were inside the section together';
};
subtest 'a queued writer blocks new readers until it has run (no writer starvation)' => sub {
    my $rw = Acme::Parataxis::Sync::RwLock->new;
    my @log;
    async {
        my $a = fiber { $rw->read_lock; push @log, 'A+'; await_sleep(60); push @log, 'A-'; $rw->read_unlock };
        is $rw->readers,      1, 'A holds a shared read lock';
        is $rw->read_holders, 1, 'for exactly one fiber';
        my $w = fiber { $rw->write_lock; push @log, 'W+'; await_sleep(30); push @log, 'W-'; $rw->write_unlock };
        is $rw->write_waiters, 1, 'the writer parked waiting for the readers to drain';
        ok !defined $rw->writer, 'and does not hold the lock yet';
        my $r = fiber { $rw->read_lock; push @log, 'R+'; push @log, 'R-'; $rw->read_unlock };
        is $rw->read_waiters, 1, 'a reader arriving behind a queued writer is held back';
        is $rw->readers,      1, 'and does not slip in alongside it';
        $a->await;
        $w->await;
        $r->await;
        is $rw->readers, 0, 'every read hold released';
        ok !defined $rw->writer, 'and the write lock released';
        is $rw->waiters, 0, 'nobody left parked';
    };
    is join( ',', @log ), 'A+,A-,W+,W-,R+,R-', 'the writer ran between the readers and the late reader waited behind it';
};
subtest 'readers parked behind a writer are all released together' => sub {
    my $rw     = Acme::Parataxis::Sync::RwLock->new;
    my $inside = 0;
    my $max    = 0;
    async {
        my $w  = fiber { $rw->write_lock; await_sleep(20); $rw->write_unlock };
        my @rs = map {
            fiber {
                $rw->read_lock;
                $inside++;
                $max = $inside if $inside > $max;
                yield;
                $inside--;
                $rw->read_unlock;
            }
        } 1 .. 3;
        is $rw->read_waiters, 3, 'all three readers parked behind the writer';
        is $rw->readers,      0, 'and none got in while it held the lock';
        $w->await;
        $_->await for @rs;
        is $max,         3, 'once the writer left, all three readers ran together';
        is $inside,      0, 'and all of them released';
        is $rw->waiters, 0, 'the lock drained completely';
    };
};
subtest 'writers are handed the lock over in FIFO order' => sub {
    my $rw    = Acme::Parataxis::Sync::RwLock->new;
    my $order = '';
    async {
        my $a  = fiber { $rw->write_lock; await_sleep(20); $rw->write_unlock };
        my @ws = map {
            my $i = $_;
            fiber { $rw->write_lock; $order .= $i; $rw->write_unlock }
        } 1 .. 3;
        is $rw->write_waiters, 3, 'three writers queued behind the holder';
        is $rw->waiters,       3, 'and they are the only parked waiters';
        ok !defined $rw->writer || $rw->writer == $a->fid, 'the lock still belongs to the first holder';
        $_->await for $a, @ws;
        is $order,       '123', 'each writer ran strictly one at a time, in arrival order';
        is $rw->waiters, 0,     'the queue drained';
    };
};
subtest 'try_* never parks and never steals a queued turn' => sub {
    my $rw = Acme::Parataxis::Sync::RwLock->new;
    async {
        my $holder = fiber { $rw->write_lock; await_sleep(40); $rw->write_unlock };
        ok !$rw->try_write_lock, 'try_write_lock is false while another fiber writes';
        ok !$rw->try_read_lock,  'try_read_lock is false while another fiber writes';
        is $rw->waiters, 0, 'neither try_* parked the caller';
        my $queued = fiber { $rw->write_lock; $rw->write_unlock };
        is $rw->write_waiters, 1, 'a writer queued behind the holder';
        ok !$rw->try_write_lock, 'try_write_lock still refuses with a writer queued - it never cuts the line';
        ok !$rw->try_read_lock,  'try_read_lock refuses while a writer is queued';
        is $rw->read_waiters, 0, 'and it parked nobody';
        $holder->await;
        $queued->await;
        ok $rw->try_read_lock, 'try_read_lock succeeds on a free lock';
        is $rw->readers, 1, 'and took a shared hold';
        like dies { $rw->try_write_lock }, qr/upgrading/,
            'try_write_lock croaks on a read hold rather than quietly refusing an upgrade that can never succeed';
        is $rw->readers, 1, 'and the refused attempt left the read hold intact';
        $rw->read_unlock;
        ok $rw->try_write_lock, 'try_write_lock succeeds once the lock is fully free';
        is $rw->writer, Acme::Parataxis->current_fid, 'and records this fiber as the writer';
        like dies { $rw->try_write_lock }, qr/not reentrant/, 'a second try_write_lock croaks';
        $rw->write_unlock;
        ok !defined $rw->writer, 'released cleanly';
        is $rw->waiters, 0, 'no waiters left behind';
    };
};
subtest 'write_unlock from a non-owner croaks; the true writer still releases' => sub {
    my $rw = Acme::Parataxis::Sync::RwLock->new;
    my ( $foreign, $owner_ok, $usable, $free );
    async {
        like dies { $rw->write_unlock }, qr/not write-held/,     'unlocking an unheld write lock croaks';
        like dies { $rw->read_unlock },  qr/holds no read lock/, 'releasing an unheld read lock croaks';
        my $a = fiber {
            $rw->write_lock;
            my $b = fiber {
                $foreign = dies { $rw->write_unlock };
                await_sleep(1)
            };
            $b->await;
            $owner_ok = dies { $rw->write_unlock };
            my $c = fiber { $rw->write_lock; $rw->write_unlock; 1 };
            $usable = $c->await;
        };
        $a->await;
        $free = !defined $rw->writer;
    };
    like $foreign, qr/not the writer/, 'a non-writer fiber cannot release the write lock';
    ok !$owner_ok, 'the true writer can';
    is $usable, 1, 'the lock is fully usable again after the failed foreign release';
    ok $free, 'and nobody is left holding it';
};
subtest 'guards release at scope end, including on an exception' => sub {
    my $rw = Acme::Parataxis::Sync::RwLock->new;
    async {
        {
            my $g = $rw->read_guard;
            is $rw->readers, 1, 'a read guard takes a shared hold';
        }
        is $rw->readers, 0, 'released when the scope ended';
        {
            my $g = $rw->write_guard;
            ok defined $rw->writer, 'a write guard takes the write lock';
        }
        ok !defined $rw->writer, 'released when the scope ended';
        {
            my $g = $rw->write_guard;
            eval { die 'boom' };
        }
        ok !defined $rw->writer, 'released even when the scope unwound on an exception';
        {
            my $outer = $rw->read_guard;
            {
                my $inner = $rw->read_guard;
                is $rw->readers, 2, 'nested read guards deepen the hold in place';
            }
            is $rw->readers, 1, 'the inner guard released only its own hold';
        }
        is $rw->readers, 0, 'the outer guard released the rest';
        is $rw->waiters, 0, 'nothing left parked';
    };
};
subtest 'the read side is reentrant; a read-to-write upgrade croaks' => sub {
    my $rw = Acme::Parataxis::Sync::RwLock->new;
    async {
        $rw->read_lock;
        $rw->read_lock;
        is $rw->readers,      2, 'a second read_lock deepens the hold instead of parking';
        is $rw->read_holders, 1, 'for the same single fiber';
        is $rw->waiters,      0, 'and parked nobody';
        $rw->read_unlock;
        is $rw->readers, 1, 'each read_unlock gives back exactly one hold';
        $rw->read_unlock;
        is $rw->readers, 0, 'and the lock is free again';
        $rw->write_lock;
        $rw->read_lock;
        is $rw->readers, 1, 'a fiber that already writes takes a read hold in place (no self-deadlock)';
        $rw->read_unlock;
        $rw->write_unlock;
        ok !defined $rw->writer, 'both holds released';
        $rw->read_lock;
        like dies { $rw->write_lock }, qr/upgrading/, 'upgrading read to write croaks instead of deadlocking';
        $rw->read_unlock;
        is $rw->readers, 0, 'the refused upgrade left the read hold intact';
        $rw->write_lock;
        like dies { $rw->write_lock },     qr/not reentrant/, 'a second write_lock croaks';
        like dies { $rw->try_write_lock }, qr/not reentrant/, 'so does a second try_write_lock';
        $rw->write_unlock;
    };
};
subtest 'an interrupted write_lock unregisters and the lock stays usable' => sub {
    my $rw  = Acme::Parataxis::Sync::RwLock->new;
    my $log = '';
    my $err;
    async {
        my $holder = fiber { $rw->write_lock; await_sleep(2000); $log .= 'H'; $rw->write_unlock };
        $err = dies {
            with_timeout( 10, sub { $rw->write_lock; $log .= 'SHOULD-NOT' } );
        };
        is $rw->write_waiters, 0, 'the timed-out writer removed itself from the queue';
        my $next = fiber { $rw->write_lock; $log .= 'N'; $rw->write_unlock };
        $holder->await;
        $next->await;
        is $rw->waiters, 0, 'the lock drained';
        is $rw->readers, 0, 'no read hold was stranded';
        ok !defined $rw->writer, 'and no writer was left recorded';
    };
    ok ref($err) && $err->isa('Acme::Parataxis::Error::Timeout'), 'the block timed out instead of deadlocking';
    is $log, 'HN', 'the cancelled writer never got the lock; the next one did';
};
subtest 'an interrupted read_lock unregisters and the lock stays usable' => sub {
    my $rw  = Acme::Parataxis::Sync::RwLock->new;
    my $log = '';
    my $err;
    async {
        my $w = fiber { $rw->write_lock; await_sleep(2000); $rw->write_unlock; $log .= 'W' };
        $err = dies {
            with_timeout( 10, sub { $rw->read_lock; $log .= 'SHOULD-NOT' } );
        };
        is $rw->read_waiters, 0, 'the timed-out reader removed itself from the queue';
        my $r = fiber { $rw->read_lock; $log .= 'R'; $rw->read_unlock };
        $w->await;
        $r->await;
        is $rw->waiters, 0, 'the lock drained';
        is $rw->readers, 0, 'and released every hold';
    };
    ok ref($err) && $err->isa('Acme::Parataxis::Error::Timeout'), 'the block timed out instead of deadlocking';
    is $log, 'WR', 'the cancelled reader never got in; the next one did';
};
subtest 'every operation croaks outside a scheduled fiber' => sub {
    my $rw = Acme::Parataxis::Sync::RwLock->new;
    like dies { $rw->read_lock },      qr/scheduled fiber/, 'read_lock croaks';
    like dies { $rw->try_read_lock },  qr/scheduled fiber/, 'try_read_lock croaks';
    like dies { $rw->read_unlock },    qr/scheduled fiber/, 'read_unlock croaks';
    like dies { $rw->write_lock },     qr/scheduled fiber/, 'write_lock croaks';
    like dies { $rw->try_write_lock }, qr/scheduled fiber/, 'try_write_lock croaks';
    like dies { $rw->write_unlock },   qr/scheduled fiber/, 'write_unlock croaks';
    like dies { $rw->read_guard },     qr/scheduled fiber/, 'read_guard croaks';
    like dies { $rw->write_guard },    qr/scheduled fiber/, 'write_guard croaks';

    # Introspection is harmless off-fiber, like Sync::Mutex's accessors.
    is $rw->waiters,       0, 'waiters() reports outside a fiber';
    is $rw->read_waiters,  0, 'read_waiters() reports outside a fiber';
    is $rw->write_waiters, 0, 'write_waiters() reports outside a fiber';
    is $rw->readers,       0, 'readers() reports outside a fiber';
    is $rw->read_holders,  0, 'read_holders() reports outside a fiber';
    ok !defined $rw->writer, 'writer() reports outside a fiber';
    ok !defined $rw->owner,  'owner() is an alias for writer()';
};
#
done_testing;
