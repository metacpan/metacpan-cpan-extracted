use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use JSON::MaybeXS qw( decode_json );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::CrossBoard;
use App::karr::Foundation::Picker;

# Ticket #192, work package 8 of the fleet-execution epic (#194): cross-board
# dependencies.
#
# `--depends-on` is board-local. In a fleet the most common real interruption is
# "this cannot be done until X is fixed somewhere else", and that X lives in
# another repository. The escalation protocol the spec writes down is a
# convention and nothing more -- create a card in the other repo tagged
# `escalated-from:<repo>#<id>`, block your own card, release the claim -- so
# nothing verifies that the two cards actually name each other and nothing lifts
# the block when the other card is closed.
#
# What is pinned here, and why each is a decision rather than an accident:
#
#   1. The card carries a BOARD NAME and an id, never a path. Coordination is
#      shared and travels in refs; a path is a property of one machine, and two
#      clones of the same fleet have different ones. The path comes from local
#      configuration or from the invocation, and never touches the card.
#   2. The link is a TAG (`needs:<board>#<id>` / `escalated-from:<board>#<id>`),
#      not a new frontmatter field. kanban-md marshals a card from its own
#      struct, so an unmodelled frontmatter key is dropped the first time it
#      writes; tags are modelled on both sides and survive the interop bridge
#      the file format exists for. `depends_on` itself cannot carry it -- it is
#      an IntSlice over there.
#   3. Terminal is the FAR board's own terminal status, never a hardcoded
#      `done` -- the same rule App::karr::Role::DependencyCheck follows locally.
#   4. A far card that does not exist does NOT settle the link. kanban-md treats
#      a missing local dependency as satisfied; karr already diverges from that
#      for `depends_on` (#123), and unblocking a card because the ticket it was
#      waiting for vanished is exactly the silent wrong answer.
#   5. Nothing new blocks. `depends_on` still warns and hands the card over
#      (#123), App::karr::Foundation::Picker still does not filter on it (#185),
#      and a cross-board link does not filter either. What keeps the waiting
#      card out of `pick` is the `blocked` flag the escalating agent sets on
#      purpose -- the link is the fact, `blocked` is the decision -- and that is
#      what `karr needs --resolve` lifts once the last link settles.
#
# Everything runs in throwaway repositories; the developer's own board is never
# touched, and no agent is ever started.

