use strict;
use warnings;

# Ticket #161. Foundation::Runner::_run_command armed the max_runtime
# deadline only inside the IO::Select read loop. A child that closed its
# stdout/stderr while still running -- the canonical
# `exec >/dev/null 2>&1; sleep N` an operator writes to keep their own
# agent log -- gave the parent EOF, the parent left the loop with
# $timed_out == 0 and entered a bare `waitpid($pid, 0)`. No deadline, no
# WNOHANG. .karr.lock stayed held, every later board in the same run
# waited behind it, and an unattended run could stall indefinitely.
#
# The fix is a deadline that is independent of the read loop: SIGALRM
# sets a flag, and the post-EOF reap polls with WNOHANG against the wall
# clock and escalates to the SIGTERM/SIGKILL pair once max_runtime has
# elapsed. The post-EOF reap is what closes the gap the bug describes.
#
# Two subtests below pin the gap:
#   1. _run_command with max_runtime=1 and the EOF-before-deadline command
#      must come back inside max_runtime, not at the agent's natural end.
#   2. the post-EOF reap's exit code must be the SIGTERM one (128+15=143),
#      so a stalled agent still surfaces as a failure rather than a
#      successful run.

use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

use App::karr::Foundation;

subtest 'deadline is enforced after EOF -- the run returns inside max_runtime' => sub {
    # Exact command from the ticket body: it closes stdout and stderr so
    # the parent's read loop hits EOF, then keeps sleeping past max_runtime.
    # Old code returned at t+20 with exit=0; new code returns at t+~3 with
    # exit=143 (128+SIGTERM, the timeout-path exit code).
    my $repo = path( tempdir( CLEANUP => 1 ) );
    my $f    = App::karr::Foundation->new( _config_data => {} );

    my $start = time;
    my ( $code, $out ) = $f->_run_command(
        $repo, { max_runtime => 1 }, 'exec >/dev/null 2>&1; sleep 20',
    );
    my $elapsed = time - $start;

    ok $elapsed < 10,
        "the run returns inside max_runtime (took ${elapsed}s; would be 20 with the bug)"
        or diag "the runner waited for the agent's sleep -- deadline was not enforced after EOF";
    isnt $code, 0, "an agent that exceeded max_runtime is not booked as exit 0"
        or diag "exit code is 0 -- the deadline path never ran, this is the ticket #164 shape";
    is $code, 143, 'the run is reported as 128+SIGTERM, the timeout-path convention';
};

subtest 'EOF before any output is also reaped at the deadline' => sub {
    # Degenerate form of the bug: an agent that execs and writes nothing
    # at all. The read loop gets EOF on the first can_read, the loop ends,
    # and the reap path has to enforce the deadline. Without the fix the
    # bare waitpid holds .karr.lock for the agent's full sleep.
    my $repo = path( tempdir( CLEANUP => 1 ) );
    my $f    = App::karr::Foundation->new( _config_data => {} );

    my $start = time;
    my ( $code, $out ) = $f->_run_command(
        $repo, { max_runtime => 1 }, 'exec /bin/sleep 20',
    );
    my $elapsed = time - $start;

    ok $elapsed < 10, "exec-and-sleep agent is reaped at the deadline (took ${elapsed}s)"
        or diag "the runner waited for the agent -- EOF before any output lost the deadline";

    is $code, 143, 'still reported as 128+SIGTERM';
    ok !length $out, 'no output was ever produced -- EOF on the read pipe was immediate';
};

# A control: an EOF agent that finishes on its own well inside max_runtime
# is reported as a clean exit, NOT a timeout. The fix must not over-trigger
# on the post-EOF path -- it has to be a deadline, not "anything that EOFs
# is suspicious".
subtest 'EOF agent that exits naturally is reported as a clean run' => sub {
    my $repo = path( tempdir( CLEANUP => 1 ) );
    my $f    = App::karr::Foundation->new( _config_data => {} );

    my ( $code, $out ) = $f->_run_command(
        $repo, { max_runtime => 30 }, 'exec >/dev/null 2>&1; exit 0',
    );

    is $code, 0, 'clean exit is reported as 0, not 128+SIGTERM'
        or diag "the EOF-then-exit path is being booked as a timeout ($code)";
};

done_testing;