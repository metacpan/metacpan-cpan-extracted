use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );

# Ticket #295, direction (B): a task can sit in a terminal status (done) while
# still carrying the blocked flag -- the #223/#224 convention keeps block_reason
# on the card as provenance and never clears it. Before this fix the `karr board`
# footer counted every blocked card, terminal ones included, so a done+blocked
# card was counted-but-invisible ("2 blocked" while the board listed one). The
# footer now counts only live (non-terminal) blocked cards as active -- the same
# is_terminal_status test the claimed count uses -- and breaks the hidden ones
# out as "(M in <final>)" so they cannot stay invisible. Rendering only: the
# flag and its reason are untouched.

sub _git_ok {
    my (@cmd) = @_;
    is( system(@cmd), 0, "@cmd" );
}

sub _setup_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );

    my $init = run_karr( $repo, 'init', '--name', 'Blocked Board' );
    is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

    # id 1: live blocked (stays in todo)   -- an active blocker
    # id 2: blocked, then moved to done    -- provenance kept, but not active
    # id 3: plain todo                      -- neither
    for my $spec (
        [ 'Live blocked', 'todo' ],
        [ 'Done blocked', 'todo' ],
        [ 'Plain todo',   'todo' ],
    ) {
        my ( $title, $status ) = @$spec;
        my $rv = run_karr( $repo, 'create', '--title', $title, '--status', $status );
        is( $rv->{exit}, 0, "create '$title' succeeds" ) or diag $rv->{stderr};
    }

    for my $id ( 1, 2 ) {
        my $rv = run_karr( $repo, 'edit', $id, '--block', "reason for $id" );
        is( $rv->{exit}, 0, "edit $id --block succeeds" ) or diag $rv->{stderr};
    }

    my $mv = run_karr( $repo, 'move', 2, 'done' );
    is( $mv->{exit}, 0, 'move 2 done succeeds' ) or diag $mv->{stderr};

    return $repo;
}

subtest 'karr board footer: terminal blocked card is broken out, not counted active' => sub {
    my $repo = _setup_repo();
    my $rv   = run_karr( $repo, 'board' );
    is( $rv->{exit}, 0, 'karr board exits 0' ) or diag $rv->{stderr};

    like( $rv->{stdout}, qr/^3 tasks \(1 done hidden\)\s+1 blocked \(1 in done\)/m,
        'footer counts one active blocker and breaks out the one hidden in done' );

    # The bug: the terminal blocked card was counted as active ("2 blocked").
    unlike( $rv->{stdout}, qr/\b2 blocked\b/,
        'the done+blocked card is NOT counted as an active blocker' );

    # Done column withheld by default, so its blocked card is invisible as a row
    # -- which is exactly why the footer breakout has to name it.
    unlike( $rv->{stdout}, qr/Done blocked/,
        'the done card itself is hidden from the default board' );
};

subtest 'karr board --done: done card visible, annotation suppressed, still not active' => sub {
    my $repo = _setup_repo();
    my $rv   = run_karr( $repo, 'board', '--done' );
    is( $rv->{exit}, 0, 'karr board --done exits 0' ) or diag $rv->{stderr};

    like( $rv->{stdout}, qr/Done blocked/, 'done card is shown with --done' );
    like( $rv->{stdout}, qr/\b1 blocked\b/, 'still only one active blocker' );
    unlike( $rv->{stdout}, qr/in done\)/,
        'no "(N in done)" annotation once the done column is shown' );
    unlike( $rv->{stdout}, qr/\b2 blocked\b/,
        'the done+blocked card is still not counted as active' );
};

subtest 'karr list --blocked (default) does not register the terminal card' => sub {
    my $repo = _setup_repo();
    my $rv   = run_karr( $repo, 'list', '--blocked' );
    is( $rv->{exit}, 0, 'karr list --blocked exits 0' ) or diag $rv->{stderr};

    like( $rv->{stdout}, qr/Live blocked/, 'the live blocked card is listed' );
    unlike( $rv->{stdout}, qr/Done blocked/,
        'the done+blocked card is not in the default blocked listing' );
};

subtest 'block_reason survives on the terminal card and is reachable with --status done' => sub {
    my $repo = _setup_repo();
    my $rv   = run_karr( $repo, 'list', '--blocked', '--status', 'done' );
    is( $rv->{exit}, 0, 'karr list --blocked --status done exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/Done blocked/,
        'the done+blocked card is still reachable (provenance kept, #223/#224)' );
};

# End-to-end companion to t/229 (which drives Cmd::Context directly): `karr
# context` applies the same terminal-blocked exclusion through the real
# dispatch path, so its default briefing does not count or list a done+blocked
# card as an active blocker (ticket #295, deliberately diverging from kanban-md
# -- see docs/adr/0006).
subtest 'karr context excludes the terminal blocked card from the blocked surfaces' => sub {
    my $repo = _setup_repo();
    my $rv   = run_karr( $repo, 'context' );
    is( $rv->{exit}, 0, 'karr context exits 0' ) or diag $rv->{stderr};

    like( $rv->{stdout}, qr/\| 1 blocked \|/,
        'header counts one active blocker, not two' );
    like( $rv->{stdout}, qr/^### Blocked$/m, 'the Blocked section renders' );
    like( $rv->{stdout}, qr/Live blocked/, 'with the live blocked card' );
    unlike( $rv->{stdout}, qr/^- \*\*#2\*\* Done blocked.*blocked:/m,
        'but the done+blocked card is not listed as blocked' );
    like( $rv->{stdout}, qr/### Recently Completed.*Done blocked/s,
        'the done card is still present on the board (recently completed)' );
};

subtest 'karr context --json and --compact agree: one active blocker' => sub {
    my $repo = _setup_repo();
    my $json = run_karr( $repo, 'context', '--json' );
    is( $json->{exit}, 0, 'karr context --json exits 0' ) or diag $json->{stderr};
    like( $json->{stdout}, qr/"blocked":1\b/, 'json summary blocked is 1' );
    # Canonical JSON sorts keys, so a blocked-section item reads note before
    # title: this fails iff the done card is carried as a blocker.
    unlike( $json->{stdout}, qr/"note":"blocked[^}]*Done blocked/,
        'the done card is not carried in the blocked section' );

    my $compact = run_karr( $repo, 'context', '--compact' );
    is( $compact->{exit}, 0, 'karr context --compact exits 0' ) or diag $compact->{stderr};
    like( $compact->{stdout}, qr/^blocked=1$/m, 'compact blocked count is 1' );
};

done_testing;
