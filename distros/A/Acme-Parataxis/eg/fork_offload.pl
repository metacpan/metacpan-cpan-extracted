use v5.40;
use blib;
$|++;
use Config;
use Acme::Parataxis           qw[run fiber await_sleep with_timeout];
use Acme::Parataxis::Blocking qw[spawn_blocking_fork set_max_blocking_forks max_blocking_forks kill_blocking_fork];
use POSIX                     ();
use Time::HiRes               qw[time];

# CPU offload for a perl that has no threads. spawn_blocking() needs a
# useithreads build because it clones an interpreter with threads->create; this
# demo uses spawn_blocking_fork(), which forks a child process instead and so
# needs nothing but fork(2). That is the whole reason it is a separate entry
# point rather than a fallback inside spawn_blocking: the two have different
# honest limits, and a caller should be able to see which one it asked for.
#
#   no threads at all  threads, threads::shared and Thread::Queue are never
#     loaded, so this runs on a perl built without ithreads and leaves the
#     property that loading Acme::Parataxis acquires no threads association
#     intact.
#   copy-in / copy-out  the child is a copy of your address space at the fork,
#     so the closure sees its args and whatever its captured lexicals held
#     then; the only thing that comes back is the frozen result. A die() in the
#     closure, or a result Storable cannot store, becomes a Future error.
#   process pool (set_max_blocking_forks)  cap on concurrent children; excess
#     spawn_blocking_fork calls park the calling fiber until a slot frees.
#   killable  this is the one thing the thread pool cannot do. A thread cannot
#     be yanked; a child is a process, so kill_blocking_fork() really stops the
#     work and the Future resolves with an error.
#   wall-clock only  real OS work cannot ride the mock clock, so this croaks
#     under run(virtual => 1).
#
# Requires a real fork(2): MSWin32 emulates fork with threads.pm, which is the
# very machinery this path exists to avoid. Without one this demo explains
# itself and exits 0 rather than dying.
#
# Usage:  perl eg/fork_offload.pl [--pool N] [--jobs N] [--burn MS]
#   runs $JOBS CPU closures (of ~$BURN ms each) through a $POOL-child process
#   pool, counts how many scheduler ticks a plain fiber completes while they
#   churn, checks every result, checks the concurrency cap, then demonstrates
#   kill_blocking_fork() on a runaway child and exits 0.
if ( !( defined $Config{d_fork} && $Config{d_fork} eq 'define' ) || $^O eq 'MSWin32' ) {
    print "This platform has no real fork(2) (MSWin32 emulates it with threads.pm),\n",
        "so spawn_blocking_fork() is unavailable here. Use perl eg/blocking_offload.pl\n", "on a useithreads build instead.\n";
    exit 0;
}
my $POOL = 2;      # concurrent children; --pool to raise
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
# $start/$end come back too: a child cannot increment a counter in its parent
# (that would be writing to memory it does not own), so concurrency is measured
# from the windows the children actually ran in, and the cap is checked against
# those rather than against a shared tally that would always read zero.
sub churn ( $tag, $ms ) {
    my $start = time();                # not $^T: that is the parent's, and every child inherits it
    my $end   = $start + $ms / 1000;
    my $sum   = 0;
    1 while time() < $end && ( $sum = ( $sum * 31 + $tag ) % 2147483647 );
    return { tag => $tag, sum => $sum, pid => $$, start => $start, end => time() };
}
my $cap = set_max_blocking_forks($POOL);
die "set_max_blocking_forks($POOL) reported $cap" unless $cap == $POOL;
my $ticks = 0;
my $done  = 0;
my $rv    = run(
    sub {
        # $JOBS closures out, only $POOL children at home: the pool is a
        # Semaphore, so the callers that oversubscribe it park at spawn and the
        # bound is a real concurrency cap, not an admission plea.
        my @fs = map {
            my $i = $_;
            spawn_blocking_fork( sub { churn( $i, $BURN ) }, $i );
        } 1 .. $JOBS;

        # The whole point: while $JOBS CPU closures churn on child processes, a
        # plain cooperative fiber still ticks on time. The ticker stops when the
        # work is done -- it is not what finishes the work, and it is bounded
        # only so run() can wind down.
        fiber {
            while ( !$done && $ticks < 400 ) {
                await_sleep(25);
                $ticks++;
            }
            1;
        };
        my @out   = map { $_->await } @fs;                              # results come back in spawn order
        my $slow  = spawn_blocking_fork( sub { churn( 99, 1500 ) } );
        my $timed = !eval {
            with_timeout( 50, sub { return $slow->await } );
            1;
        };
        my $again = spawn_blocking_fork( sub { churn( 7, 20 ) }, 7 )->await;

        # The difference from the thread pool: a runaway child can be signalled
        # for real, so the work actually stops.
        my $runaway = spawn_blocking_fork( sub { my $n = 0; $n++ while 1 } );
        await_sleep(200);    # let it get properly stuck
        my $delivered = kill_blocking_fork($runaway);
        my $killed_at = time();
        my $killed    = eval { $runaway->await; 1 } ? 0 : 1;
        my $kill_took = time() - $killed_at;
        my $err       = $@;

        # ...and a slot the killed child was holding came back, so the pool is
        # not left one permit short forever.
        my $after_kill = spawn_blocking_fork( sub { churn( 8, 20 ) }, 8 )->await;
        $done = 1;
        return {
            out        => \@out,
            timed      => $timed,
            again      => $again,
            ticks      => $ticks,
            delivered  => $delivered,
            killed     => $killed,
            kill_took  => $kill_took,
            kill_err   => $err,
            after_kill => $after_kill,
        };
    }
);