# A named repository inside one throwaway work directory, so the board names
# the test asserts on are readable instead of a tempdir's random syllables.
sub init_board {
    my ( $work, $name, %opt ) = @_;
    my $repo = path($work)->child($name);
    $repo->mkpath;
    system( 'git', 'init', '-q', "$repo" ) == 0 or die 'git init';
    system( 'git', '-C', "$repo", 'config', 'user.email', 'fleet@example.com' ) == 0
        or die 'git config';
    system( 'git', '-C', "$repo", 'config', 'user.name', 'Fleet' ) == 0
        or die 'git config';
    my $init = run_karr( "$repo", 'init', '--name', $opt{board_name} // $name );
    die "karr init failed: $init->{stderr}" if $init->{exit};
    return "$repo";
}

sub store_for {
    my ($repo) = @_;
    return App::karr::BoardStore->new( git => App::karr::Git->new( dir => $repo ) );
}

sub seed_task {
    my ( $repo, %spec ) = @_;
    my $store = store_for($repo);
    my $task  = App::karr::Task->new(
        id     => $spec{id},
        title  => $spec{title} // "Task $spec{id}",
        status => $spec{status} // 'todo',
        ( $spec{tags} ? ( tags => $spec{tags} ) : () ),
    );
    $task->block( $spec{block} ) if defined $spec{block};
    $store->save_task($task);
    return $task;
}

sub task_on {
    my ( $repo, $id ) = @_;
    return store_for($repo)->find_task($id);
}

sub err_of {
    my ($code) = @_;
    my $err = '';
    eval { $code->(); 1 } or $err = $@;
    return $err;
}

# ---------------------------------------------------------------------------

subtest 'a cross-board reference is a board name and an id, never a path' => sub {
    my $refs = App::karr::CrossBoard->parse_refs( '--needs', 'other-repo#7' );
    is_deeply( $refs, [ { board => 'other-repo', id => 7 } ],
        'board#id parses into its two halves' );

    is( App::karr::CrossBoard->format_ref( $refs->[0] ), 'other-repo#7',
        'and formats back to exactly what was typed' );

    is_deeply(
        App::karr::CrossBoard->parse_refs( '--needs', 'a#1,b#2,a#1' ),
        [ { board => 'a', id => 1 }, { board => 'b', id => 2 } ],
        'a comma-separated list keeps its order and collapses duplicates'
    );

    # The load-bearing refusal: a path is what must never reach a card, because
    # two clones of the same fleet have different ones.
    for my $bad ( '/home/getty/dev/other#7', '../other#7', 'dev/other#7' ) {
        like( err_of( sub { App::karr::CrossBoard->parse_refs( '--needs', $bad ) } ),
            qr/\AUsage error:.*--needs/s, "a path is refused: $bad" );
    }

    for my $bad ( '7', 'other', 'other#', '#7', 'other#x', 'a b#7', 'a#1#2', '' ) {
        like( err_of( sub { App::karr::CrossBoard->parse_refs( '--needs', $bad ) } ),
            qr/\AUsage error:.*--needs/s, "malformed reference is refused: '$bad'" );
    }
};

subtest 'the card carries the link, and carries it where kanban-md keeps it' => sub {
    my $work = tempdir( CLEANUP => 1 );
    my $home = init_board( $work, 'home' );

    my $c = run_karr( $home, 'create', 'Waiting on the other repo',
        '--needs', 'other#7' );
    is( $c->{exit}, 0, 'create --needs succeeds' ) or diag $c->{stderr};

    my $task = task_on( $home, 1 );
    is_deeply( $task->tags, ['needs:other#7'],
        'the link is a tag -- no new frontmatter field, so kanban-md keeps it' );
    is_deeply( $task->depends_on, [],
        'and depends_on is untouched: it is an IntSlice over there' );

    my $md = $task->to_markdown;
    unlike( $md, qr/\Q$work\E/,
        'nothing path-shaped reached the card' );

    is_deeply( [ App::karr::CrossBoard->needs_of($task) ],
        [ { board => 'other', id => 7 } ], 'and karr reads it back off the card' );

    # The far end of the escalation, the convention the spec already writes
    # down, now typed and validated instead of hand-spelled.
    my $other = init_board( $work, 'other' );
    my $e = run_karr( $other, 'create', 'Fix the thing they are waiting for',
        '--escalated-from', 'home#1' );
    is( $e->{exit}, 0, 'create --escalated-from succeeds' ) or diag $e->{stderr};
    is_deeply( task_on( $other, 1 )->tags, ['escalated-from:home#1'],
        'the far card records where the escalation came from' );

    my $bad = run_karr( $home, 'create', 'Nope', '--needs', "$work#7" );
    is( $bad->{exit}, 2, 'a path in --needs is a usage error' );
    like( $bad->{stderr}, qr/Usage error/, 'and says so' );

    my $show = run_karr( $home, 'show', '1' );
    like( $show->{stdout}, qr/^Needs:\s+other#7/m,
        'show prints the cross-board dependency on its own line' );
};

subtest 'edit adds and removes links the way it adds and removes dependencies' => sub {
    my $work = tempdir( CLEANUP => 1 );
    my $home = init_board( $work, 'home' );
    run_karr( $home, 'create', 'Waiting', '--needs', 'other#7' );

    my $add = run_karr( $home, 'edit', '1', '--add-needs', 'third#3' );
    is( $add->{exit}, 0, '--add-needs succeeds' ) or diag $add->{stderr};
    is_deeply( task_on( $home, 1 )->tags, [ 'needs:other#7', 'needs:third#3' ],
        'appended, in order' );

    run_karr( $home, 'edit', '1', '--add-needs', 'third#3' );
    is_deeply( task_on( $home, 1 )->tags, [ 'needs:other#7', 'needs:third#3' ],
        'appending one the card already carries is a no-op, like --add-tag' );

    my $rm = run_karr( $home, 'edit', '1', '--remove-needs', 'other#7' );
    is( $rm->{exit}, 0, '--remove-needs succeeds' ) or diag $rm->{stderr};
    is_deeply( task_on( $home, 1 )->tags, ['needs:third#3'], 'and removes it' );

    my $gone = run_karr( $home, 'edit', '1', '--remove-needs', 'never#1' );
    is( $gone->{exit}, 0,
        'removing a link the card does not carry stays legal, like --remove-depends-on' );

    my $bad = run_karr( $home, 'edit', '1', '--add-needs', 'other' );
    is( $bad->{exit}, 2, 'a malformed reference rejects the whole invocation' );
};

subtest 'karr needs reports the far card, and the path comes from the invocation' => sub {
    my $work  = tempdir( CLEANUP => 1 );
    my $home  = init_board( $work, 'home' );
    my $other = init_board( $work, 'other' );

    seed_task( $other, id => 7, title => 'The prerequisite', status => 'todo' );
    run_karr( $home, 'create', 'Waiting', '--needs', 'other#7' );

    my $blind = run_karr( $home, 'needs' );
    is( $blind->{exit}, 0, 'a board this machine cannot place is not a failure' );
    like( $blind->{stdout}, qr/other#7/, 'the link is still reported' );
    like( $blind->{stdout}, qr/unknown board/i,
        'and says the name could not be placed on this machine' );

    my $seen = run_karr( $home, 'needs', '--board', "other=$other" );
    is( $seen->{exit}, 0, 'with a location it succeeds' ) or diag $seen->{stderr};
    like( $seen->{stdout}, qr/other#7/, 'names the link' );
    like( $seen->{stdout}, qr/\btodo\b/, 'and the far card status' );
    like( $seen->{stdout}, qr/open/, 'which is not settled yet' );

    my $json = run_karr( $home, 'needs', '--board', "other=$other", '--json' );
    my $data = decode_json( $json->{stdout} );
    is( scalar @$data, 1, 'one waiting card in the JSON payload' );
    is( $data->[0]{id}, 1, 'the waiting card' );
    is_deeply(
        [ map { [ @{$_}{qw( ref board task state status )} ] } @{ $data->[0]{needs} } ],
        [ [ 'other#7', 'other', 7, 'open', 'todo' ] ],
        'the link, its two halves, its state and the far status'
    );
};

subtest 'the back-reference is verified, and a mismatch is named' => sub {
    my $work  = tempdir( CLEANUP => 1 );
    my $home  = init_board( $work, 'home' );
    my $other = init_board( $work, 'other' );

    seed_task( $other, id => 7, title => 'The prerequisite' );
    run_karr( $home, 'create', 'Waiting', '--needs', 'other#7' );

    my $unverified = run_karr( $home, 'needs', '--board', "other=$other", '--json' );
    is( decode_json( $unverified->{stdout} )->[0]{needs}[0]{verified}, 0,
        'a far card with no back-reference is reported unverified' );

    seed_task( $other, id => 7, title => 'The prerequisite',
        tags => ['escalated-from:home#9'] );
    my $wrong = run_karr( $home, 'needs', '--board', "other=$other" );
    like( $wrong->{stdout}, qr/home#9/,
        'a back-reference naming a different card is shown, not swallowed' );

    seed_task( $other, id => 7, title => 'The prerequisite',
        tags => ['escalated-from:home#1'] );
    my $right = run_karr( $home, 'needs', '--board', "other=$other", '--json' );
    is( decode_json( $right->{stdout} )->[0]{needs}[0]{verified}, 1,
        'a matching back-reference verifies the link from this end' );
};

subtest '--resolve settles a closed link and lifts the block it caused' => sub {
    my $work  = tempdir( CLEANUP => 1 );
    my $home  = init_board( $work, 'home' );
    my $other = init_board( $work, 'other' );

    # The far board's own final column, not `done`: a fleet member imported
    # from kanban-md may name it anything (#67).
    my $ostore = store_for($other);
    my $ec     = $ostore->effective_config;
    $ostore->save_config( { %$ec, statuses => [qw( backlog todo shipped archived )] } );
    seed_task( $other, id => 7, title => 'The prerequisite', status => 'shipped' );
    seed_task( $other, id => 9, title => 'Still open',       status => 'todo' );

    run_karr( $home, 'create', 'Waiting', '--needs', 'other#7,other#9' );
    run_karr( $home, 'edit', '1', '--block', 'needs other#7: the API has to change first' );

    my $half = run_karr( $home, 'needs', '--resolve', '--board', "other=$other" );
    is( $half->{exit}, 0, 'resolve succeeds' ) or diag $half->{stderr};
    is_deeply( task_on( $home, 1 )->tags, ['needs:other#9'],
        'the settled link is dropped, the open one is kept' );
    ok( task_on( $home, 1 )->has_blocked,
        'and the card stays blocked while it still waits on something' );

    seed_task( $other, id => 9, title => 'Still open', status => 'shipped' );
    my $full = run_karr( $home, 'needs', '--resolve', '--board', "other=$other" );
    is( $full->{exit}, 0, 'the second resolve succeeds' ) or diag $full->{stderr};

    my $freed = task_on( $home, 1 );
    is_deeply( $freed->tags, [], 'the last link is gone' );
    ok( !$freed->has_blocked, 'and the card is unblocked' );
    like( $full->{stdout}, qr/the API has to change first/,
        'the block reason it lifted is printed, so nothing is cleared silently' );

    my $log = run_karr( $home, 'log' );
    like( $log->{stdout}, qr/needs/, 'the activity log records the resolve' );
};

subtest 'a far card that vanished does not settle anything' => sub {
    my $work  = tempdir( CLEANUP => 1 );
    my $home  = init_board( $work, 'home' );
    my $other = init_board( $work, 'other' );

    run_karr( $home, 'create', 'Waiting', '--needs', 'other#7' );
    run_karr( $home, 'edit', '1', '--block', 'needs other#7' );

    my $r = run_karr( $home, 'needs', '--resolve', '--board', "other=$other" );
    is( $r->{exit}, 0, 'reported, not fatal' );
    is_deeply( task_on( $home, 1 )->tags, ['needs:other#7'],
        'the link survives -- a ticket that vanished is not a ticket that is done' );
    ok( task_on( $home, 1 )->has_blocked, 'and the card stays blocked' );
    like( $r->{stdout}, qr/does not exist|missing/i, 'and says what it found' );
};

subtest 'local configuration supplies the path, by the name the fleet already uses' => sub {
    my $work  = tempdir( CLEANUP => 1 );
    my $home  = init_board( $work, 'home' );
    my $other = init_board( $work, 'other' );

    seed_task( $other, id => 7, title => 'The prerequisite', status => 'done' );
    run_karr( $home, 'create', 'Waiting', '--needs', 'other#7' );

    my $cfg = path($work)->child('foundation.yml');
    $cfg->spew_utf8( "hub: $home\ndirs:\n  - $home\n  - $other\n" );

    my $r = run_karr( $home, 'needs', '--fleet-config', "$cfg", '--json' );
    is( $r->{exit}, 0, 'the fleet config places the board' ) or diag $r->{stderr};
    is( decode_json( $r->{stdout} )->[0]{needs}[0]{state}, 'settled',
        'and the far card is read through it, with no --board given' );
};

subtest 'nothing new blocks: the link is the fact, blocked is the decision' => sub {
    my $work  = tempdir( CLEANUP => 1 );
    my $home  = init_board( $work, 'home' );
    my $other = init_board( $work, 'other' );

    seed_task( $other, id => 7, title => 'The prerequisite', status => 'todo' );
    # In todo: a backlog card is held back from pick and foundation alike
    # (ticket k306), and this is about the link, not the column.
    run_karr( $home, 'create', 'Waiting', '--needs', 'other#7', '--status', 'todo' );

    # Foundation must not become stricter than the board it coordinates (#185).
    my $picker = App::karr::Foundation::Picker->new( store => store_for($home) );
    is( $picker->next_ticket, 1,
        'foundation still selects it -- the link is not an eligibility filter' );

    # `karr pick` hands the card over and warns, exactly as it does for an
    # unsatisfied local depends_on (#123).
    my $pick = run_karr( $home, 'pick', '--claim', 'agent-one' );
    is( $pick->{exit}, 0, 'pick still hands out a card with an outstanding link' );
    like( $pick->{stdout}, qr/Picked task 1\b/, 'the very card that is waiting' );
    like( $pick->{stderr}, qr/other#7/,
        'and says out loud what it is waiting on' );

    # What does keep it out is the flag the escalating agent sets on purpose.
    run_karr( $home, 'edit', '1', '--release' );
    run_karr( $home, 'edit', '1', '--block', 'needs other#7' );
    is( App::karr::Foundation::Picker->new( store => store_for($home) )->next_ticket,
        undef, 'a blocked card is not selected -- that is the existing mechanism' );

    seed_task( $other, id => 7, title => 'The prerequisite', status => 'done' );
    run_karr( $home, 'needs', '--resolve', '--board', "other=$other" );
    is( App::karr::Foundation::Picker->new( store => store_for($home) )->next_ticket,
        1, 'and resolving the link is what gives the card back to the fleet' );
};

done_testing;
