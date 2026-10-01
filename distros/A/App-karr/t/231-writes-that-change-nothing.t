use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );
use Time::HiRes ();
use JSON::MaybeXS qw( decode_json );

# Ticket #231. Two commands wrote a card they had changed in no way:
#
#   karr move 5 backlog        # card 5 is already at backlog
#   -> Moved task 5: backlog -> backlog     (updated stamped, move logged)
#
#   karr edit 3                # not one field option
#   -> Updated task 3: K3                   (updated stamped, edit logged)
#
# The write is what costs: App::karr::BoardStore/save_task_cas stamps `updated`
# on every write and App::karr::Role::BoardAccess/save_task appends the
# activity-log entry at the same door. `updated` is the field karr-foundation's
# drain reads to tell a stuck card from a worked one (t/31-foundation-drain.t),
# and `context` and `metrics` read it too -- so a command that changed nothing
# and wrote anyway forged that signal and put an entry in the log for an event
# that did not happen.
#
# The two answers differ on purpose, both out of ADR 0002:
#
#   * `move` to the status the card already has is a request whose outcome
#     already holds -- "a no-op like re-archiving an archived task", which the
#     ADR files under exit 0. It reports "Task N is already at X" and, under
#     --json, `changed: false`. kanban-md answers the same way
#     (internal/board/mutate.go:101-104), and `karr archive` on an archived
#     card already did here.
#
#   * `edit` with no field option is not a request at all: no field is named,
#     so there is no state to reach. That is "an argument list that is
#     syntactically fine but semantically empty", which
#     App::karr::Role::ExitCodes/usage_error exists for -- exit 2.
#
# Every subtest below carries its counterproof: the same command with something
# real to do still stamps `updated` and still logs.

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

    is( _run_karr( $repo, 'init', '--name', 'Ticket231 Board' )->{exit}, 0,
        'setup: karr init exits 0' );
    is( _run_karr( $repo, 'create', 'K1' )->{exit}, 0, 'setup: card 1 created' );

    return $repo;
}

sub _field_of {
    my ( $repo, $id, $label ) = @_;
    my $rv = _run_karr( $repo, 'show', $id );
    my ($value) = $rv->{stdout} =~ /^\Q$label\E:\s+(\S+)/m;
    return defined $value ? $value : '';
}

sub _updated_of { _field_of( $_[0], $_[1], 'Updated' ) }

# The actions in the activity log, in order. A write that landed has an entry
# here; one that did not, has none.
sub _log_actions {
    my ($repo) = @_;
    my $rv = _run_karr( $repo, 'log', '--json' );
    my $data = eval { decode_json( $rv->{stdout} ) };
    return () unless ref $data eq 'ARRAY';
    return map { $_->{action} } @$data;
}

# `updated` has one-second resolution, so a same-second write would be
# invisible to the assertions below. Waiting past the second boundary is what
# lets these tests fail: before the fix every stamp checked here moved.
sub _past_the_second { Time::HiRes::sleep(1.1) }

subtest 'a move to the status the card already has writes nothing' => sub {
    my $repo = _setup_repo();

    my $before     = _updated_of( $repo, 1 );
    my @before_log = _log_actions($repo);
    _past_the_second();

    my $rv = _run_karr( $repo, 'move', '1', 'backlog' );
    is( $rv->{exit}, 0, 'exit 0 -- a no-op is success, the way ADR 0002 has it' )
        or diag $rv->{stderr};
    like( $rv->{stdout}, qr/^Task 1 is already at backlog: K1$/m,
        'and it says the card is already there' );
    unlike( $rv->{stdout}, qr/Moved task/,
        'instead of reporting a move from backlog to backlog' );

    is( _updated_of( $repo, 1 ), $before,
        '`updated` is untouched -- the field the drain reads was being forged' );
    is_deeply( [ _log_actions($repo) ], \@before_log,
        'and the activity log gained no entry for an event that did not happen' );
};

subtest '--json says changed: false, and a real move says true' => sub {
    my $repo = _setup_repo();

    my $rv = _run_karr( $repo, 'move', '1', 'backlog', '--json' );
    is( $rv->{exit}, 0, 'move --json onto the same status exits 0' ) or diag $rv->{stderr};
    my $data = eval { decode_json( $rv->{stdout} ) };
    is( ref $data, 'HASH', 'a single id is still a bare object' ) or diag $rv->{stdout};

    ok( exists $data->{changed}, 'the result carries `changed`' );
    ok( !$data->{changed},
        'which is false -- a JSON reader never sees the human line' );
    is( $data->{id},         1,         'the id is reported' );
    is( $data->{old_status}, 'backlog', 'old_status holds the status the card has' );
    is( $data->{new_status}, 'backlog', 'and so does new_status' );

    # The counterproof for the field: it is on both answers, so a reader tests
    # its value rather than its existence.
    my $moved = _run_karr( $repo, 'move', '1', 'todo', '--json' );
    is( $moved->{exit}, 0, 'a real move exits 0' ) or diag $moved->{stderr};
    my $moved_data = eval { decode_json( $moved->{stdout} ) };
    ok( $moved_data->{changed}, 'and reports changed: true' ) or diag $moved->{stdout};
    is( $moved_data->{old_status}, 'backlog', 'from backlog' );
    is( $moved_data->{new_status}, 'todo',    'to todo' );
};

