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
use App::karr::Error qw( set_original_argv );
use MockStore;

# Ticket #223. App::karr::Role::ClaimTimeout::check_claim knew four cases --
# unclaimed, the claimant matches, the claim expired, otherwise refuse -- and
# not one of them asked what status the card was in. So the agent that finished
# a card went on guarding it for the rest of claim_timeout (1h by default):
#
#   karr move 1 done --claim alpha-one
#   karr edit 1 -a "a late note"   -> Task 1 is claimed by alpha-one
#   karr move 1 todo               -> Task 1 is claimed by alpha-one
#   karr archive 1                 -> Task 1 is claimed by alpha-one
#
# CONTEXT.md defines a Claim as the lease an agent holds *while working* a task
# and calls it released once the task reaches a terminal status, with
# claimed_by kept there for provenance -- which is why `karr board` prints no
# claimant on a finished card and does not count it in its "N claimed" footer.
# The name the refusal demanded was therefore one the board deliberately hides,
# and the guard was never a lock anyway: `karr edit ID --release` takes any
# claim off without knowing whose it is.
#
# What this pins, in both directions:
#
#   * a card in a terminal status is not guarded, for all five commands that
#     apply the rule (edit, move, delete, archive, handoff);
#   * a card in a working status still is, for the same five -- the fix must
#     stay a fifth case and not become a deleted guard;
#   * "terminal" is the board's own word (App::karr::Config/is_terminal_status),
#     so a board that ends in `shipped` releases claims there and nowhere else;
#   * the expired-claim trace of ticket #177 survives on a terminal card, which
#     is why the new case is checked after the expiry test rather than before
#     it.

# In-process runner (t/lib/TestKarr.pm): same ($cwd, @argv) signature and
# { exit, stdout, stderr } return as the open3 helper this file used to carry,
# dispatched through the shared App::karr::Dispatch path. KARR_TEST_SUBPROC=1
# restores the old open3 path.
sub _run_karr { return run_karr(@_) }

# Always a throwaway repo; never the developer's real board.
sub _setup_repo {
    my (%opt) = @_;
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
      or die 'git config failed';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
      or die 'git config failed';

    is( _run_karr( $repo, 'init', '--name', 'Ticket223 Board' )->{exit}, 0,
        'setup: karr init exits 0' );

    for my $n ( 1 .. ( $opt{tasks} || 1 ) ) {
        is( _run_karr( $repo, 'create', "Card $n" )->{exit}, 0,
            "setup: card $n created" );
    }

    return $repo;
}

sub _field_of {
    my ( $repo, $id, $label ) = @_;
    my $rv = _run_karr( $repo, 'show', $id );
    my ($value) = $rv->{stdout} =~ /^\Q$label\E:\s+(\S+)/m;
    return defined $value ? $value : '';
}

my $HOLDER = 'agent-holder';
my $OTHER  = 'agent-other';

subtest 'a finished card is not guarded by the claim of whoever finished it' => sub {
    my $repo = _setup_repo( tasks => 6 );

    is( _run_karr( $repo, 'move', '1,2,3,4,5,6', 'in-progress',
            '--claim', $HOLDER )->{exit}, 0, 'the holder claims all six cards' );
    is( _run_karr( $repo, 'move', '1,2,3,4,5,6', 'done',
            '--claim', $HOLDER )->{exit}, 0, 'and finishes all six' );

    # The claim is still on the card -- the field is provenance, and this test
    # is not about removing it.
    is( _field_of( $repo, 1, 'Claimed' ), $HOLDER,
        "the finisher's name is still on the card" );

    subtest 'edit: the late note the ticket was written about' => sub {
        my $rv = _run_karr( $repo, 'edit', '1', '-a', 'a late note' );
        is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
        unlike( $rv->{stderr}, qr/is claimed by/, 'nothing refused' );
        like( _run_karr( $repo, 'show', '1' )->{stdout}, qr/a late note/,
            'and the note really landed in the body' );
    };

    subtest 'move: reopening a finished card' => sub {
        my $rv = _run_karr( $repo, 'move', '2', 'todo' );
        is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
        unlike( $rv->{stderr}, qr/is claimed by/, 'nothing refused' );
        is( _field_of( $repo, 2, 'Status' ), 'todo', 'and the card is open again' );
    };

    subtest 'archive: the routine end of finished work' => sub {
        my $rv = _run_karr( $repo, 'archive', '3' );
        is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
        unlike( $rv->{stderr}, qr/is claimed by/, 'nothing refused' );
        is( _field_of( $repo, 3, 'Status' ), 'archived', 'and the card is archived' );
    };

    subtest 'delete, which passes no claimant at all' => sub {
        my $rv = _run_karr( $repo, 'delete', '4', '--yes' );
        is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
        unlike( $rv->{stderr}, qr/is claimed by/, 'nothing refused' );
        like( _run_karr( $repo, 'show', '4' )->{stderr}, qr/not found/,
            'and the card is gone' );
    };

    subtest 'handoff under a name that is not the holder' => sub {
        my $rv = _run_karr( $repo, 'handoff', '5', '--claim', $OTHER,
            '--note', 'back for another look' );
        is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
        unlike( $rv->{stderr}, qr/is claimed by/, 'nothing refused' );
        is( _field_of( $repo, 5, 'Status' ), 'review', 'and the card went back' );
    };

    subtest 'archived is terminal too, not just the done column' => sub {
        is( _run_karr( $repo, 'move', '6', 'archived', '--claim', $HOLDER )->{exit},
            0, 'the holder archives its own card' );

        my $rv = _run_karr( $repo, 'edit', '6', '-a', 'a note on an archived card' );
        is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
        unlike( $rv->{stderr}, qr/is claimed by/, 'nothing refused' );
    };
};

