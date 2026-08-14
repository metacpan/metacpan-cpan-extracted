use strict;
use warnings;

# Ticket #147. App::karr::Foundation::Runner::_run_command owes a waitpid to
# every child it forks, and two calls that can throw sat between the two:
#
#   1. the parent opened .karr.log *after* the fork, so an unopenable log
#      croaked with the agent already exec'd;
#   2. the TIMEOUT line was appended to that log *before* the SIGTERM/SIGKILL,
#      so a log that went away during a run (the agent's own doing, e.g.)
#      skipped the only thing that stops a hung agent.
#
# Neither is fatal to the process, which is what makes it expensive:
# _run_command is called from _drain_repo, which App::karr::Foundation's
# _process_repo wraps in try/catch ("drain error in $repo") and _release_lock's
# the board anyway. The run continues to the next board, so every affected board
# leaves a live, unwatched agent behind and looks unlocked to the next tick.
#
# The fork override has to be in place before the Runner is compiled, because a
# CORE::GLOBAL replacement only binds ops compiled after it -- so this lives in
# its own file, like t/122-foundation-runner-errors.t (which pins the wording of
# the log error under ticket #77).
our $LAST_CHILD_PID;
BEGIN {
    *CORE::GLOBAL::fork = sub {
        my $pid = CORE::fork();
        $LAST_CHILD_PID = $pid if $pid;    # true only in the parent; child sees 0
        return $pid;
    };
}

use Test::More;
use POSIX qw( WNOHANG );
use Path::Tiny qw( tempdir );

use App::karr::Foundation;
use App::karr::Foundation::Runner;

{
    # Stands in for App::karr::Foundation with an _append_log that never
    # throws. The real one writes the START line to the very file the subtest
    # below breaks and would die there first -- which is why this window was
    # hard to see, not why it was safe: it is the Runner's own open that has to
    # happen before the fork.
    package FakeFoundation;
    sub new                 { bless {}, shift }
    sub _stream_to_terminal { 0 }
    sub _prompt_for         { '' }
    sub _append_log         { }
    sub _say_verbose        { }
    sub dry_run             { 0 }
}

# Reap or kill whatever a regression leaves behind, so a failing run of this
# file does not also litter the machine. Only touches a pid that is still ours:
# once the library has reaped it, the number may belong to somebody else.
sub cleanup_child {
    my ($pid) = @_;
    return unless defined $pid;
    return if waitpid( $pid, WNOHANG ) != 0;
    kill 'KILL', $pid;
    waitpid( $pid, 0 );
}

subtest 'an unopenable log is refused before anything is forked' => sub {
    my $foundation = FakeFoundation->new;    # held: the Runner keeps it weakly
    my $runner = App::karr::Foundation::Runner->new( foundation => $foundation );

    my $repo = tempdir( CLEANUP => 1 );
    # A directory where the log belongs: open '>>' fails with EISDIR whatever
    # the caller's privileges are, so this holds for root too.
    $repo->child('.karr.log')->mkpath;

    local $LAST_CHILD_PID;
    eval { $runner->_run_command( $repo, { command => 'true', max_runtime => 5 } ) };
    my $err = $@;

    like $err, qr/^open log /, 'the run is refused, naming the log';
    is $LAST_CHILD_PID, undef, 'and nothing was forked: no agent was started'
        or diag "a child was forked before the log open failed: $LAST_CHILD_PID";
    is waitpid( -1, WNOHANG ), -1, 'no child of this process is left over'
        or diag 'the refused run left a child behind';

    cleanup_child($LAST_CHILD_PID);
};

subtest 'a log lost mid-run does not cost the agent its SIGTERM and its reap' => sub {
    # The reachable half: the log is writable when the run starts, so the
    # foundation's START line lands and the agent is forked -- and then the
    # agent itself replaces .karr.log with a directory and hangs past
    # max_runtime. The TIMEOUT append then fails, in the window between the tee
    # loop and the waitpid. `exec` in the command matters: without it /bin/sh
    # keeps the sleep as a grandchild that survives the kill, and this test
    # would litter the box.
    my $f    = App::karr::Foundation->new( _config_data => {} );
    my $repo = tempdir( CLEANUP => 1 );
    my $cmd  = 'rm -f .karr.log; mkdir .karr.log; exec sleep 30';

    local $LAST_CHILD_PID;
    my @warnings;
    my $ok = do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        eval { $f->_run_command( $repo, { max_runtime => 1 }, $cmd ); 1 };
    };
    my $err = $@;

    ok !$ok, 'the broken log still fails the run for this board'
        or diag 'the run reported success over an unwritable log';
    like $err, qr/\.karr\.log/, 'and the error names the log';

    ok defined $LAST_CHILD_PID, 'the agent really was forked'
        or diag 'nothing forked -- this subtest is not exercising the window';

    SKIP: {
        skip 'nothing was forked', 3 unless defined $LAST_CHILD_PID;

        is waitpid( $LAST_CHILD_PID, WNOHANG ), -1,
            'the library reaped the agent: it is no longer a child of this process'
            or diag "pid $LAST_CHILD_PID is still ours -- alive, or a zombie";
        is kill( 0, $LAST_CHILD_PID ), 0, 'and it is not running any more'
            or diag "pid $LAST_CHILD_PID survived the run";
        ok scalar( grep { /cannot write .*\.karr\.log/ } @warnings ),
            'the TIMEOUT line it could not write is reported, not swallowed'
            or diag "warnings were:\n@warnings";
    }

    cleanup_child($LAST_CHILD_PID);
    is waitpid( -1, WNOHANG ), -1, 'no child of this process is left over'
        or diag 'the timed-out run left a child behind';
};

done_testing;
