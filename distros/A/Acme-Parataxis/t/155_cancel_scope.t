use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield await_sleep with_timeout with_cancel];
use Acme::Parataxis::Semaphore;
use Acme::Parataxis::Channel;
use Acme::Parataxis::CancellationToken;
use Test2::V1 -ipP;
$|++;

# Busy-yield until a semaphore shows exactly $n parked fibers. Dies on timeout instead of returning false so a
# scheduling bug surfaces as a clear failure rather than a cascade of undef derefs.
sub sem_parked_at ( $sem, $n = 1 ) {
    for ( 1 .. 2000 ) { return 1 if $sem->waiters == $n; yield }
    die "semaphore never showed $n waiter(s)";
}
subtest 'an interior park is interrupted by the scope token' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    my ( $tok, $after );
    async {
        my $w = fiber {
            with_cancel(
                sub {
                    my ($t) = @_;
                    $tok = $t;
                    $sem->down;
                    $after = 'reached past the wait';
                }
            );
        };
        sem_parked_at($sem);
        is $sem->waiters, 1, 'the interior wait parked under the scope';
        $tok->cancel;
        my $caught = dies { $w->await };
        ok ref($caught) && $caught->isa('Acme::Parataxis::Error::Cancelled'), 'scope cancel interrupted the interior wait';
        is $caught->kind,             'cancelled',      'kind() is "cancelled"';
        is $caught->wait_reason->[0], 'Semaphore down', 'the error names the parked wait';
        is $sem->waiters,             0,                'the interrupted waiter was deregistered';
        ok !$after, 'the block did not run past the wait';
    };
};
subtest 'a wait entered after the scope is cancelled fails fast, leaving no stale waiter' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    my $ch  = Acme::Parataxis::Channel->new( capacity => 1 );
    my ( $tok, $first, $second, $block_rv );
    async {
        my $w = fiber {
            with_cancel(
                sub {
                    my ($t) = @_;
                    $tok = $t;
                    my $e1 = dies { $sem->down };
                    $first = ref($e1) && $e1->isa('Acme::Parataxis::Error::Cancelled');
                    my $e2 = dies { $ch->get };
                    $second   = ref($e2) && $e2->isa('Acme::Parataxis::Error::Cancelled');
                    $block_rv = 'done';
                    return $block_rv;
                }
            );
        };
        sem_parked_at($sem);
        $tok->cancel;
        $w->await;
        is $block_rv, 'done', 'the block caught both cancellations and finished';
        ok $first,  'the parked first wait was interrupted';
        ok $second, 'a wait entered after the cancel failed fast instead of parking';
        is $sem->waiters, 0, 'no waiter leaked from the re-entry interrupt';
        my $z = fiber { $ch->get };
        $ch->put('fresh');
        is $z->await, 'fresh', 'a later getter still receives data (no stale entry ate the wake)';
    };
};
subtest 'a finished wait stays done; cancelling after normal exit is a no-op' => sub {
    my ( $tok, $v );
    async {
        ( $tok, $v ) = with_cancel( sub { return await_sleep(2) } );
        is $tok->waiters, 0, 'the scope exited with nothing still registered';
        ok !$tok->cancelled, 'the token was not cancelled while the scope ran';
        $tok->cancel;
        ok $tok->cancelled, 'a late cancel only flips the (now inert) token flag';
        is $tok->waiters, 0, 'nothing was left to interrupt';
        ok eval {1}, 'process healthy after the no-op cancel';
    };
    is $v, 2, 'the finished wait kept its value through the exit';
};
subtest 'nested scopes: an inner cancel only kills inner waits' => sub {
    my ( $sem_in, $sem_out ) = ( Acme::Parataxis::Semaphore->new( count => 0 ), Acme::Parataxis::Semaphore->new( count => 0 ) );
    my ( $inner_tok, $outer_tok, $caught_inner, $outer_val );
    async {
        my $w = fiber {
            with_cancel(
                sub {
                    my ($ot) = @_;
                    $outer_tok = $ot;
                    my $inner_err;
                    $inner_err = dies {
                        with_cancel(
                            sub {
                                my ($it) = @_;
                                $inner_tok = $it;
                                $sem_in->down;
                            }
                        );
                    };
                    $caught_inner = ref($inner_err) && $inner_err->isa('Acme::Parataxis::Error::Cancelled');
                    $sem_out->down;
                    $outer_val = 'outer-ok';
                    return $outer_val;
                }
            );
            return $outer_val;
        };
        sem_parked_at($sem_in);
        $inner_tok->cancel;
        sem_parked_at($sem_out);
        ok $caught_inner, 'the inner scope threw Error::Cancelled inside the outer block';
        is $sem_in->waiters,  0, 'the inner wait was released';
        is $sem_out->waiters, 1, 'the outer wait is untouched by the inner cancel';
        ok $inner_tok->cancelled,  'the inner token fired';
        ok !$outer_tok->cancelled, 'the outer token did not fire';
        $sem_out->up;
        is $w->await, 'outer-ok', 'the outer block finished with its own value';
    };
};
subtest 'composition with with_timeout: the deadline beats the scope' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    my $caught;
    async {
        $caught = dies {
            with_cancel(
                sub {
                    with_timeout( 20, sub { $sem->down } );
                }
            );
        };
    };
    ok ref($caught) && $caught->isa('Acme::Parataxis::Error::Timeout'), 'the deadline won over the (unfired) scope';
    is $sem->waiters, 0, 'the timed-out waiter was deregistered';
};
subtest 'composition with with_timeout: the scope beats a still-armed deadline' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    my ( $tok, $caught );
    async {
        $caught = dies {
            with_cancel(
                sub {
                    my ($t) = @_;
                    $tok = $t;
                    my $fire = fiber { await_sleep(10); $tok->cancel };
                    with_timeout( 5000, sub { $sem->down } );
                }
            );
        };
    };
    ok ref($caught) && $caught->isa('Acme::Parataxis::Error::Cancelled'),    'the scope cancel won over the unexpired deadline';
    ok !( ref($caught) && $caught->isa('Acme::Parataxis::Error::Timeout') ), 'not reported as a timeout';
    is $sem->waiters, 0, 'the deadline block left no waiter behind';
};
subtest 'no stale registrations leak from normal or thrown exits' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    my @toks;
    async {
        my $w = fiber {
            my $t = with_cancel( sub { $sem->down; return 'a' } );
            push @toks, $t;
        };
        sem_parked_at($sem);
        $sem->up;
        $w->await;
        is scalar @toks,      1, 'clean exit returned its token';
        is $toks[0]->waiters, 0, 'no registrations after a clean exit';
        my $w2 = fiber {
            with_cancel(
                sub {
                    my ($t) = @_;
                    push @toks, $t;
                    $sem->down;
                    die 'boom';
                }
            );
        };
        sem_parked_at($sem);
        $sem->up;
        my $caught = dies { $w2->await };
        ok $caught, 'the dying block exited through its throw';
        like "$caught", qr/boom/, 'the real error propagated, not a cancel';
        is $toks[1]->waiters, 0, 'no registrations after a thrown exit';
        my ( $t3, $v3 ) = with_cancel( sub { await_sleep(1); 'fresh' } );
        is $v3,          'fresh', 'a fresh scope still works afterwards';
        is $t3->waiters, 0,       'the fresh scope exited clean too';
    };
};
subtest 'with_cancel requires a fiber and a code ref' => sub {
    like dies {
        with_cancel( sub {1} )
    }, qr[must be called from inside a scheduled fiber], 'croaks outside a scheduled fiber';
    async {
        like dies { with_cancel() }, qr[requires a CODE ref], 'croaks without a block';
    };
};
#
done_testing;
