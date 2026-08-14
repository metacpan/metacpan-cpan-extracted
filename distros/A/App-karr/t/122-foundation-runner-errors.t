use strict;
use warnings;

# The fork override has to be in place before App::karr::Foundation::Runner is
# compiled, because a CORE::GLOBAL replacement only binds ops compiled after it.
# That is also why this lives in its own file: fork is unusable for the rest of
# the process afterwards, and the other error-message tests drive bin/karr
# through IPC::Open3.
our $FORK_FAILS;      # a package variable so the subtest below can localize it
our $LAST_CHILD_PID;  # ditto: how the parent below finds the real child to reap
BEGIN {
    *CORE::GLOBAL::fork = sub {
        return undef if $FORK_FAILS;
        my $pid = CORE::fork();
        $LAST_CHILD_PID = $pid if $pid;    # true only in the parent; child sees 0
        return $pid;
    };
}

use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

use App::karr::Foundation::Runner;

# Ticket #77. App::karr::Foundation::Runner reported the three ways starting an
# agent command can fail at the OS level with croak, so each one handed the
# operator a line and a file inside karr:
#
#   pipe failed: Too many open files at /.../lib/App/karr/Foundation/Runner.pm line 67.
#   fork failed: Resource temporarily unavailable at /.../Runner.pm line 70.
#   open log: Permission denied at /.../Runner.pm line 83.
#
# "The kernel refused you a process" is an operator's problem, not a bug report,
# so the errno has to survive and the call site has to go.
#
# The pipe case is the one not exercised here: making pipe(2) fail means
# exhausting the descriptor table, and the soft limit on a normal box is a
# million. It shares its single line of code shape with the two below.

{
    # Stands in for App::karr::Foundation. The Runner holds it weakly, so the
    # caller has to keep it alive -- $foundation below is not a spare variable.
    package FakeFoundation;
    sub new                 { bless {}, shift }
    sub _stream_to_terminal { 0 }
    sub _prompt_for         { '' }
    sub _append_log         { }
    sub _say_verbose        { }
    sub dry_run             { 0 }
}

my $foundation = FakeFoundation->new;
my $runner     = App::karr::Foundation::Runner->new( foundation => $foundation );

subtest 'a refused fork is reported without a karr source location' => sub {
    my $repo = path( tempdir( CLEANUP => 1 ) );

    local $FORK_FAILS = 1;
    eval { $runner->_run_command( $repo, { command => 'true', max_runtime => 5 } ) };
    my $err = $@;

    ok $err, 'the run fails';
    like $err, qr/^fork failed: /, 'and says which call refused';
    unlike $err, qr/ at \S+ line \d+/, 'no "at FILE line N." suffix'
        or diag "error was:\n$err";
    unlike $err, qr/Runner\.pm/, 'no karr module path'
        or diag "error was:\n$err";
    is scalar( grep { length } split /\n/, $err ), 1, 'exactly one line'
        or diag "error was:\n$err";
};

subtest 'a log file that cannot be opened is reported the same way' => sub {
    my $repo = path( tempdir( CLEANUP => 1 ) );
    # A directory where the log belongs: open '>>' fails with EISDIR whatever
    # the caller's privileges are, so this holds for root too. In a real run the
    # foundation's own _append_log reaches the same path first; the Runner still
    # owes a clean message for the case where it does not.
    $repo->child('.karr.log')->mkpath;

    # Unlike the subtest above, this one does not set $FORK_FAILS -- it does not
    # need to. Since ticket #147 the log is opened before the fork, so the
    # failure below happens with no child in existence at all.
    local $LAST_CHILD_PID;
    eval { $runner->_run_command( $repo, { command => 'true', max_runtime => 5 } ) };
    my $err = $@;

    ok $err, 'the run fails';
    like $err, qr/^open log /, 'and says it was the log';
    like $err, qr/\Q@{[ $repo->child('.karr.log') ]}\E/,
        'naming the file, which the croak never did';
    unlike $err, qr/ at \S+ line \d+/, 'no "at FILE line N." suffix'
        or diag "error was:\n$err";
    unlike $err, qr/Runner\.pm/, 'no karr module path'
        or diag "error was:\n$err";

    # Ticket #143 made this subtest reap the child the pre-#147 Runner forked
    # before it died here, because a child that failed before its exec left no
    # trace but Test::Builder's "Forked inside subtest, but subtest never
    # finished!" on the shared STDERR -- never a counted failure, so the file
    # stayed green regardless. Ticket #147 moved the log open in front of the
    # fork, so there is now nothing to reap, and that is what this pins: the
    # error above is raised with no agent started. t/148 covers the leak itself.
    is $LAST_CHILD_PID, undef, 'the failure happened before any fork'
        or diag "a child was forked before the log open failed: $LAST_CHILD_PID";
    if ( defined $LAST_CHILD_PID ) {    # a regression must not litter the box
        kill 'KILL', $LAST_CHILD_PID;
        waitpid( $LAST_CHILD_PID, 0 );
    }
};

done_testing;
