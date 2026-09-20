use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );

# Ticket k291: --local-only makes a mutating command write to the board's local
# refs/karr/* and skip both the fetch (sync_before) and the push (sync_after),
# so it cannot block in the caller's timeout on an unreachable or silent
# CONFIGURED remote. The flag is declared once in App::karr::Role::SyncLifecycle
# and honoured in sync_before/sync_after, so every writing command that composes
# the role carries it; move/edit/handoff/create are the ones this covers here.
#
# A board with no remote already syncs as a clean no-op (App::karr::Git::pull and
# ::push both return early on has_remote), so the exposure this addresses is the
# reachable-but-slow or unreachable configured remote -- reproduced below with a
# remote path that cannot be reached.

sub _run_karr { return run_karr(@_) }

sub _git_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die "git init failed";
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    return $repo;
}

sub _board_repo {
    my ($name) = @_;
    my $repo = _git_repo();
    is( _run_karr( $repo, 'init', '--name', $name )->{exit},
        0, "setup: karr init exits 0 ($name)" );
    return $repo;
}

sub _bare_remote {
    my $remote = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', '--bare', $remote ) == 0
        or die "git init --bare failed";
    return $remote;
}

# OID a (local-path) remote advertises for one ref, '' when it has none.
sub _remote_oid {
    my ( $remote, $ref ) = @_;
    my $out = qx{git ls-remote "$remote" "$ref" 2>/dev/null};
    return $out =~ /^(\S+)/ ? $1 : '';
}

# The id `karr create` just handed out.
sub _created_id {
    my ($r) = @_;
    return $r->{stdout} =~ /Created task (\d+)/ ? $1 : undef;
}

subtest 'unreachable remote: default touches it, --local-only skips it' => sub {
    my $repo = _board_repo('Offline Board');

    # A configured remote that cannot possibly be reached -- a local path with
    # no repository behind it, so the fetch/push fails deterministically and
    # fast rather than actually hanging a network read.
    system( 'git', '-C', $repo, 'remote', 'add',
        'origin', '/nonexistent/karr-k291-bogus.git' );

    # create --local-only writes locally without a round trip, so it succeeds
    # even though the remote is unreachable.
    my $c = _run_karr( $repo, 'create', 'Task one', '--local-only' );
    is( $c->{exit}, 0, 'create --local-only succeeds against an unreachable remote' );
    my $id = _created_id($c);
    ok( defined $id, "create --local-only produced a task id ($id)" );

    # Control: the default path DOES reach the remote -- a plain move against the
    # unreachable remote fails in sync_before, which is exactly the round trip
    # --local-only removes. Without this, the test below could pass even if the
    # flag did nothing.
    my $default = _run_karr( $repo, 'move', $id, 'in-progress', '--claim', 'tester' );
    isnt( $default->{exit}, 0,
        'default move DOES try the remote and fails on the unreachable one' );
    like( $default->{stderr}, qr/fail/i, 'the transport failure is surfaced' );

    # The task must not have moved: the failed sync_before ran before any write.
    like( _run_karr( $repo, 'show', $id )->{stdout}, qr/Status:\s+backlog/,
        'the failed default move left the card at its original status' );

    # Core regression: --local-only move succeeds offline AND the write lands.
    my $mv = _run_karr( $repo, 'move', $id, 'in-progress',
        '--claim', 'tester', '--local-only' );
    is( $mv->{exit}, 0, 'move --local-only succeeds against an unreachable remote' );
    like( _run_karr( $repo, 'show', $id )->{stdout}, qr/Status:\s+in-progress/,
        'move --local-only actually wrote the new status to the local refs' );

    # edit and handoff carry the same role-level flag. edit needs the owning
    # claim to touch a claimed card (a board rule, not a sync one).
    my $ed = _run_karr( $repo, 'edit', $id, '-a', 'a local note',
        '--claim', 'tester', '--local-only' );
    is( $ed->{exit}, 0, 'edit --local-only succeeds against an unreachable remote' );

    my $ho = _run_karr( $repo, 'handoff', $id, '--claim', 'tester', '--local-only' );
    is( $ho->{exit}, 0, 'handoff --local-only succeeds against an unreachable remote' );
    like( _run_karr( $repo, 'show', $id )->{stdout}, qr/Status:\s+review/,
        'handoff --local-only wrote the review status locally' );
};

subtest 'reachable remote: default pushes, --local-only does not, sync publishes' => sub {
    my $repo   = _board_repo('Reachable Board');
    my $remote = _bare_remote();
    system( 'git', '-C', $repo, 'remote', 'add', 'origin', $remote );

    # Two cards, both published to the remote by the default (pushing) create.
    my $a = _created_id( _run_karr( $repo, 'create', 'Card A' ) );
    my $b = _created_id( _run_karr( $repo, 'create', 'Card B' ) );
    ok( defined $a && defined $b, "created two published cards ($a, $b)" );

    my $ref_a = "refs/karr/tasks/$a/data";
    my $ref_b = "refs/karr/tasks/$b/data";
    my $a_before = _remote_oid( $remote, $ref_a );
    my $b_before = _remote_oid( $remote, $ref_b );
    ok( length $a_before && length $b_before,
        'both cards were pushed to the remote by the default create' );

    # Default move updates the remote immediately -- default behaviour preserved.
    is( _run_karr( $repo, 'move', $a, 'in-progress', '--claim', 'tester' )->{exit},
        0, 'default move succeeds' );
    isnt( _remote_oid( $remote, $ref_a ), $a_before,
        'default move published the change to the remote right away' );

    # --local-only move writes locally but leaves the remote untouched. The
    # in-process runner flushes armed SyncGuards after every dispatch, so an
    # unchanged remote here also proves no push fired at teardown.
    is( _run_karr( $repo, 'move', $b, 'in-progress', '--claim', 'tester', '--local-only' )->{exit},
        0, 'move --local-only succeeds' );
    like( _run_karr( $repo, 'show', $b )->{stdout}, qr/Status:\s+in-progress/,
        'move --local-only wrote the new status to the local board' );
    is( _remote_oid( $remote, $ref_b ), $b_before,
        'move --local-only did NOT push -- the remote ref is unchanged' );

    # The deferred change is real local board state: a later plain sync ships it.
    is( _run_karr( $repo, 'sync' )->{exit}, 0, 'karr sync succeeds' );
    isnt( _remote_oid( $remote, $ref_b ), $b_before,
        'a later karr sync publishes the --local-only change' );
};

subtest 'no remote: --local-only is a harmless no-op that still succeeds' => sub {
    my $repo = _board_repo('No Remote Board');

    my $id = _created_id( _run_karr( $repo, 'create', 'Solo card' ) );
    ok( defined $id, "created a card with no remote configured ($id)" );

    # With no remote, both paths already avoid the network; --local-only simply
    # changes nothing here and must still succeed.
    is( _run_karr( $repo, 'move', $id, 'in-progress', '--claim', 'tester', '--local-only' )->{exit},
        0, 'move --local-only succeeds on a board with no remote' );
    like( _run_karr( $repo, 'show', $id )->{stdout}, qr/Status:\s+in-progress/,
        'the local write landed' );
};

done_testing;
