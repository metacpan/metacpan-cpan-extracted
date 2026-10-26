use v5.40;
use experimental 'defer';
use blib;
use Acme::Parataxis qw[async fiber yield await_sleep with_timeout];
use Acme::Parataxis::CancellationToken;
use Acme::Parataxis::Semaphore;
use Acme::Parataxis::Nursery;
use Test2::V1 -ipP;
no warnings 'experimental::defer';    # Test2::V1 re-enables it
$|++;

# defer (run cleanup on every fiber exit), delivered by perl's native 'defer' keyword (v5.36+, experimental).
# A defer written lexically in the fiber body fires on the return path, the throw path, and the cancel path,
# exactly when the fiber's scope exits - before the coroutine is reaped.
#
# Busy-yield until a semaphore shows exactly $n parked fibers. Dies rather than spinning forever so a scheduling
# bug surfaces as a clear failure instead of a hang. Mirrors the pattern in t/062.
sub sem_parked_at ( $sem, $n = 1 ) {
    for ( 1 .. 2000 ) { return 1 if $sem->waiters == $n; yield }
    die "semaphore never showed $n waiter(s)";
}
async {
    subtest 'defer blocks run LIFO on a normal return' => sub {
        my @log;
        fiber {
            defer { push @log, 'd1' };
            defer { push @log, 'd2' };
            await_sleep(1);
            return 'ok';
        }
        ->await;
        is \@log, [ 'd2', 'd1' ], 'the block ran LIFO exactly once';
    };
    subtest 'defer runs when the body dies' => sub {
        my ( @log, $caught );
        my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
        my $w   = fiber {
            defer { push @log, 'ran' };
            $sem->down;    # park during construction
            die "boom\n";
        };
        sem_parked_at($sem);    # let the body park at the semaphore
        $sem->up;               # resume it into its death
        $caught = dies { $w->await };
        is \@log, ['ran'], 'the defer ran on the throw path';
        ok $caught, 'the await did not succeed';
        like "$caught", qr/boom/, 'the body error was delivered to the awaiter';
    };
    subtest 'defer runs when a cancellation token interrupts the parked wait' => sub {
        my ( @log, $caught );
        my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
        my $tok = Acme::Parataxis::CancellationToken->new;
        my $w   = fiber {
            defer { push @log, 'cancelled' };
            $tok->register;
            my $e;
            $e = dies { $sem->down };
            $tok->unregister;
            die $e if $e;
            return 'survived';
        };
        sem_parked_at($sem);
        $tok->cancel;
        $caught = dies { $w->await };
        is \@log, ['cancelled'], 'the defer ran on the cancel path';
        ok $caught,                                                           'the cancelled fiber did not return normally';
        ok ref($caught) && $caught->isa('Acme::Parataxis::Error::Cancelled'), 'await rethrows Error::Cancelled';
    };
    subtest 'defer runs when a deadline cuts the parked wait' => sub {
        my @log;
        fiber {
            defer { push @log, 'd' };
            eval {
                with_timeout( 20, sub { await_sleep(10_000) } );
            };
            1;
        }
        ->await;
        is \@log, ['d'], 'the defer ran when with_timeout fired';
    };
    subtest 'a defers own death folds into the awaiter error' => sub {
        my ( @log, $caught );
        my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
        my $w   = fiber {
            defer { push @log, 'bad'; die "defer-death\n" };
            $sem->down;    # park during construction
            return 'body';
        };
        sem_parked_at($sem);
        $sem->up;          # resume: the body returns, the defer dies at scope exit
        $caught = dies { $w->await };
        is \@log, ['bad'], 'the defer ran and died';
        ok $caught, 'the await did not succeed';
        like "$caught", qr/defer-death/, 'the defer death became the awaiter error';
    };
    subtest 'a body that dies after a defer ran chains the value, a defer that ran twice stays LIFO' => sub {
        my @log;
        my $w = fiber {
            defer { push @log, 'a' };
            defer { push @log, 'a' };
            await_sleep(1);
            return 'ok';
        };
        is $w->await, 'ok',         'the fiber returned normally with both registrations pending';
        is \@log,     [ 'a', 'a' ], 'two defer statements each ran once, LIFO';
    };
    subtest 'run-level fibers and nursery children both run defers' => sub {
        my @log;
        fiber {
            defer { push @log, 'root-child' };
            await_sleep(1);
            return;
        }
        ->await;
        my $n = Acme::Parataxis::Nursery->new;
        my $c = $n->spawn(
            sub {
                defer { push @log, 'nursery' };
                await_sleep(1);
                return 'nc';
            }
        );
        is $c->await, 'nc',                        'the nursery child finished normally';
        is \@log,     [ 'root-child', 'nursery' ], 'defers ran in both the run-level fiber and the nursery child';
    };
    subtest 'defer cleanup does not leak the fiber slot' => sub {
        my @log;
        my $w = fiber {
            defer { push @log, 'cleanup' };
            await_sleep(1);
            return 'ok';
        };
        is $w->await, 'ok',        'the fiber returned normally with a pending defer';
        is $w->fid,   -1,          'the fiber slot was released (the defer kept nothing live)';
        is \@log,     ['cleanup'], 'the defer fired while the slot was released';
    };
};
done_testing;
