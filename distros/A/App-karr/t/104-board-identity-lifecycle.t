use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Cwd qw( abs_path );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

use App::karr::Git;
use App::karr::BoardStore;

# Ticket #95, the lifecycle half: where the board identity comes from and how
# it survives the board's own destructive round trips.
#
#   * karr init stamps a new board -- and completing a half-board never
#     re-keys one, or every other clone would read it as foreign
#   * karr import, the other board-birth path (#30), stamps too
#   * karr restore of a snapshot onto the same board must not look like a
#     foreign board: a snapshot that carries the id restores it, and one from
#     before identities existed keeps the board's standing id rather than
#     stripping it
#   * end to end through the CLI: a swapped remote stops a writing command,
#     and karr sync --accept-foreign-board / karr sync --push are the two
#     deliberate ways through

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is( $rc, 0, "@cmd" );
}

sub _repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    return $repo;
}

sub _run_karr {
    my ( $dir, @argv ) = @_;
    my $err = gensym;
    my $pid = open3( my $in, my $out, $err,
        $^X, "-I$ROOT/lib", $BIN, '--dir', $dir, @argv );
    close $in;
    my $stdout = do { local $/; <$out> };
    my $stderr = do { local $/; <$err> };
    waitpid $pid, 0;
    return {
        exit   => $? >> 8,
        stdout => defined $stdout ? $stdout : '',
        stderr => defined $stderr ? $stderr : '',
    };
}

sub board_id_of {
    my ($git) = @_;
    my $raw = $git->read_ref('refs/karr/meta/board-id') // '';
    $raw =~ s/\s+//g;
    return length $raw ? $raw : undef;
}

subtest 'init stamps a new board, and completing a half-board keeps the stamp' => sub {
    my $repo = _repo();
    is( _run_karr( $repo, 'init', '--name', 'Stamped' )->{exit}, 0, 'init succeeds' );

    my $git = App::karr::Git->new( dir => $repo );
    my $id  = board_id_of($git);
    ok defined $id, 'the board carries an identity';
    like $id, qr/\A[0-9a-f]{32}\z/, 'and it looks like an id';

    # init refuses a board that exists, so the re-init path that must not
    # re-key a board is the half-board completion (#62): tasks and a counter
    # -- and now an identity -- but no config.
    _git_ok( 'git', '-C', $repo, 'update-ref', '-d', 'refs/karr/config' );
    is( _run_karr( $repo, 'init', '--name', 'Completed' )->{exit}, 0,
        'init completes the half-board' );
    is board_id_of($git), $id, 'the identity survived the re-init';
};

subtest 'import, the other board-birth path, stamps too' => sub {
    my $repo  = _repo();
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
    like board_id_of( App::karr::Git->new( dir => $repo ) ),
        qr/\A[0-9a-f]{32}\z/, 'an imported board is born with an identity';
};

# ---------------------------------------------------------------------
# End to end through the CLI: the swapped remote from #95, the refusal a
# writing command runs into, and the two documented ways through.
# ---------------------------------------------------------------------
sub _clone_pair {
    my $work = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    for my $name (qw( a b )) {
        system("git clone -q '$work/origin.git' '$work/$name' 2>/dev/null");
        _git_ok( 'git', '-C', "$work/$name", 'config', 'user.email',
            "$name\@karr.test" );
        _git_ok( 'git', '-C', "$work/$name", 'config', 'user.name', "agent-$name" );
    }
    return $work;
}