# The concurrency cap, reconstructed from the windows each child reported. Walk
# the start/stop endpoints and take the deepest overlap; with $POOL children
# allowed it must never exceed $POOL, and it must exceed zero or the closures
# did not really overlap at all.
my $high = 0;
{
    my @events = map { ( [ $_->{start}, +1 ], [ $_->{end}, -1 ] ) } @{ $rv->{out} };
    my $depth  = 0;
    for my $e ( sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @events ) {
        $depth += $e->[1];
        $high = $depth if $depth > $high;
    }
}
my $fail = 0;
sub problem ($msg) { print "verify FAIL: $msg\n"; ++$fail }
my @out = @{ $rv->{out} };
problem "expected $JOBS results, got " . scalar @out unless @out == $JOBS;
problem "closures did not overlap at all (peak depth $high)"                                 if $high == 0;
problem "cap raised to $POOL but $high children ran at once"                                 if $high > $POOL;
problem "a cooperative fiber completed only $rv->{ticks} ticks while $JOBS closures churned" if !$rv->{ticks};
problem "closure results did not come back in spawn order" unless join( ',', map { $_->{tag} } @out ) eq join( ',', 1 .. $JOBS );
problem "a closure result was not carried across intact"     if grep { !$_->{sum} || ref($_) ne 'HASH' } @out;
problem "the closures did not each run in their own process" if scalar( keys %{ { map { $_->{pid} => 1 } @out } } ) != $JOBS;
problem "with_timeout(50) did not time out a 1500 ms closure"               unless $rv->{timed};
problem "a fresh spawn_blocking_fork after the timeout gave a wrong answer" unless $rv->{again}{tag} == 7;
problem "kill_blocking_fork() did not signal the runaway child"             unless $rv->{delivered};
problem "the signalled child's Future did not resolve with an error"        unless $rv->{killed};
problem "the signalled child reported: $rv->{kill_err}"                     unless $rv->{kill_err} =~ /signal|never delivered/;
problem "the Future took " . sprintf( '%.1f', $rv->{kill_took} ) . "s to resolve after the signal" if $rv->{kill_took} > 10;
problem "the pool lost a permit to the killed child" unless $rv->{after_kill}{tag} == 8;
problem "set_max_blocking_forks reported a different cap"         if max_blocking_forks() != $POOL;
problem "threads.pm was loaded, but this path must never load it" if exists $INC{'threads.pm'};
print sprintf "%d closures (%d ms each) through %d forked children in %.2fs; peak == %d, cap == %d\n", $JOBS, $BURN, $POOL, time() - $^T, $high,
    max_blocking_forks();
print sprintf "while they churned, a plain fiber ticked %d times at 25 ms -- the scheduler never stopped.\n", $rv->{ticks};
print sprintf "with_timeout(50) vs a 1500 ms closure: %s. composition works, and the abandoned child\n",
    $rv->{timed} ? 'timed out' : 'finished (unexpected!)';
print "kept its pool slot until it really finished, exactly as a thread pool's would.\n";
print sprintf "kill_blocking_fork() stopped a runaway child in %.1f ms; the pool slot came back.\n", $rv->{kill_took} * 1000;
print "no threads.pm in %INC: exactly what a non-ithreads perl needs.\n";
$fail ? ( print "demo FAILED ($fail issues)\n" and exit 1 ) : ( print "all checks passed\n" and exit 0 );
