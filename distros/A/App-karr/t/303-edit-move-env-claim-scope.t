use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );

use App::karr::Git;

# Tickets #303 (edit) and #304 (move): KARR_CLAIM is written onto a card only
# when the card ends up in a require_claim column -- the rule create has
# followed since #286 (ADR 0005), now shared through
# App::karr::Role::ClaimDefault/resolved_claim_for.
#
# The house rules have every session export KARR_CLAIM first thing. Before
# this, move and edit stamped it whatever the column:
#
#   * `karr edit ID -a note` on a backlog card claimed it for the caller, so
#     every agent note took the card out of `pick` and `list --unclaimed`
#     for claim_timeout
#   * `karr move ID todo` -- promoting a card into the pool for someone else
#     -- left the promoter holding it
#   * `karr edit ID --release` cleared the claim and then stamped the env
#     name back on with a fresh claimed_at
#
# The rule now:
#
#   * KARR_CLAIM is written only when the card ends in a require_claim status
#     (the move destination; edit's --status, else the card's current one)
#   * an explicit --claim stamps on any status but backlog, which holds no
#     claim at all (ticket k306, t/306-backlog-held-back.t)
#   * --release never claims; --release with an explicit --claim is a usage
#     error (exit 2)
#   * the env name still identifies the caller for check_claim, so a card
#     the caller holds stays editable in any column
#
# The default board marks in-progress and review require_claim and leaves
# backlog and todo bare (App::karr::Config/default_config), so a plain
# `karr init` board is the fixture.

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    return run_karr( $cwd, @argv );
}

sub _board_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo )                                     == 0 or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0 or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' )         == 0 or die 'git config';
    my $init = _run_karr( $repo, 'init', '--name', 'k303 Board' );
    is( $init->{exit}, 0, 'setup: karr init' ) or diag $init->{stderr};
    return $repo;
}

sub _task {
    my ( $repo, $id ) = @_;
    return App::karr::Git->new( dir => $repo )->load_task_ref( $id // 1 );
}

# A backlog card created with KARR_CLAIM unset, so whatever claim it ends up
# with came from the command under test.
sub _backlog_card {
    my ( $repo, $title ) = @_;
    local $ENV{KARR_CLAIM};
    delete $ENV{KARR_CLAIM};
    my $rv = _run_karr( $repo, 'create', $title );
    is( $rv->{exit}, 0, "setup: create '$title'" ) or diag $rv->{stderr};
}

#### edit (ticket #303)

subtest 'edit -a on a backlog card: the note is written, no claim' => sub {
    my $repo = _board_repo();
    _backlog_card( $repo, 'Sorting' );
    local $ENV{KARR_CLAIM} = 'me';

    my $rv = _run_karr( $repo, 'edit', '1', '-a', 'a note' );
    is( $rv->{exit}, 0, 'edit -a succeeds' ) or diag $rv->{stderr};

    my $task = _task($repo);
    like( $task->body, qr/a note/, 'the note landed' );
    is( $task->status, 'backlog', 'still in the backlog' );
    ok( !$task->has_claimed_by, 'no claimed_by from the environment' )
        or diag 'claimed_by: ' . $task->claimed_by;
    ok( !$task->has_claimed_at, 'and no claimed_at either' );
};

subtest 'edit --status todo: the card lands in todo unclaimed' => sub {
    my $repo = _board_repo();
    _backlog_card( $repo, 'Promote me' );
    local $ENV{KARR_CLAIM} = 'me';

    my $rv = _run_karr( $repo, 'edit', '1', '--status', 'todo' );
    is( $rv->{exit}, 0, 'edit --status todo succeeds' ) or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->status, 'todo', 'card is in todo' );
    ok( !$task->has_claimed_by, 'a column that needs no claim gets none from the env' )
        or diag 'claimed_by: ' . $task->claimed_by;
};

subtest 'edit --release releases, and the env does not claim it back' => sub {
    my $repo = _board_repo();
    _backlog_card( $repo, 'Held' );
    local $ENV{KARR_CLAIM} = 'me';

    my $mv = _run_karr( $repo, 'move', '1', 'in-progress' );
    is( $mv->{exit}, 0, 'setup: move in-progress via the env' ) or diag $mv->{stderr};
    is( _task($repo)->claimed_by, 'me', 'setup: held under the env name' );

    my $rv = _run_karr( $repo, 'edit', '1', '--release' );
    is( $rv->{exit}, 0, 'edit --release succeeds' ) or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->status, 'in-progress', 'status untouched' );
    ok( !$task->has_claimed_by, 'claimed_by is gone' )
        or diag 'claimed_by: ' . $task->claimed_by;
    ok( !$task->has_claimed_at, 'claimed_at is gone too' );
};

