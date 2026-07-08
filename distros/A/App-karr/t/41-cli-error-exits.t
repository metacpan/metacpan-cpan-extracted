use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

# Regression tests for karr board tickets #5 and #6.
#
# #5: `karr <unknown-subcommand>` silently falls through to the same default
#     action as bare `karr` (App::karr::execute, App/karr.pm ~237-253, which
#     unconditionally instantiates and renders App::karr::Cmd::Board)
#     instead of erroring. MooX::Cmd hands the unrecognised token to
#     execute() via $args_ref without ever dispatching to a Cmd:: subclass.
#     A fix must not break bare `karr` / bare `karr --done`, which
#     legitimately rely on that same fallthrough to render the board (see
#     t/40-board-done-cli.t) -- both are re-pinned below as GREEN.
#
# #6: ID-taking commands are inconsistent about not-found exit codes.
#     App::karr::Cmd::Show/Move/Edit/Delete/Handoff all already
#     `die "Task $id not found\n"` on a missing id -- these five are pinned
#     here as GREEN regressions. (Historically that uncaught die leaked exit
#     255; since ADR 0002 / ticket #22 the central bin/karr handler classifies
#     it as a runtime failure and exits 1. The assertions below only pin a
#     non-zero exit, so they hold across that change; the exact code is pinned
#     in t/57-exit-code-contract.t.)
#     App::karr::Cmd::Archive is the odd one out: on a missing id it does
#     `warn "Task $id not found\n"` + records an error result + `next`s the
#     loop instead of dying, so the command completes normally and exits 0.
#     That is RED here until fixed.
#
# Reference (../kanban-md, Go implementation):
#   - cmd/root.go Execute(): any error returned from cobra's dispatch --
#     including cobra's own built-in "unknown command" error for an
#     unregistered subcommand -- is printed to STDERR and the process exits
#     non-zero (1, or a wrapped clierr code). rootCmd sets SilenceUsage, so
#     an unknown command does NOT dump help/board text to STDOUT.
#   - cmd/show.go runShow(): task.FindByID failure is returned as a plain Go
#     `error`, which root.go's Execute() prints to STDERR and turns into a
#     non-zero exit -- and every id-taking command (show/move/edit/delete/
#     handoff/archive) funnels errors through that same Execute(), so they
#     are all non-zero on not-found by construction.
#   - cmd/archive.go runArchive(): for a *single* id it returns the
#     FindByID error directly (non-zero exit, nothing archived). For
#     *multiple* ids it goes through root.go's runBatch(), which runs every
#     id even after an earlier failure, collects a per-id result, prints
#     "Error: task #ID: ..." per failure to STDERR, and still returns a
#     SilentError{Code:1} if *any* id in the batch failed -- i.e. partial
#     success is committed to disk, but the exit code reports overall
#     failure. That's the parity target encoded in the "mixed id" subtest
#     below: karr's existing warn-and-continue loop in Cmd::Archive already
#     matches the "commit what exists, keep going" half of this; it only
#     needs the final exit code fixed to be non-zero when any id in the
#     batch was not found.
#   - archive is explicitly idempotent in both implementations:
#     re-archiving an already-archived id is a successful no-op (exit 0),
#     not treated as a not-found-style error. Already pinned at the Cmd::
#     level in t/38-archive-ref-backed.t; re-pinned here at the CLI/
#     subprocess level since the ticket #6 fix must not regress it while
#     fixing the not-found exit code.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3(
        undef,
        my $stdout_fh,
        $stderr,
        $^X,
        "-I$ROOT/lib",
        $BIN,
        @argv,
    );

    my $stdout = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";

    return {
        exit   => $exit,
        stdout => defined $stdout ? $stdout : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is( $rc, 0, "@cmd" );
}

# Fresh isolated temp repo per call, never the developer's real board.
# task id 1 == 'Sentinel Task' when with_task is set.
sub _setup_repo {
    my (%opts) = @_;
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );

    my $init = _run_karr( $repo, 'init', '--name', 'CLI Board' );
    is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

    if ( $opts{with_task} ) {
        my $rv = _run_karr( $repo, 'create', '--title', 'Sentinel Task', '--status', 'todo' );
        is( $rv->{exit}, 0, 'karr create Sentinel Task succeeds' ) or diag $rv->{stderr};
    }

    return $repo;
}

# ---------------------------------------------------------------- ticket #5

