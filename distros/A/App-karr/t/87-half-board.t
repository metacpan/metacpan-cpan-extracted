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

use App::karr::Git;
use App::karr::BoardStore;

# Ticket #62: a write command in a repository without a board did not refuse.
# It wrote refs/karr/meta/next-id and the task ref but never refs/karr/config,
# and board_exists accepted next-id on its own -- so `karr create` typed in the
# wrong directory left a half-board behind that `karr init` then refused to
# touch for good. The board name, the statuses and the .gitignore entries could
# never be written, and `karr destroy --yes` was the only way out.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is( $rc, 0, "@cmd" );
}

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3( undef, my $stdout_fh, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );
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

sub _karr_refs {
    my ($repo) = @_;
    open my $fh, '-|', 'git', '-C', $repo, 'for-each-ref', '--format=%(refname)', 'refs/karr/'
        or die "cannot list refs: $!";
    my @refs = <$fh>;
    close $fh;
    chomp @refs;
    return sort @refs;
}

# The board's own refs, without the activity log. Every write leaves an entry
# under refs/karr/log/<role>/<identity> (#64), which says nothing about whether
# the board is whole -- and the identity in that name depends on the git
# user.email of whoever runs the suite. The half-board assertion below is about
# structure: tasks and a counter present, config absent. The two assertions
# that a repository holds *nothing* stay on _karr_refs, because there a stray
# log ref would be a real finding.
sub _board_refs {
    my ($repo) = @_;
    return grep { !m{^refs/karr/log/} } _karr_refs($repo);
}

sub _bare_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    return $repo;
}

# A board in exactly the shape a pre-fix `karr create` left behind in an
# unrelated repository: tasks and a counter, no config.
sub _half_board {
    my $repo = _bare_repo();
    is( _run_karr( $repo, 'init', '--name', 'Scratch' )->{exit}, 0, 'setup: board built' );
    is( _run_karr( $repo, 'create', "seeded $_" )->{exit}, 0, "setup: task $_" ) for 1 .. 2;
    _git_ok( 'git', '-C', $repo, 'update-ref', '-d', 'refs/karr/config' );
    _git_ok( 'git', '-C', $repo, 'update-ref', '-d', 'refs/karr/meta/encoding' );
    return $repo;
}

subtest 'write commands refuse in a repository with no board' => sub {
    my $repo = _bare_repo();

    for my $argv (
        [ 'create', 'oops wrong dir' ],
        [ 'move',   '1', 'done' ],
        [ 'edit',   '1', '--append-body', 'note' ],
        [ 'delete', '1', '--yes' ],
        [ 'archive', '1' ],
        [ 'handoff', '1', '--claim', 'someone' ],
        [ 'pick',   '--claim', 'someone' ],
        [ 'config', 'set', 'board.name', 'Hijacked' ],
        ['disable'],
        ['enable'],
      )
    {
        my $rv = _run_karr( $repo, @$argv );
        is( $rv->{exit}, 1, "karr $argv->[0] exits 1 without a board" );
        like( $rv->{stderr}, qr/No karr board found/, "karr $argv->[0] says the board is missing" );
    }

    is_deeply( [ _karr_refs($repo) ], [],
        'and not one of them left a ref behind in an unrelated repository' );
};

subtest 'a half-board is named as one, not reported as no board at all' => sub {
    # Ticket #133: both states raised the same sentence, so a repository whose
    # only missing ref was refs/karr/config told every write command's user
    # "No karr board found. Run 'karr init'". An agent read that on a repository
    # holding 21 tickets, believed the tickets did not exist, and ran init --
    # which back then also broke how the tickets were read (#132).
    my $repo = _half_board();

    my $rv = _run_karr( $repo, 'create', 'anything' );
    is( $rv->{exit}, 1, 'a write command still refuses on a half-board' );
    like( $rv->{stderr}, qr/Half-initialized karr board/,
        'but it names the state it actually found' );
    like( $rv->{stderr}, qr/refs\/karr\/config is missing/,
        'and says which ref is missing' );
    like( $rv->{stderr}, qr/2 task refs/,
        'and how many task refs are at stake, so nobody writes them off' );
    like( $rv->{stderr}, qr/karr init/, 'it still points at karr init' );
    like( $rv->{stderr}, qr/keeps what is already there/,
        'and promises init does not discard them' );
    unlike( $rv->{stderr}, qr/No karr board found/,
        'and never claims the repository has no board' );
    # karr repair only migrates double-encoded UTF-8, and on a repository with
    # no refs at all it dies with the very sentence this branch replaces.
    unlike( $rv->{stderr}, qr/karr repair/, 'nor does it send anyone to karr repair' );

    is_deeply( [ _board_refs($repo) ],
        [ 'refs/karr/meta/board-id', 'refs/karr/meta/next-id',
          'refs/karr/tasks/1/data', 'refs/karr/tasks/2/data' ],
        'the refused command left the half-board exactly as it was' );
};