subtest 'a card that is still being worked on is guarded exactly as before' => sub {
    my $repo = _setup_repo( tasks => 5 );

    is( _run_karr( $repo, 'move', '1,2,3,4,5', 'in-progress',
            '--claim', $HOLDER )->{exit}, 0, 'the holder claims all five cards' );

    my %refused = (
        'edit'    => [ 'edit',    '1', '-a', 'not mine to write on' ],
        'move'    => [ 'move',    '2', 'review' ],
        'archive' => [ 'archive', '3' ],
        'delete'  => [ 'delete',  '4', '--yes' ],
        'handoff' => [ 'handoff', '5', '--claim', $OTHER ],
    );

    for my $cmd ( sort keys %refused ) {
        my $rv = _run_karr( $repo, @{ $refused{$cmd} } );
        isnt( $rv->{exit}, 0, "$cmd is still refused on a live claim" );
        like( $rv->{stderr}, qr/is claimed by \Q$HOLDER\E/,
            "...and still names the holder ($cmd)" );
    }

    is( _field_of( $repo, 1, 'Status' ), 'in-progress',
        'and every card is still where its holder left it' );
    is( _field_of( $repo, 4, 'Claimed' ), $HOLDER, 'claim intact' );
};

# ---------------------------------------------------------------------------
# The rule reads the board's terminal statuses, never a literal `done`.
# ---------------------------------------------------------------------------

{
    package ClaimConsumer;
    use Moo;
    has store => ( is => 'ro' );
    # The other two names the role requires. Nothing here prints: quiet keeps
    # expired_claim_report's human copy out of the test output while its return
    # value is still the pair the assertions read.
    sub json  { 0 }
    sub quiet { 1 }
    with 'App::karr::Role::ClaimTimeout';
}

sub _consumer_for {
    my (@statuses) = @_;
    my $ec = { %{ App::karr::Config->default_config } };
    $ec->{statuses} = [@statuses] if @statuses;
    return ClaimConsumer->new( store => MockStore->new( ec => $ec ) );
}

sub _claimed_card {
    my ( $status, $secs_ago ) = @_;
    return App::karr::Task->new(
        id         => 1,
        title      => 'Claimed card',
        status     => $status,
        claimed_by => $HOLDER,
        claimed_at => gmtime( time - ( $secs_ago // 5 ) )->datetime . 'Z',
    );
}

# The answer plus the reason, so a check_claim that died of something other
# than the claim rule -- a missing method on the store, say -- cannot read as
# "the card was guarded".
sub _answer_of {
    my ( $consumer, $status ) = @_;
    # The refusal appends the caller's own command line with --claim HOLDER
    # when App::karr::Error/original_argv was recorded (ticket #269). The CLI
    # subtests above recorded theirs, and this direct call has none of its own
    # -- so the recorded one is cleared, and the message is pinned as the
    # no-argv shape: prose plus the release door, and nothing else.
    set_original_argv();
    my $ok = eval { $consumer->check_claim( _claimed_card($status), $OTHER ) };
    return $ok ? 'allowed' : $@;
}

subtest 'terminal is whatever the board calls terminal' => sub {
    my $default = _consumer_for();
    is( _answer_of( $default, 'done' ), 'allowed',
        'default board: a claim on `done` guards nothing' );
    like( _answer_of( $default, 'review' ),
        qr/\ATask 1 is claimed by \Q$HOLDER\E:\n  karr edit 1 --release\n\z/,
        'default board: a claim on `review` still guards the card' );

    # A board imported from kanban-md may end anywhere; `done` is not even a
    # column here, and `shipped` is the finished one (ticket #67/#98).
    my $custom = _consumer_for(qw( backlog doing shipped archived ));
    is( _answer_of( $custom, 'shipped' ), 'allowed',
        'custom board: a claim on `shipped` guards nothing' );
    is( _answer_of( $custom, 'archived' ), 'allowed',
        'custom board: `archived` is terminal here too' );
    like( _answer_of( $custom, 'doing' ),
        qr/\ATask 1 is claimed by \Q$HOLDER\E:\n  karr edit 1 --release\n\z/,
        'custom board: a claim on `doing` still guards the card' );

    # And the boards really do disagree: `done` is not a column on the custom
    # board, so nothing there releases the claim for it.
    like( _answer_of( $custom, 'done' ),
        qr/\ATask 1 is claimed by \Q$HOLDER\E:\n  karr edit 1 --release\n\z/,
        'custom board: `done` is no longer the magic word' );
};

subtest 'an expired claim on a finished card is still reported (#177)' => sub {
    # Order, not decoration: the terminal case is checked after the expiry
    # test, so a takeover that would have been recorded before still is.
    # karr-foundation reads that record for the holder's name.
    my $c = _consumer_for();
    ok( $c->check_claim( _claimed_card( 'done', 7200 ), $OTHER ),
        'the call goes through' );
    my %report = $c->expired_claim_report(1);
    is( $report{expired_claim}{held_by}, $HOLDER,
        'and the expired claim it stepped over is still on the record' );
};

done_testing;
