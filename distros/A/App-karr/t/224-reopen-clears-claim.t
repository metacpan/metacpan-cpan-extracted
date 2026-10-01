use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );
use Time::Piece;

use App::karr::Config;
use App::karr::Task;
use MockStore;

# Ticket #224. A status change never cleared claimed_by, so a card leaving a
# terminal status carried the finisher's name into a working column, where it
# is a live lease again:
#
#   karr move 1 in-progress --claim alpha-one
#   karr move 1 done        --claim alpha-one
#   karr move 1 todo                            # reopen, no --claim
#   karr show 1   -> Status: todo   Claimed: alpha-one
#   karr edit 1 -a "x"          -> Task 1 is claimed by alpha-one
#   karr pick --claim beta-two  -> No available tasks to pick.
#
# The card sits in todo, `karr list` shows it as open work, `karr board` counts
# it under "1 claimed", and the picker hands it to nobody -- on a board holding
# that one card, `pick` still answered "No available tasks to pick". That is a
# drain-run standstill nothing reports.
#
# The rule this pins, from App::karr::Role::TaskMutation/apply_status_change:
# a card leaving a terminal status for a non-terminal one, with no new claimant
# passed by the caller, has claimed_by and claimed_at cleared.
#
# All three restrictions matter, and each is pinned separately below:
#
#   * terminal -> non-terminal. `karr archive` on a done card is terminal ->
#     terminal and must NOT clear -- CONTEXT.md keeps claimed_by on a finished
#     card as provenance;
#   * no new claimant. `move ID todo --claim beta-two` and `handoff --claim`
#     bring one, and that name wins;
#   * terminal is the board's own word (App::karr::Config/is_terminal_status),
#     never the literal `done`, the same way ticket #223 asked it.
#
# The damage is the point, so the CLI half pins that the reopened card is
# `karr pick`-able again, not merely that a field went away.

# In-process runner (t/lib/TestKarr.pm): same ($cwd, @argv) signature and
# { exit, stdout, stderr } return as the open3 helper this file used to carry,
# dispatched through the shared App::karr::Dispatch path. KARR_TEST_SUBPROC=1
# restores the old open3 path.
sub _run_karr { return run_karr(@_) }

# Always a throwaway repo; never the developer's real board.
sub _setup_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
      or die 'git config failed';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
      or die 'git config failed';

    is( _run_karr( $repo, 'init', '--name', 'Ticket224 Board' )->{exit}, 0,
        'setup: karr init exits 0' );
    is( _run_karr( $repo, 'create', 'Card one' )->{exit}, 0,
        'setup: the one card is created' );

    return $repo;
}

sub _field_of {
    my ( $repo, $id, $label ) = @_;
    my $rv = _run_karr( $repo, 'show', $id );
    my ($value) = $rv->{stdout} =~ /^\Q$label\E:\s+(\S+)/m;
    return defined $value ? $value : '';
}

# A card finished by $HOLDER, which is where every case below starts.
sub _finished_card {
    my ($repo) = @_;
    is( _run_karr( $repo, 'move', '1', 'in-progress', '--claim', 'alpha-one' )->{exit},
        0, 'setup: alpha-one takes the card up' );
    is( _run_karr( $repo, 'move', '1', 'done', '--claim', 'alpha-one' )->{exit},
        0, 'setup: alpha-one finishes it' );
    is( _field_of( $repo, 1, 'Claimed' ), 'alpha-one',
        'setup: the finisher is on the card' );
    return;
}

subtest 'a reopened card goes back into the pool' => sub {
    my $repo = _setup_repo();
    _finished_card($repo);

    my $rv = _run_karr( $repo, 'move', '1', 'todo' );
    is( $rv->{exit}, 0, 'the reopen itself goes through' ) or diag $rv->{stderr};
    is( _field_of( $repo, 1, 'Status' ), 'todo', 'the card is open work again' );
    is( _field_of( $repo, 1, 'Claimed' ), '',
        "and no longer carries the finisher's claim" );

    unlike( _run_karr( $repo, 'board' )->{stdout}, qr/claimed/,
        'karr board counts no claim on it' );

    my $edit = _run_karr( $repo, 'edit', '1', '-a', 'a note from somebody else' );
    is( $edit->{exit}, 0, 'a third party may edit it' ) or diag $edit->{stderr};
    unlike( $edit->{stderr}, qr/is claimed by/, 'nothing refused' );

    # The damage the ticket is actually about: the card was invisible to the
    # picker while sitting in todo as the board's only open work.
    my $pick = _run_karr( $repo, 'pick', '--claim', 'beta-two' );
    is( $pick->{exit}, 0, 'karr pick exits 0' ) or diag $pick->{stderr};
    like( $pick->{stdout}, qr/Picked task 1\b/,
        'and hands the card out -- it used to answer "No available tasks to pick."' );
    is( _field_of( $repo, 1, 'Claimed' ), 'beta-two', 'the picker now holds it' );
};

subtest 'a reopen that brings a claimant hands the card to that name' => sub {
    my $repo = _setup_repo();
    _finished_card($repo);

    my $rv = _run_karr( $repo, 'move', '1', 'todo', '--claim', 'beta-two' );
    is( $rv->{exit}, 0, 'move --claim goes through' ) or diag $rv->{stderr};
    is( _field_of( $repo, 1, 'Claimed' ), 'beta-two',
        'the new claimant wins -- neither the old name nor nothing at all' );
};

