use v5.40;
use blib;
$|++;
use Config;
use Acme::Parataxis           qw[run fiber await_sleep with_timeout];
use Acme::Parataxis::Blocking qw[spawn_blocking set_max_blocking_threads max_blocking_threads];
use if $Config{useithreads} eq 'define', 'threads';            # 'use threads' must precede
use if $Config{useithreads} eq 'define', 'threads::shared';    # threads::shared, so both are conditional
use Time::HiRes qw[time];

# Offloading CPU-bound work while the scheduler keeps running. A fiber is a
# coroutine on one OS thread, so a pure-Perl tight loop in a fiber starves its
# siblings until it yields -- and loop yield points are rare in real number
# crunching. spawn_blocking() moves such a closure onto a dedicated background
# Perl interpreter (a real ithread cloned with threads->create) whose only job
# is that closure: the fiber waiting on the result parks cleanly and every
# other fiber keeps scheduling on the main thread meanwhile.
#
#   pool (set_max_blocking_threads)  cap on concurrent background interpreters;
#     excess spawn_blocking calls park the calling fiber until a slot frees,
#     so the bound is a true concurrency limit like the C pool's.
#   copy-in / copy-out  the closure sees a snapshot: threads->create args and
#     captured lexicals at spawn; the return value crosses back through
#     threads::shared, and a die() in the closure becomes a Future error.
#   wall-clock only  real OS work cannot ride the mock clock, so spawn_blocking
#     croaks under run(virtual => 1).
#
# Requires a perl built with useithreads; without one this demo explains
# itself and exits 0 rather than dying.
#
# Usage:  perl eg/blocking_offload.pl [--pool N] [--jobs N] [--burn MS]
#   runs $JOBS CPU closures (of ~$BURN ms each) through a $POOL-interpreter
#   pool, counts how many scheduler ticks a plain fiber completes while they
#   churn, checks every result and the concurrency cap, then exits 0.
#
# Wall-clock note: perl_clone is expensive on Windows (the pod's platform
# warning), so a whole run takes tens of wall seconds no matter how small
# --burn is; the scheduler still ticks the whole time. --pool 1 --jobs 2 is
# the fastest run there is.
if ( !( defined $Config{useithreads} && $Config{useithreads} eq 'define' ) ) {
    print "This perl is not built with useithreads, so spawn_blocking() cannot clone\n",
        "an interpreter. Acme::Parataxis::Blocking is a no-op here; rebuild perl\n", "with -Dusethreads to run the offload demo.\n";
    exit 0;
}
my $POOL = 2;      # background interpreters; --pool to raise
my $JOBS = 6;      # closures to run through the pool; --jobs to change
my $BURN = 100;    # ms of CPU per closure; --burn to vary
{
    my @a = @ARGV;
    while (@a) {
        my $arg = shift @a;
        if    ( $arg eq '--pool' ) { $POOL = int shift @a }
        elsif ( $arg eq '--jobs' ) { $JOBS = int shift @a }
        elsif ( $arg eq '--burn' ) { $BURN = int shift @a }
        else                       { die "unknown option '$arg'\n" }
    }
}
die "--pool must be >= 1\n" if $POOL < 1;
die "--jobs must be >= 1\n" if $JOBS < 1;

# Any pure-Perl number crunch the scheduler should not have to babysit. The
# wall-clock loop is used (not sleep) so the work is visible to the scheduler
# AND to with_timeout, exactly as a real heavy routine would be. The sum folds
# the tag in, so every result is individually checkable after it crosses back.
sub churn ( $tag, $ms ) {
    my $end = time() + $ms / 1000;
    my $sum = 0;
    1 while time() < $end && ( $sum = ( $sum * 31 + $tag ) % 2147483647 );
    return { tag => $tag, sum => $sum };
}
my $cap = set_max_blocking_threads($POOL);
die "set_max_blocking_threads($POOL) reported $cap" unless $cap == $POOL;

# Shared across the workers (each a cloned interpreter of its own) so the peak
# is evidence the pool bound held. threads::shared is idle until used, exactly
# like threads itself.
my $cur  = 0;
my $peak = 0;
share($cur)  or die 'share $cur';
share($peak) or die 'share $peak';
my $ticks = 0;
my $rv    = run(
    sub {
        # $JOBS closures out, only $POOL interpreters at home: the pool is a
        # Semaphore, so the callers that oversubscribe it park at spawn and
        # the bound is a real concurrency cap, not an admission plea.
        my @fs = map {
            my $i = $_;
            spawn_blocking(
                sub {
                    { lock $cur; lock $peak; $cur++; $peak = $cur if $cur > $peak }
                    my $r = churn( $i, $BURN );
                    { lock $cur; $cur-- }
                    return $r;
                },
                $i,
            );
        } 1 .. $JOBS;

        # The whole point: while $JOBS CPU closures churn on dedicated
        # interpreters, a plain cooperative fiber still ticks on time. The
        # ticker is bounded only so run() can wind down - it is not what
        # finishes the work.
        fiber {
            while ( $ticks < 1000 ) {
                await_sleep(25);
                $ticks++;
            }
            1;
        };
        my @out   = map { $_->await } @fs;                        # results come back in spawn order
        my $slow  = spawn_blocking( sub { churn( 99, 300 ) } );
        my $timed = !eval {
            with_timeout( 50, sub { return $slow->await } );
            1;
        };
        my $again = spawn_blocking( sub { churn( 7, 20 ) } )->await;
        return {
            out   => \@out,
            timed => $timed,
            again => $again,
            ticks => $ticks,
            peak  => do { lock $peak; $peak },
        };
    }
);
my $fail = 0;
sub problem ($msg) { print "verify FAIL: $msg\n"; ++$fail }
my @out = @{ $rv->{out} };
problem "expected $JOBS results, got " . scalar @out unless @out == $JOBS;
problem "cap raised to $POOL but the run reported peak " . ( $rv->{peak} // 'undef' )        if ( $rv->{peak}  // 0 ) > $POOL;
problem "a cooperative fiber completed only $rv->{ticks} ticks while $JOBS closures churned" if ( $rv->{ticks} // 0 ) == 0;
problem "closure results did not come back in spawn order" unless join( ',', map { $_->{tag} } @out ) eq join( ',', 1 .. $JOBS );
problem "a closure result was not carried across intact" if grep { !$_->{sum} || ref($_) ne 'HASH' } @out;
problem "with_timeout(50) did not time out a 300 ms closure"           unless $rv->{timed};
problem "a fresh spawn_blocking after the timeout gave a wrong answer" unless $rv->{again}{tag} == 7;
problem "set_max_blocking_threads reported a different cap" if max_blocking_threads() != $POOL;
print sprintf "%d closures (%d ms each) through %d background interpreters in %.2fs; peak == %d, cap == %d\n", $JOBS, $BURN, $POOL, time() - $^T,
    $rv->{peak} // 0, max_blocking_threads();
print sprintf "while they churned, a plain fiber ticked %d times at 25 ms -- the scheduler never stopped.\n", $rv->{ticks};
print sprintf "with_timeout(50) vs a 300 ms closure: %s. composition works.\n", $rv->{timed} ? 'timed out' : 'finished (unexpected!)';
$fail ? ( print "demo FAILED ($fail issues)\n" and exit 1 ) : ( print "all checks passed\n" and exit 0 );
