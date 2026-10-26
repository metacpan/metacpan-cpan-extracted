use v5.40;
use Test2::V1 -ipP;
use blib;
use Config;
skip_all 'spawn_blocking requires a threaded perl (useithreads)', 1 if !( defined $Config{useithreads} && $Config{useithreads} eq 'define' );
use Acme::Parataxis           qw[run fiber await_sleep with_timeout];
use Acme::Parataxis::Blocking qw[spawn_blocking set_max_blocking_threads max_blocking_threads];

# Compile-time `use threads;` would abort this file on a non-ithreads perl before the skip_all above could run, so
# defer both to `use if` (no-op when useithreads is undefined). The compile-time import still installs share()'s ref
# prototype on threaded perls, mirroring the guarded idiom in eg/blocking_offload.pl.
use if ( defined $Config{useithreads} && $Config{useithreads} eq 'define' ), 'threads';
use if ( defined $Config{useithreads} && $Config{useithreads} eq 'define' ), 'threads::shared';
use Time::HiRes qw[time];
$|++;

# A fractional core sleep() is a near-no-op inside cloned threads on some Win32 perls, so "heavy" closures burn CPU
# against the high-resolution wall clock instead: real ms of work visible to the scheduler AND to with_timeout.
sub burn ($ms) {
    my $end = time() + $ms / 1000;
    1 while time() < $end;
    1;
}