subtest 'handoff out of a terminal status keeps its own claim' => sub {
    my $repo = _setup_repo();
    _finished_card($repo);

    # --claim is required on handoff, so this path always brings a claimant and
    # the clearing rule never applies to it.
    my $rv = _run_karr( $repo, 'handoff', '1', '--claim', 'beta-two' );
    is( $rv->{exit}, 0, 'handoff off a done card goes through' ) or diag $rv->{stderr};
    is( _field_of( $repo, 1, 'Status' ),  'review',   'it lands in review' );
    is( _field_of( $repo, 1, 'Claimed' ), 'beta-two', 'held by the agent that handed it off' );
};

subtest 'archive keeps the finisher on the card' => sub {
    my $repo = _setup_repo();
    _finished_card($repo);

    # done -> archived is terminal -> terminal, so nothing is released:
    # CONTEXT.md keeps claimed_by on a finished card as provenance, and
    # `karr archive` passes no claimant of its own.
    my $rv = _run_karr( $repo, 'archive', '1' );
    is( $rv->{exit}, 0, 'archive goes through' ) or diag $rv->{stderr};
    is( _field_of( $repo, 1, 'Status' ),  'archived',  'the card is archived' );
    is( _field_of( $repo, 1, 'Claimed' ), 'alpha-one', 'and still names who finished it' );
};

subtest 'a reopen into a column that wants an owner asks for one' => sub {
    my $repo = _setup_repo();
    _finished_card($repo);

    # The released claim must not go on satisfying require_claim on its way
    # out: clearing after that check would land the card in a require_claim
    # column with no claim at all, which is the hole ticket #150 closed for
    # `edit --release`.
    my $rv = _run_karr( $repo, 'move', '1', 'in-progress' );
    isnt( $rv->{exit}, 0, 'a claimless reopen into in-progress is refused' );
    like( $rv->{stderr}, qr/requires a claim/, 'and says what it wants' );
    like( $rv->{stderr}, qr/^  karr move 1 in-progress --claim NAME$/m,
        'and the invocation that would have worked (k263)' );
    is( _field_of( $repo, 1, 'Status' ), 'done', 'the card did not move' );
    is( _field_of( $repo, 1, 'Claimed' ), 'alpha-one',
        'and a refused move released nothing' );

    my $ok = _run_karr( $repo, 'move', '1', 'in-progress', '--claim', 'beta-two' );
    is( $ok->{exit}, 0, 'with a claimant it goes through' ) or diag $ok->{stderr};
    is( _field_of( $repo, 1, 'Claimed' ), 'beta-two', 'held by the new agent' );
};

subtest 'the activity log still names who finished the card' => sub {
    my $repo = _setup_repo();
    _finished_card($repo);
    is( _run_karr( $repo, 'move', '1', 'todo' )->{exit}, 0, 'reopen' );

    # CONTEXT.md names the activity log as the provenance source: the name
    # leaves the card, so the trace has to be readable there.
    my $log = _run_karr( $repo, 'log', '--json' )->{stdout};
    like( $log, qr/"action":"move","agent":"alpha-one","detail":"done"/,
        'the finishing move is on record under the finisher' );
    like( $log, qr/"action":"move","agent":"Test User","detail":"todo"/,
        'and the reopen is attributed to whoever ran it, not to the released claim' );
};

# ---------------------------------------------------------------------------
# Terminal is the board's own word, never the literal `done`.
# ---------------------------------------------------------------------------

{
    package MutationConsumer;
    use Moo;
    has store => ( is => 'ro' );
    # The collaborators the mutation-path roles declare. Nothing here writes:
    # apply_status_change is called directly, so the compare-and-swap loop and
    # the activity log are not on this path at all.
    sub git            { undef }
    sub save_task      { 1 }
    sub log_task_write { 1 }
    sub find_task      { undef }
    sub json           { 0 }
    sub quiet          { 1 }
    with 'App::karr::Role::TaskMutation';
}

sub _consumer_for {
    my (@statuses) = @_;
    my $ec = { %{ App::karr::Config->default_config } };
    $ec->{statuses} = [@statuses] if @statuses;
    return MutationConsumer->new( store => MockStore->new( ec => $ec ) );
}

sub _claimed_card {
    my ($status) = @_;
    return App::karr::Task->new(
        id         => 1,
        title      => 'Claimed card',
        status     => $status,
        claimed_by => 'alpha-one',
        claimed_at => gmtime( time - 5 )->datetime . 'Z',
    );
}

subtest 'the board decides which move releases the claim' => sub {
    my $default = _consumer_for();

    my $reopened = _claimed_card('done');
    $default->apply_status_change( $reopened, 'todo', undef );
    ok( !$reopened->has_claimed_by, 'default board: done -> todo releases the claim' );
    ok( !$reopened->has_claimed_at, 'and the stamp goes with the name' );

    my $archived = _claimed_card('done');
    $default->apply_status_change( $archived, 'archived', undef );
    is( $archived->claimed_by, 'alpha-one',
        'default board: done -> archived is terminal to terminal and keeps it' );

    # A board imported from kanban-md may end anywhere. Here `shipped` is the
    # final column and `done` is an ordinary working one -- so the release
    # happens at `shipped` and nowhere else.
    my @custom = qw( backlog todo done shipped archived );
    my $board  = _consumer_for(@custom);

    my $shipped = _claimed_card('shipped');
    $board->apply_status_change( $shipped, 'done', undef );
    ok( !$shipped->has_claimed_by, 'custom board: shipped -> done releases the claim' );

    # Into todo, not backlog: a move into backlog releases the claim from any
    # column (ticket k306), which would say nothing about `done` here.
    my $working = _claimed_card('done');
    $board->apply_status_change( $working, 'todo', undef );
    is( $working->claimed_by, 'alpha-one',
        'custom board: `done` is no longer the magic word' );
};

done_testing;