subtest 'edit --release --claim X is a usage error, and nothing is written' => sub {
    my $repo = _board_repo();
    _backlog_card( $repo, 'Held' );
    local $ENV{KARR_CLAIM} = 'me';

    _run_karr( $repo, 'move', '1', 'in-progress' );
    my $before = _task($repo);
    is( $before->claimed_by, 'me', 'setup: held under the env name' );

    my $rv = _run_karr( $repo, 'edit', '1', '--release', '--claim', 'X' );
    is( $rv->{exit}, 2, 'exit 2, a usage error (ADR 0002)' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr}, qr/cannot use --claim and --release together/,
        'the error names the contradiction' );

    my $after = _task($repo);
    is( $after->claimed_by, 'me', 'the claim is unchanged' );
    is( $after->claimed_at, $before->claimed_at, 'and so is its timestamp' );
};

subtest 'edit --release --status in-progress: the env does not satisfy require_claim' => sub {
    # The #150 refusal, which the env name used to walk around: --release
    # clears the claim, and a release does not claim, so a require_claim
    # destination has no owner and is refused.
    my $repo = _board_repo();
    _backlog_card( $repo, 'Not like this' );
    local $ENV{KARR_CLAIM} = 'me';

    my $rv = _run_karr( $repo, 'edit', '1', '--release', '--status', 'in-progress' );
    is( $rv->{exit}, 1, 'refused, exit 1' ) or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr}, qr/^Status 'in-progress' requires a claim/m,
        'with the require_claim refusal' );

    my $task = _task($repo);
    is( $task->status, 'backlog', 'the card did not move' );
    ok( !$task->has_claimed_by, 'and is not claimed' );
};

subtest 'edit -a on a card the caller holds: allowed, and the claim stays' => sub {
    # The env name is still who the caller is: check_claim compares it with
    # the card, and a require_claim column keeps being held under it.
    my $repo = _board_repo();
    _backlog_card( $repo, 'Mine' );
    local $ENV{KARR_CLAIM} = 'me';

    _run_karr( $repo, 'move', '1', 'in-progress' );

    my $rv = _run_karr( $repo, 'edit', '1', '-a', 'progress' );
    is( $rv->{exit}, 0, 'edit -a on my own card succeeds' ) or diag $rv->{stderr};

    my $task = _task($repo);
    like( $task->body, qr/progress/, 'the note landed' );
    is( $task->claimed_by, 'me', 'still held under the env name' );
};

subtest 'edit with an explicit --claim stamps on a todo card, not on a backlog one' => sub {
    my $repo = _board_repo();
    _backlog_card( $repo, 'Reserved' );
    local $ENV{KARR_CLAIM} = 'me';

    # backlog holds no claim at all (ticket k306), explicit or not.
    my $rv = _run_karr( $repo, 'edit', '1', '--claim', 'other' );
    is( $rv->{exit}, 1, 'edit --claim on the backlog card is refused' );
    ok( !_task($repo)->has_claimed_by, 'and nothing was stamped' );

    is( _run_karr( $repo, 'move', '1', 'todo' )->{exit}, 0, 'setup: promoted to todo' );
    $rv = _run_karr( $repo, 'edit', '1', '--claim', 'other' );
    is( $rv->{exit}, 0, 'edit --claim succeeds in todo' ) or diag $rv->{stderr};
    is( _task($repo)->claimed_by, 'other',
        'the explicit flag stamps on a status that needs no claim' );
};

#### move (ticket #304)

