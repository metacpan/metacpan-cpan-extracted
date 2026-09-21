use v5.40;
no warnings 'recursion';    # fibers run on separate heap stacks; Perl's C-stack-depth heuristic misfires there
use blib;
use Time::HiRes     qw[time];
use Acme::Parataxis qw[async fiber yield stop await_read current_fid];
use Acme::Parataxis::Semaphore;
use Acme::Parataxis::Signal;
use Acme::Parataxis::Channel;
use Acme::Parataxis::Future;
use Test2::V1 -ipP;
$|++;

BEGIN {
    $SIG{__WARN__} = sub { return if $_[0] =~ /^Deep recursion on subroutine/; warn @_ }
}
use constant MAX_FIBERS => 1024;
use constant MAX_JOBS   => 1024;
sub live_count  { Acme::Parataxis::get_live_fiber_count() }
sub outstanding { Acme::Parataxis::get_outstanding_jobs() }

# Fill the 1024-slot job queue with fire-and-forget sleeps from a single tight loop. While that fiber runs, the
# scheduler cannot poll, so none of the 1024 jobs can have completed and the very next submission MUST report the pool
# full deterministically. Then the fiber parks until the jobs drain and submits again successfully.
async {
    my $fills = 0;
    my $rc;
    for ( 1 .. MAX_JOBS ) {
        $rc = Acme::Parataxis::submit_c_job( 0, 300, 0 );
        last if $rc < 0;
        $fills++;
    }
    is $fills, MAX_JOBS, 'job pool: filled all 1024 slots' or diag "filled only $fills (submission returned $rc)";
    my $full = Acme::Parataxis::submit_c_job( 0, 300, 0 );
    ok $full < 0, "job pool: next submission refused when full (got $full)";
    Acme::Parataxis->yield while outstanding() > 0;
    is Acme::Parataxis::submit_c_job( 0, 1, 0 ), 0, 'job pool: submission succeeds after the pool drained';
};
ok outstanding() == 0, 'job pool: nothing left outstanding after the pool drain';

# Park 1023 fibers on a signal (no sleep jobs, no timers) to fill the 1024-slot fiber table alongside the running main
# fiber; the next spawn must croak.
async {
    my $sig     = Acme::Parataxis::Signal->new;
    my $waiters = 0;
    my $full_err;
    for ( 1 .. MAX_FIBERS + 2 ) {
        my $ok = eval {
            fiber { $sig->wait };
            1;
        };
        if ( !$ok ) { $full_err = $@; last }
        $waiters++;
    }
    ok defined $full_err && $full_err =~ /fiber table is full/, 'fiber table: spawning past capacity croaks with "fiber table is full"' or
        diag 'no croak; parked ' . $waiters . ' waiters' . ( $full_err ? "; err=$full_err" : '' );
    is $waiters,     MAX_FIBERS, 'fiber table: exactly MAX_FIBERS parked fibers accepted';
    is live_count(), $waiters,   'fiber table: every accepted fiber is still parked at the cap';
    $sig->broadcast;
    Acme::Parataxis->yield while live_count() > 1;
    ok live_count() <= 1, 'fiber table: all waiters released and drained';
    my $again = fiber { return 1 };
    ok defined $again, 'fiber table: table accepts new fibers after the release';
};
ok live_count() == 0 && outstanding() == 0, 'fiber table: table and job pool clean at end of run';

# Concurrent producers/consumers on a capacity-1 channel force a strict put/get rendezvous; every token must be
# delivered exactly once, in order.
async {
    my $chan = Acme::Parataxis::Channel->new( capacity => 1 );
    my ( $seq, $consumed ) = ( 0, 0 );
    my $pairs = 64;
    my @f;
    for ( 1 .. $pairs ) {
        push @f, fiber { $chan->put( ++$seq ) }
    }
    for ( 1 .. $pairs ) {
        push @f, fiber {
            my $v = $chan->get;
            ok $v == ++$consumed, "channel cascade: delivered token $v in order" or note "got $v, expected $consumed";
        };
    }
    undef @f;    # drop our references; the C context keeps the parked fibers alive
    yield for 1 .. 3;
};
ok live_count() == 0, 'channel cascade: all producers/consumers drained';

# Semaphore wake burst
async {
    my $sem    = Acme::Parataxis::Semaphore->new( count => 2 );
    my $guards = 0;
    my $g      = 200;
    my @f;
    for ( 1 .. $g ) {
        push @f, fiber { $sem->guard; $guards++ }
    }
    undef @f;
    yield    for 1 .. 2;             # let the parked guards settle on the semaphore
    $sem->up for 1 .. ( $g - 2 );    # exactly enough permits for the blocked guard fibers
    yield    for 1 .. 5;
    is $guards, $g, 'semaphore burst: every guard acquired a permit';

    # Each of the 198 dial-ups hands a permit to one parked guard. That guard's RAII guard destructor returns the
    # permit on release, so every dial-up nets +1 on top of the 2 initial permits the first two guards consumed and
    # already restored: 2 + 198 = 200. The count drifting up is correct holder-ownership behaviour.
    is $sem->count, 200, 'semaphore burst: count reflects permits returned by released guards';
};
ok live_count() == 0, 'semaphore burst: all guards drained';

# Future multi-await + reuse
async {
    my $fut = Acme::Parataxis::Future->new;
    my ( $ok, $err ) = ( 0, 0 );
    for my $cycle ( 1, 2 ) {
        my $seen = 0;
        my @f;
        for ( 1 .. 25 ) {
            push @f, fiber { my $v = $fut->await; $seen++ if $v eq 'cycle-' . $cycle };
        }
        undef @f;
        $fut->set_result( 'cycle-' . $cycle );
        yield for 1 .. 3;
        is $seen, 25, 'future multi-await: all 25 awaiters served on cycle ' . $cycle;
        $fut->clear_result;
    }
    my @f;
    for ( 1 .. 10 ) {
        push @f, fiber {
            eval { $fut->await; $ok++ }
        }
    }
    undef @f;
    $fut->set_error('boom');
    yield for 1 .. 3;
    is $ok, 0, 'future multi-await: no awaiter succeeded on the failed cycle';
};
ok live_count() == 0, 'future multi-await: all awaiters drained';

# await_read timeout
async {
    pipe( my $r, my $w );
    my $t0 = time;
    my $rc = await_read( $r, 100 );
    my $el = time - $t0;
    ok defined $rc, 'await_read timeout: returns (does not stall the scheduler)';
    ok $el < 5.0, 'await_read timeout: returned promptly' or note "took ${el}s";
    $^O eq 'MSWin32' or cmp_ok $el, '>=', 0.090, 'await_read timeout: honoured the full timeout on POSIX' or note "elapsed ${el}s";
};
#
done_testing;