subtest 'a move that really moves the card still stamps and still logs' => sub {
    my $repo = _setup_repo();

    my $before = _updated_of( $repo, 1 );
    _past_the_second();

    my $rv = _run_karr( $repo, 'move', '1', 'todo' );
    is( $rv->{exit}, 0, 'the move goes through' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/^Moved task 1: backlog -> todo$/m, 'and reports it' );

    isnt( _updated_of( $repo, 1 ), $before, '`updated` moved with the card' );
    is_deeply( [ _log_actions($repo) ], [ 'create', 'move' ],
        'and the move is in the activity log' );
};

subtest 'a batch decides per id, not once for the whole list' => sub {
    my $repo = _setup_repo();
    is( _run_karr( $repo, 'create', 'K2' )->{exit}, 0, 'setup: card 2 created' );
    is( _run_karr( $repo, 'move', '2', 'todo' )->{exit}, 0, 'setup: card 2 is at todo' );

    my $rv = _run_karr( $repo, 'move', '1,2', 'backlog', '--json' );
    is( $rv->{exit}, 0, 'the batch exits 0' ) or diag $rv->{stderr};

    my $data = eval { decode_json( $rv->{stdout} ) };
    is( ref $data, 'ARRAY', 'two ids are an array' ) or diag $rv->{stdout};
    ok( !$data->[0]{changed}, 'card 1 was already at backlog: changed false' );
    ok( $data->[1]{changed},  'card 2 came back from todo: changed true' );
    is( $data->[1]{old_status}, 'todo', 'and reports where it came from' );
};

subtest 'edit with no field option is a usage error and writes nothing' => sub {
    my $repo = _setup_repo();

    my $before     = _updated_of( $repo, 1 );
    my @before_log = _log_actions($repo);
    _past_the_second();

    my $rv = _run_karr( $repo, 'edit', '1' );
    is( $rv->{exit}, 2, 'exit 2 -- an invocation that names nothing to change' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stderr}, qr/no changes specified/, 'and says what is missing' );
    unlike( $rv->{stdout}, qr/Updated task/,
        'nothing claims the card was updated' );

    is( _updated_of( $repo, 1 ), $before, '`updated` is untouched' );
    is_deeply( [ _log_actions($repo) ], \@before_log,
        'and no edit entry was appended' );

    # An output option is not a field: it says how the result is printed, not
    # what it is.
    my $json = _run_karr( $repo, 'edit', '1', '--json' );
    is( $json->{exit}, 2, 'edit --json alone is refused the same way' )
        or diag $json->{stdout} . $json->{stderr};
    is( _updated_of( $repo, 1 ), $before, 'and wrote nothing either' );
};

subtest 'an edit that names a field still stamps and still logs' => sub {
    my $repo = _setup_repo();

    my $before = _updated_of( $repo, 1 );
    _past_the_second();

    my $rv = _run_karr( $repo, 'edit', '1', '-a', 'a real note' );
    is( $rv->{exit}, 0, 'the edit goes through' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/^Updated task 1: K1$/m, 'and reports it' );

    isnt( _updated_of( $repo, 1 ), $before, '`updated` moved with the change' );
    is_deeply( [ _log_actions($repo) ], [ 'create', 'edit' ],
        'and the edit is in the activity log' );

    # --release and --unblock carry no value, so they have to count as fields
    # in their own right -- `edit ID --release` is how a stale claim is broken
    # and must not become a usage error (ticket #150, t/154). Out of backlog
    # first: a card there holds no claim (ticket k306).
    is( _run_karr( $repo, 'move', '1', 'todo' )->{exit}, 0, 'setup: card 1 in todo' );
    my $claim = _run_karr( $repo, 'edit', '1', '--claim', 'agent-fox' );
    is( $claim->{exit}, 0, 'edit --claim goes through' ) or diag $claim->{stderr};
    my $release = _run_karr( $repo, 'edit', '1', '--release' );
    is( $release->{exit}, 0, 'and edit --release on its own is not a usage error' )
        or diag $release->{stderr};
    is( _field_of( $repo, 1, 'Claimed' ), '', 'the claim is gone' );
};