sub _swap_in_foreign_board {
    my ($work) = @_;
    system("rm -rf '$work/origin.git'");
    _git_ok( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    system("git clone -q '$work/origin.git' '$work/foreign' 2>/dev/null");
    _git_ok( 'git', '-C', "$work/foreign", 'config', 'user.email',
        'f@karr.test' );
    _git_ok( 'git', '-C', "$work/foreign", 'config', 'user.name', 'agent-f' );
    is( _run_karr( "$work/foreign", 'init', '--name', 'Foreign' )->{exit}, 0,
        'setup: a different board is initialised at the same URL' );
    is( _run_karr( "$work/foreign", 'create', 'Foreign task' )->{exit}, 0,
        'setup: and has its own work' );
    return;
}

subtest 'end to end: a swapped remote is refused, and the ways through work' => sub {
    my $work = _clone_pair();

    is( _run_karr( "$work/a", 'init', '--name', 'Original' )->{exit}, 0,
        'A creates the board' );
    is( _run_karr( "$work/a", 'create', 'Original task' )->{exit}, 0,
        'A creates a task' );
    is( _run_karr( "$work/b", 'sync', '--pull' )->{exit}, 0, 'B syncs it in' );
    like( _run_karr( "$work/b", 'list', '--compact' )->{stdout},
        qr/Original task/, 'B has the board' );

    my $id_before = board_id_of( App::karr::Git->new( dir => "$work/b" ) );
    ok defined $id_before, 'B carries the board identity';

    _swap_in_foreign_board($work);

    my $blocked = _run_karr( "$work/b", 'create', 'Another task' );
    isnt( $blocked->{exit}, 0,
        'a writing command on B fails instead of converging onto the foreign board' );
    like( $blocked->{stderr}, qr/refusing to sync/, 'and says it refused' );
    like( $blocked->{stderr}, qr/different board/, 'and what the remote became' );
    like( $blocked->{stderr}, qr/accept-foreign-board/,
        'and how to adopt the foreign board if that is really wanted' );
    like( _run_karr( "$work/b", 'list', '--compact' )->{stdout},
        qr/Original task/, 'B still has its own board while the question is open' );

    # Way through number one: the remote is the truth now, adopt it.
    my $adopted = _run_karr( "$work/b", 'sync', '--accept-foreign-board' );
    is( $adopted->{exit}, 0, 'karr sync --accept-foreign-board succeeds' )
        or diag $adopted->{stderr};
    like( _run_karr( "$work/b", 'list', '--compact' )->{stdout},
        qr/Foreign task/, 'B now carries the foreign board' );
    unlike( _run_karr( "$work/b", 'list', '--compact' )->{stdout},
        qr/Original task/, 'and the old board is gone' );
    is( _run_karr( "$work/b", 'create', 'After the takeover' )->{exit}, 0,
        'and writing commands work again' );
};

subtest 'end to end: sync --push republishes this board over the wrong remote' => sub {
    my $work = _clone_pair();

    is( _run_karr( "$work/a", 'init', '--name', 'Mine' )->{exit}, 0, 'board created' );
    is( _run_karr( "$work/a", 'create', 'Precious task' )->{exit}, 0, 'and published' );

    _swap_in_foreign_board($work);

    my $blocked = _run_karr( "$work/a", 'create', 'Second task' );
    isnt( $blocked->{exit}, 0, 'the swap stops the next writing command' );
    like( $blocked->{stderr}, qr/refusing to sync/, 'with the refusal' );

    is( _run_karr( "$work/a", 'sync', '--push' )->{exit}, 0,
        'sync --push republishes this board over the foreign one' );
    is( _run_karr( "$work/a", 'create', 'Third task' )->{exit}, 0,
        'and ordinary commands resume once the remote agrees again' );
    like( _run_karr( "$work/a", 'list', '--compact' )->{stdout},
        qr/Precious task/, 'the board itself was never touched' );
};

subtest 'restore keeps the standing identity when the snapshot predates it' => sub {
    my $repo = _repo();
    my $git  = App::karr::Git->new( dir => $repo );
    my $store = App::karr::BoardStore->new( git => $git );

    $store->save_config( App::karr::Config->default_config );
    $store->ensure_board_id;
    my $standing = $store->board_id;
    ok defined $standing, 'setup: the board has an identity';

    # A backup taken before identities existed carries no board-id. Installing
    # it verbatim would strip the identity, and the push that follows would
    # prune it off the remote too -- the board would disarm itself.
    my $snapshot = $store->snapshot;
    delete $snapshot->{refs}{'refs/karr/meta/board-id'};

    ok $store->restore_snapshot($snapshot), 'the restore runs';
    is $store->board_id, $standing,
        'and the identity the board already had is still its identity';
};

subtest 'restore installs the identity a snapshot carries' => sub {
    my $repo = _repo();
    my $git  = App::karr::Git->new( dir => $repo );
    my $store = App::karr::BoardStore->new( git => $git );

    $store->save_config( App::karr::Config->default_config );
    $store->ensure_board_id;
    my $snapshot = $store->snapshot;
    my $own = $store->board_id;

    # Same board: the id travels with the snapshot and comes back unchanged.
    ok $store->restore_snapshot($snapshot), 'same-board restore runs';
    is $store->board_id, $own, 'identity unchanged by its own snapshot';

    # A foreign snapshot is a deliberate takeover: its id is installed as is.
    $snapshot->{refs}{'refs/karr/meta/board-id'} = 'f' x 32 . "\n";
    ok $store->restore_snapshot($snapshot), 'foreign restore runs';
    is $store->board_id, 'f' x 32, 'a foreign snapshot re-keys the board on purpose';
};

done_testing;