# Card 20: spawn_blocking(sub { ... }) runs a CPU-bound closure on a dedicated background Perl interpreter (a real
# ithread, cloned with threads->create) and marshals the result back through a shared queue as a normal
# Acme::Parataxis::Future, so the cooperative fibers keep running while the closure churns and the future composes
# with await / with_timeout / cancellation exactly like any other. The concurrency cap (default 4, PARATAXIS_SB_THREADS)
# is set here to 2 before any use; the bound is a Semaphore, so excess callers park their fiber until a slot frees.
my $cap = set_max_blocking_threads(2);
is $cap,                   2,        'set_max_blocking_threads() returns the new cap';
is max_blocking_threads(), 2,        'max_blocking_threads() reports the cap';
is $Config{useithreads},   'define', 'the guard only skipped this file on a threaded perl';
subtest 'spawn_blocking basics: caller keeps running, result via a normal Future' => sub {
    my $fut;
    my $did_run = 0;
    my $rv      = run(
        sub {
            $fut = spawn_blocking( sub { burn 300; 6 * 7 } );
            fiber { await_sleep(150); $did_run = 1 };
            return $fut->await;
        }
    );
    is $rv, 42, 'awaiting the Future yields the closure return value';
    ok $did_run,                             'another fiber ran to completion while the blocking closure was in flight';
    ok $fut->isa('Acme::Parataxis::Future'), 'spawn_blocking returns an Acme::Parataxis::Future';
    ok $fut->is_ready,                       'the future is ready after its await';
    is $fut->result, 42, 'result() rereads the value after completion';
    my $cls = run(
        sub {
            my $f = Acme::Parataxis::Blocking->spawn_blocking( sub {5} );
            return $f->await;
        }
    );
    is $cls, 5, 'the class-method form (Acme::Parataxis::Blocking->spawn_blocking) works';
};
subtest 'spawn_blocking marshalling: args, structured results' => sub {
    my $rv = run(
        sub {
            my $f = spawn_blocking( sub { my ( $a, $b ) = @_; return { sum => $a + $b, list => [ $a, $b ] } }, 20, 22 );
            return $f->await;
        }
    );
    is $rv->{sum},     42, 'explicit spawn_blocking args arrive in the closure';
    is $rv->{list}[0], 20, 'scalar args marshall in order';
    is $rv->{list}[1], 22, 'structured (nested arrayref) results marshall back intact';
    my $u = run(
        sub {
            return spawn_blocking( sub { return undef } )->await;
        }
    );
    is $u, undef, 'an undef result is legal';
};
subtest 'spawn_blocking errors: die, unshareable result, misuse' => sub {
    my ( $f2_ok, $f2_text );
    my $r = run(
        sub {
            my $f = spawn_blocking( sub { die "boom-$_[0]" }, 'x' );
            $f2_ok   = eval { $f->await; 1 };
            $f2_text = $@;
            return 'done';
        }
    );
    ok !$f2_ok, 'a closure die() becomes a Future error';
    like $f2_text, qr/boom-x/, 'the diagnostic text crosses back';
    is $r, 'done', 'run() still completes after a failed future';
    my ( $f3_ok, $f3_text );
    run(
        sub {
            my $f = spawn_blocking(
                sub {
                    sub {1}
                }
            );    # returns a CODE ref: not shareable
            $f3_ok   = eval { $f->await; 1 };
            $f3_text = $@;
        }
    );
    ok !$f3_ok, 'an unshareable result becomes a Future error';
    like $f3_text, qr/cannot|share|clone|CODE/i, 'the marshalling failure is the error message';
    my $e1 = eval {
        my $f = spawn_blocking( sub {1} );
        1;
    };
    like( $e1 ? '' : $@, qr/scheduled fiber/, 'spawn_blocking outside a scheduled fiber croaks' );
    my $e2 = eval { my $f = spawn_blocking('nope'); 1 };
    like( $e2 ? '' : $@, qr/spawn_blocking/, 'spawn_blocking without a CODE ref croaks' );
    my $ev = eval {
        run(
            code => sub {
                spawn_blocking( sub {1} );
            },
            virtual => 1
        );
        1;
    };
    like( $ev ? '' : $@, qr/wall-clock|mock clock/, 'spawn_blocking croaks under the mock clock of run(virtual => 1)' );
    my $e4 = eval { set_max_blocking_threads(9); 1 };
    like( $e4 ? '' : $@, qr/before the first|in use/, 'changing the cap after the pool is in use croaks' );
};
subtest 'spawn_blocking composes with with_timeout and cancellation' => sub {
    my $g;
    my $r = run(
        sub {
            $g = spawn_blocking( sub { burn 300; 'slow-result' } );
            my $ok = eval {
                with_timeout( 100, sub { return $g->await } );
                1;
            };
            return $ok ? 'no-timeout' : 'timed-out';
        }
    );
    is $r, 'timed-out', 'an overdue Future await inside with_timeout times out (cancellation composes)';
    my $health = run(
        sub {
            my $f = spawn_blocking( sub {'still-here'} );
            return $f->await;
        }
    );
    is $health, 'still-here', 'the scheduler and closure pipeline stay healthy after an interrupted await';
};
subtest 'spawn_blocking pool is bounded by set_max_blocking_threads' => sub {
    my $cur = 0;
    threads::shared::share($cur);
    my $peak = 0;
    threads::shared::share($peak);
    my @vals;
    my $done_count = run(
        sub {
            my @fs = map {
                my $i = $_;
                spawn_blocking(
                    sub {
                        { lock $cur; lock $peak; $cur++; $peak = $cur if $cur > $peak }
                        burn 100;
                        { lock $cur; $cur-- }
                        return $i;
                    }
                );
            } 1 .. 6;
            @vals = map { $_->await } @fs;
            return scalar @vals;
        }
    );
    my @peak;
    { lock $peak; @peak = ($peak) }
    ok $peak[0] <= 2, 'concurrent background interpreters never exceeded the configured cap';
    is $done_count,                           6,             'all six closures completed';
    is join( ',', sort { $a <=> $b } @vals ), '1,2,3,4,5,6', 'each closure result arrived intact in order';
};
subtest 'spawn_blocking under an attached event-loop driver' => sub {
    plan skip_all => 'Mojo::IOLoop not installed' unless eval { require Mojo::IOLoop; 1 };
    my $rv;
    my $did_run = 0;
    Acme::Parataxis->attach_loop( Mojo::IOLoop->new );
    $rv = run(
        sub {
            my $f = spawn_blocking( sub { burn 150; 'loop-result' } );
            fiber { await_sleep(40); $did_run = 1 };
            return $f->await;
        }
    );
    Acme::Parataxis->detach_loop;
    is $rv, 'loop-result', 'the result arrived with the harvester riding the loop timers';
    ok $did_run, 'fibers still cooperated under the driver while the closure ran';
};
done_testing();