subtest 'the reopen release of #224 is neither skipped nor silently taken' => sub {
    my $repo = _setup_repo();

    is( _run_karr( $repo, 'move', '1', 'in-progress', '--claim', 'alpha-one' )->{exit},
        0, 'setup: alpha-one takes the card up' );
    is( _run_karr( $repo, 'move', '1', 'done', '--claim', 'alpha-one' )->{exit},
        0, 'setup: alpha-one finishes it' );
    is( _field_of( $repo, 1, 'Claimed' ), 'alpha-one', 'setup: the finisher is on the card' );

    my $before = _updated_of( $repo, 1 );
    _past_the_second();

    # done -> done is terminal to terminal, which is exactly the pair the #224
    # release cannot fire on -- so the short-circuit in front of it takes
    # nothing away. The claim has to survive this, as provenance (#223).
    my $again = _run_karr( $repo, 'move', '1', 'done' );
    is( $again->{exit}, 0, 'moving a done card to done is a no-op' ) or diag $again->{stderr};
    like( $again->{stdout}, qr/already at done/, 'and says so' );
    is( _field_of( $repo, 1, 'Claimed' ), 'alpha-one',
        'the claim was not released behind the short-circuit' );
    is( _updated_of( $repo, 1 ), $before, 'and nothing was written' );

    # And the release itself still happens where it always did: a real reopen.
    my $reopen = _run_karr( $repo, 'move', '1', 'todo' );
    is( $reopen->{exit}, 0, 'the reopen goes through' ) or diag $reopen->{stderr};
    is( _field_of( $repo, 1, 'Claimed' ), '',
        'and it still releases the claim (#224 intact)' );
    isnt( _updated_of( $repo, 1 ), $before, 'that one did write' );
};

subtest 'move --claim onto the same status is a change and is written' => sub {
    my $repo = _setup_repo();
    # In todo: backlog holds no claim (ticket k306), so there a claim-only
    # move is refused -- t/306-backlog-held-back.t pins that side.
    is( _run_karr( $repo, 'move', '1', 'todo' )->{exit}, 0, 'setup: card 1 in todo' );

    my $before = _updated_of( $repo, 1 );
    _past_the_second();

    # Deliberately not kanban-md's answer. It short-circuits in front of its
    # claim handling and drops the claim; karr's claims expire and gate `pick`,
    # so an agent taking over a card whose claim ran out -- without moving it to
    # another column first -- must not be told nothing happened while nothing
    # did.
    my $rv = _run_karr( $repo, 'move', '1', 'todo', '--claim', 'agent-fox' );
    is( $rv->{exit}, 0, 'move --claim onto the same status goes through' )
        or diag $rv->{stderr};
    is( _field_of( $repo, 1, 'Claimed' ), 'agent-fox', 'the claim landed' );
    isnt( _updated_of( $repo, 1 ), $before, 'the write happened' );
    is_deeply( [ _log_actions($repo) ], [ 'create', 'move', 'move' ],
        'and it is in the activity log, because something did change' );
};

subtest 'a same-status move is not asked for a claim it does not need' => sub {
    my $repo = _setup_repo();

    is( _run_karr( $repo, 'move', '1', 'in-progress', '--claim', 'alpha-one' )->{exit},
        0, 'setup: the card is in a require_claim column' );
    is( _run_karr( $repo, 'edit', '1', '--release' )->{exit}, 0,
        'setup: and its claim is released there' );

    my $before = _updated_of( $repo, 1 );
    _past_the_second();

    # Deliberate, and the order kanban-md uses: the short-circuit sits in front
    # of require_claim, so a card already parked in a column that wants an owner
    # is not what the command declining to move it has to answer for. It used to
    # exit 1 with "Status 'in-progress' requires a claim" for a move that would
    # not have moved anything.
    my $rv = _run_karr( $repo, 'move', '1', 'in-progress' );
    is( $rv->{exit}, 0, 'the no-op is not refused for a missing claim' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stdout}, qr/already at in-progress/, 'it reports the no-op' );
    is( _updated_of( $repo, 1 ), $before, 'and wrote nothing' );

    # The rule itself is untouched where it applies: an actual move into that
    # column still wants an owner.
    is( _run_karr( $repo, 'move', '1', 'todo' )->{exit}, 0, 'move it out again' );
    my $back = _run_karr( $repo, 'move', '1', 'in-progress' );
    is( $back->{exit}, 1, 'a real move into in-progress without --claim is refused' )
        or diag $back->{stdout} . $back->{stderr};
    like( $back->{stderr}, qr/requires a claim/, 'with the require_claim message' );
};

done_testing;
