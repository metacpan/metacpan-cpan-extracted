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
use Time::Piece;

use App::karr::Git;

# Regression for karr board ticket #150:
#   `karr edit --status X --release` walked straight through require_claim:
#   the require_claim guard in apply_status_change was satisfied by a claim
#   the same command was about to throw away, so a card landed in a
#   require_claim column with no claim on it -- a state karr move and
#   karr edit --status both refuse to create by any other route.
#
#   kanban-md rejects --claim + --release outright (cmd/edit.go:128-130) and
#   runs the require_claim guard in a place --release cannot skip
#   (internal/board/mutate.go:442). karr now does both: --claim + --release is
#   a usage error, and --release clears the claim before the guard runs.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
    my ( $cwd, $stdin, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3( my $stdin_fh, my $stdout_fh, $stderr,
        $^X, "-I$ROOT/lib", $BIN, @argv );

    print {$stdin_fh} $stdin if defined $stdin;
    close $stdin_fh;

    my $stdout      = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";

    return {
        exit   => $exit,
        stdout => defined $stdout      ? $stdout      : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _setup_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0                                     or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0 or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0         or die 'git config';

    my $init = _run_karr( $repo, undef, 'init', '--name', 'Require Claim Board' );
    is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

    my $create = _run_karr( $repo, undef, 'create', '--title', 'Task 1', '--status', 'todo' );
    is( $create->{exit}, 0, 'seed task 1 created' ) or diag $create->{stderr};

    return $repo;
}

sub _task { App::karr::Git->new( dir => $_[0] )->load_task_ref( $_[1] // 1 ) }

subtest '--claim and --release together are rejected as a usage error (#150)' => sub {
    my $repo = _setup_repo();

    # The ticket's reproduction, single-command form: claim + release + status
    # change in one shot, all the way through the door. kanban-md refuses this
    # at the flag layer (cmd/edit.go:128-130); karr does the same.
    my $one_shot = _run_karr( $repo, undef,
        'edit', 1, '--status', 'in-progress', '--claim', 'agent-b', '--release' );
    is( $one_shot->{exit}, 2, 'edit --status --claim --release is a usage error' )
        or diag $one_shot->{stdout} . $one_shot->{stderr};
    like( $one_shot->{stderr}, qr/cannot use --claim and --release together/,
        '...with the rejection message' );

    # --release without --claim is not rejected; the rejection is about the
    # combination, not either flag on its own.
    my $release_only = _run_karr( $repo, undef, 'edit', 1, '--release' );
    isnt( $release_only->{exit}, 2, '--release alone is not a usage error' );

    # And the task was not mutated by the rejected command.
    my $task = _task($repo);
    is( $task->status, 'todo', 'status unchanged after the rejected invocation' );
    ok( !$task->has_claimed_by, 'and no claim was set' );
};

subtest 'the ticket reproduction: --status X --release no longer slips through require_claim (#150)' => sub {
    my $repo = _setup_repo();

    # Set up the pre-fix reproduction path: claim the task first, then try to
    # land it in a require_claim column while stripping the claim.
    my $claim = _run_karr( $repo, undef, 'edit', 1, '--claim', 'agent-a' );
    is( $claim->{exit}, 0, 'agent-a claims task 1' ) or diag $claim->{stderr};

    # The pre-fix run was exit=0 with the task in in-progress and no claim.
    # The fix: --release now clears the claim before the require_claim guard
    # runs, so apply_status_change sees no claim and refuses the move into
    # in-progress. The exit is 1 (runtime failure), not 2, because the refusal
    # comes from the guard against a status change, the same shape as
    # `karr move 1 in-progress` without --claim.
    my $bug = _run_karr( $repo, undef,
        'edit', 1, '--status', 'in-progress', '--release' );
    is( $bug->{exit}, 1, 'edit --status in-progress --release is now refused' )
        or diag $bug->{stdout} . $bug->{stderr};
    like( $bug->{stderr}, qr/Status 'in-progress' requires --claim/,
        '...with the require_claim message' );

    my $task = _task($repo);
    is( $task->status,     'todo', 'the status did not move into in-progress' );
    is( $task->claimed_by, 'agent-a', 'and the pre-existing claim is still there' );
};

subtest 'unclaimed-then-release: --release clears a claim, plain --status still requires --claim (#150)' => sub {
    my $repo = _setup_repo();

    # --release alone, with nothing else to do, is fine: it clears the claim
    # and that is it.
    my $claim = _run_karr( $repo, undef, 'edit', 1, '--claim', 'alice' );
    is( $claim->{exit}, 0, 'alice claims task 1' ) or diag $claim->{stderr};

    my $release = _run_karr( $repo, undef, 'edit', 1, '--release' );
    is( $release->{exit}, 0, 'edit --release clears the claim' ) or diag $release->{stderr};
    ok( !_task($repo)->has_claimed_by, 'and the claim is gone' );

    # A status change into a require_claim column without --claim is still
    # refused -- the --release carve-out is for breaking somebody else's stale
    # claim, not for landing work in-progress without an owner.
    my $no_claim_move = _run_karr( $repo, undef, 'edit', 1, '--status', 'in-progress' );
    is( $no_claim_move->{exit}, 1,
        'edit --status in-progress without --claim is still refused' )
        or diag $no_claim_move->{stdout} . $no_claim_move->{stderr};
    like( $no_claim_move->{stderr}, qr/requires --claim/,
        '...with the same require_claim message as move' );

    # And the same shape with --claim lands the task and records the claim,
    # the way it always has.
    my $ok = _run_karr( $repo, undef,
        'edit', 1, '--status', 'in-progress', '--claim', 'bob' );
    is( $ok->{exit}, 0, 'edit --status in-progress --claim bob succeeds' )
        or diag $ok->{stderr};

    my $task = _task($repo);
    is( $task->status,     'in-progress', 'status moved into in-progress' );
    is( $task->claimed_by, 'bob',         'and the claim is recorded' );
};

done_testing;