subtest 'unknown subcommand: errors instead of silently rendering the board (RED, ticket #5)' => sub {
    my $repo = _setup_repo( with_task => 1 );
    my $rv = _run_karr( $repo, 'definitely-not-a-command' );

    isnt( $rv->{exit}, 0, 'unknown subcommand exits non-zero' );
    like( $rv->{stderr}, qr/\Qdefinitely-not-a-command\E/,
        'STDERR names the unrecognised token' );
    unlike( $rv->{stdout}, qr/^\d+ tasks\b/m,
        'STDOUT has no board task-count footer' );
    unlike( $rv->{stdout}, qr/Sentinel Task/,
        'STDOUT does not leak board contents (seeded task title)' );
};

subtest 'bare karr and bare karr --done still render the board (GREEN pin, must survive the #5 fix)' => sub {
    my $repo = _setup_repo( with_task => 1 );

    my $bare = _run_karr($repo);
    is( $bare->{exit}, 0, 'bare karr exits 0' ) or diag $bare->{stderr};
    like( $bare->{stdout}, qr/^\d+ tasks\b/m, 'bare karr renders the board footer' );
    like( $bare->{stdout}, qr/Sentinel Task/,  'bare karr renders task content' );

    my $done = _run_karr( $repo, '--done' );
    is( $done->{exit}, 0, 'bare karr --done exits 0' ) or diag $done->{stderr};
    like( $done->{stdout}, qr/^\d+ tasks\b/m, 'bare karr --done renders the board footer' );
};

# ---------------------------------------------------------------- ticket #6

my %ID_CMD = (
    show    => [ 'show',    99 ],
    move    => [ 'move',    99, 'done' ],
    edit    => [ 'edit',    99, '--title', 'New title' ],
    delete  => [ 'delete',  99, '--yes' ],
    handoff => [ 'handoff', 99, '--claim', 'fox-owl' ],
    archive => [ 'archive', 99 ],
);

# show/move/edit/delete/handoff already `die "Task $id not found\n"`
# (a runtime failure -> exit 1 since ADR 0002; was an uncaught 255 before):
# GREEN pins today. archive currently `warn`s and continues instead of dying
# -> exit 0: RED, ticket #6.
my %EXPECT_RED_TODAY = ( archive => 1 );

for my $name ( sort keys %ID_CMD ) {
    my $label = "karr $name 99 (unknown id): non-zero exit + message names the id"
      . ( $EXPECT_RED_TODAY{$name} ? ' (RED, ticket #6)' : ' (GREEN pin)' );

    subtest $label => sub {
        my $repo = _setup_repo( with_task => 1 );
        my $rv = _run_karr( $repo, @{ $ID_CMD{$name} } );

        isnt( $rv->{exit}, 0, "karr $name 99 exits non-zero" );
        like( $rv->{stderr}, qr/\b99\b/, "karr $name 99: message on STDERR names the id" );
    };
}

subtest 'archive: mixed existing + missing id (1,99) -- reference parity (RED exit code, ticket #6)' => sub {
    my $repo = _setup_repo( with_task => 1 ); # task 1 = 'Sentinel Task'

    my $rv = _run_karr( $repo, 'archive', '1,99' );

    # Reference parity chosen from kanban-md cmd/root.go runBatch() +
    # cmd/archive.go: a batch archive processes every id and commits
    # whichever ones exist, but reports overall failure via the exit code
    # if any id in the batch was not found. karr's current Cmd::Archive
    # loop already does the "commit what exists, keep going" half (warn +
    # next, no early die on a missing id) -- that assertion is GREEN
    # already. Only the exit code is wrong today (0 instead of non-zero) --
    # that assertion is RED.
    isnt( $rv->{exit}, 0, 'archive 1,99 exits non-zero overall (RED today)' );
    like( $rv->{stderr}, qr/\b99\b/, 'STDERR names the missing id 99' );

    my $show = _run_karr( $repo, 'show', 1 );
    is( $show->{exit}, 0, 'the existing id (1) is still found afterwards' ) or diag $show->{stderr};
    like( $show->{stdout}, qr/^Status:\s+archived$/m,
        'the existing id (1) was still archived despite id 99 failing (GREEN today)' );
};

subtest 'archive: re-archiving an already-archived task stays exit 0 (GREEN pin, do not regress t/38)' => sub {
    my $repo = _setup_repo( with_task => 1 ); # task 1 = 'Sentinel Task'

    my $first = _run_karr( $repo, 'archive', 1 );
    is( $first->{exit}, 0, 'first archive of task 1 exits 0' ) or diag $first->{stderr};

    my $second = _run_karr( $repo, 'archive', 1 );
    is( $second->{exit}, 0, 'archiving an already-archived task is a no-op success, exit 0' )
      or diag $second->{stderr};
    like( $second->{stdout}, qr/already archived/i,
        'stdout reports the already-archived state' );
};

done_testing;