subtest 'move ID todo: promoted into the pool unclaimed' => sub {
    my $repo = _board_repo();
    _backlog_card( $repo, 'Promoted' );

    {
        local $ENV{KARR_CLAIM} = 'promoter';
        my $rv = _run_karr( $repo, 'move', '1', 'todo' );
        is( $rv->{exit}, 0, 'move todo succeeds' ) or diag $rv->{stderr};
    }

    my $task = _task($repo);
    is( $task->status, 'todo', 'card is in todo' );
    ok( !$task->has_claimed_by, 'the promoter did not claim it' )
        or diag 'claimed_by: ' . $task->claimed_by;
    ok( !$task->has_claimed_at, 'no claimed_at either' );

    {
        local $ENV{KARR_CLAIM} = 'worker';
        my $un = _run_karr( $repo, 'list', '--unclaimed', '--status', 'todo', '--compact' );
        is( $un->{exit}, 0, 'another agent lists unclaimed todo' ) or diag $un->{stderr};
        like( $un->{stdout}, qr/Promoted/, 'and sees the promoted card' );
    }
};

subtest 'move --next into todo: unclaimed as well' => sub {
    # The destination is only known once the card has been read, so the
    # decision has to be taken there and not from the command line.
    my $repo = _board_repo();
    _backlog_card( $repo, 'Next' );
    local $ENV{KARR_CLAIM} = 'promoter';

    my $rv = _run_karr( $repo, 'move', '1', '--next' );
    is( $rv->{exit}, 0, 'move --next succeeds' ) or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->status, 'todo', 'backlog -> todo' );
    ok( !$task->has_claimed_by, 'no claim from the environment' );
};

subtest 'move ID in-progress: claimed from KARR_CLAIM' => sub {
    my $repo = _board_repo();
    _backlog_card( $repo, 'Start' );
    local $ENV{KARR_CLAIM} = 'starter';

    my $rv = _run_karr( $repo, 'move', '1', 'in-progress' );
    is( $rv->{exit}, 0, 'move in-progress is satisfied by the env' ) or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->status,     'in-progress', 'card is in progress' );
    is( $task->claimed_by, 'starter',     'claimed_by is the env name' );
    like( $task->claimed_at, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/,
        'claimed_at is stamped' );
};

subtest 'move ID todo --claim X: an explicit claim stamps on todo' => sub {
    my $repo = _board_repo();
    _backlog_card( $repo, 'Reserved' );
    local $ENV{KARR_CLAIM} = 'promoter';

    my $rv = _run_karr( $repo, 'move', '1', 'todo', '--claim', 'X' );
    is( $rv->{exit}, 0, 'move todo --claim succeeds' ) or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->status,     'todo', 'card is in todo' );
    is( $task->claimed_by, 'X',    'the explicit flag wins on any status' );
    ok( $task->has_claimed_at, 'and claimed_at is stamped with it' );
};

subtest 'move to the status the card has, env only: nothing to write' => sub {
    # Only an explicit --claim turns a same-status move into a write (#231);
    # an env name that would not be written on todo cannot either.
    my $repo = _board_repo();
    _backlog_card( $repo, 'Already there' );
    {
        local $ENV{KARR_CLAIM};
        delete $ENV{KARR_CLAIM};
        _run_karr( $repo, 'move', '1', 'todo' );
    }
    local $ENV{KARR_CLAIM} = 'me';

    my $rv = _run_karr( $repo, 'move', '1', 'todo' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/already at todo/, 'reported as already there' );
    ok( !_task($repo)->has_claimed_by, 'and not claimed' );
};

subtest 'reopening a finished card into todo releases its claim despite the env' => sub {
    # The #224 release fires when the reopening command names no claimant.
    # KARR_CLAIM used to count as naming one, so the finished card came back
    # to todo held -- by the env name, not even the one that finished it.
    my $repo = _board_repo();
    {
        local $ENV{KARR_CLAIM};
        delete $ENV{KARR_CLAIM};
        my $c = _run_karr( $repo, 'create', 'Finished', '--status', 'in-progress',
            '--claim', 'finisher' );
        is( $c->{exit}, 0, 'setup: create in-progress' ) or diag $c->{stderr};
        my $d = _run_karr( $repo, 'move', '1', 'done', '--claim', 'finisher' );
        is( $d->{exit}, 0, 'setup: move done' ) or diag $d->{stderr};
    }
    local $ENV{KARR_CLAIM} = 'me';

    my $rv = _run_karr( $repo, 'move', '1', 'todo' );
    is( $rv->{exit}, 0, 'reopen succeeds' ) or diag $rv->{stderr};

    my $task = _task($repo);
    is( $task->status, 'todo', 'card is back in todo' );
    ok( !$task->has_claimed_by, 'unheld, free for anyone to pick' )
        or diag 'claimed_by: ' . $task->claimed_by;
};

done_testing;