subtest 'init completes a half-board instead of refusing forever' => sub {
    my $repo = _half_board();

    is_deeply( [ _board_refs($repo) ],
        [ 'refs/karr/meta/board-id', 'refs/karr/meta/next-id',
          'refs/karr/tasks/1/data', 'refs/karr/tasks/2/data' ],
        'setup: the half-board has tasks, a counter and an identity but no config' );

    my $git   = App::karr::Git->new( dir => $repo );
    my $store = App::karr::BoardStore->new( git => $git );
    ok( !$store->board_exists, 'a board without refs/karr/config does not count as existing' );
    ok( $store->has_board_refs, 'but karr can still see that something is there' );

    my $rv = _run_karr( $repo, 'init', '--name', 'My Real Board' );
    is( $rv->{exit}, 0, 'init succeeds on a half-board' ) or diag $rv->{stderr};

    is( _run_karr( $repo, 'config', 'get', 'board.name' )->{stdout},
        "My Real Board\n", 'the board name can finally be set' );

    # The counter must survive: init used to write 1 unconditionally, so the
    # next create would have been handed an id that is already taken.
    my $created = _run_karr( $repo, 'create', 'brand new' );
    is( $created->{exit}, 0, 'create works on the completed board' );
    like( $created->{stdout}, qr/Created task 3:/, 'and gets a fresh id, not one of the seeded ones' );

    my $list = _run_karr( $repo, 'list' )->{stdout};
    like( $list, qr/seeded 1/, 'the task that was already there is intact' );
    like( $list, qr/seeded 2/, 'both of them, in fact' );
    like( $list, qr/brand new/, 'alongside the new one' );
};

subtest 'init still refuses a board that is actually there' => sub {
    my $repo = _bare_repo();
    is( _run_karr( $repo, 'init', '--name', 'First' )->{exit}, 0, 'first init succeeds' );

    my $rv = _run_karr( $repo, 'init', '--name', 'Second' );
    isnt( $rv->{exit}, 0, 'a second init is refused' );
    like( $rv->{stderr}, qr/Board already exists/, 'and says so' );
    is( _run_karr( $repo, 'config', 'get', 'board.name' )->{stdout},
        "First\n", 'the existing board name is not overwritten' );
};

subtest 'a fresh init writes the counter it always wrote' => sub {
    my $repo = _bare_repo();
    is( _run_karr( $repo, 'init', '--name', 'Fresh' )->{exit}, 0, 'init succeeds' );

    my $git = App::karr::Git->new( dir => $repo );
    ok( $git->ref_exists('refs/karr/meta/next-id'), 'the next-id ref exists' );
    is( $git->read_next_id_ref, 1, 'and starts at 1' );
};

subtest 'import bootstraps a board that is complete, not a half one' => sub {
    # Import is allowed to run without a board -- it is one of the two ways to
    # create one -- so it has to leave behind a board the writing commands will
    # then accept. A kanban-md tasks/ view with no config.yml used to produce
    # tasks and a counter and nothing else.
    my $repo  = _bare_repo();
    my $tasks = "$repo/tasks";
    mkdir $tasks or die "mkdir $tasks: $!";
    open my $fh, '>', "$tasks/1-imported.md" or die $!;
    print {$fh} <<'MD';
---
id: 1
title: Imported task
status: backlog
priority: medium
class: standard
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
---

Imported body.
MD
    close $fh;

    is( _run_karr( $repo, 'import', '--yes' )->{exit}, 0, 'import succeeds' );

    my $git = App::karr::Git->new( dir => $repo );
    ok( $git->ref_exists('refs/karr/config'),
        'import wrote a config ref, so the board counts as initialized' );

    my $created = _run_karr( $repo, 'create', 'after import' );
    is( $created->{exit}, 0, 'and a write command works straight afterwards' )
        or diag $created->{stderr};
    like( $created->{stdout}, qr/Created task 2:/, 'with an id past the imported one' );
};

subtest 'the cleanup commands still work on a half-board' => sub {
    # Without this, tightening board_exists would strand every half-board an
    # older karr already wrote: no way to back it up, no way to remove it.
    my $repo = _half_board();
    my $out  = "$repo/snapshot.yml";

    is( _run_karr( $repo, 'backup', '--output', $out )->{exit}, 0, 'backup works' );
    ok( -s $out, 'and wrote something' );
    is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'materialize works' );

    is( _run_karr( $repo, 'destroy', '--yes' )->{exit}, 0, 'destroy works' );
    is_deeply( [ _karr_refs($repo) ], [], 'and removed the half-board' );
};

subtest 'the cleanup commands still refuse an empty repository' => sub {
    my $repo = _bare_repo();
    for my $cmd (qw( backup materialize )) {
        my $rv = _run_karr( $repo, $cmd );
        isnt( $rv->{exit}, 0, "karr $cmd refuses with nothing under refs/karr/" );
        like( $rv->{stderr}, qr/No karr board found/, "karr $cmd says why" );
    }
    my $rv = _run_karr( $repo, 'destroy', '--yes' );
    isnt( $rv->{exit}, 0, 'karr destroy refuses with nothing under refs/karr/' );
    like( $rv->{stderr}, qr/No karr board found/, 'karr destroy says why' );
};

done_testing;
