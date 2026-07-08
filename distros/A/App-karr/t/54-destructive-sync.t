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
use YAML::XS qw( Load );

use App::karr::Git;

# Ticket #23: Backup/Restore/Destroy now run through Role::SyncLifecycle
# (sync_before / sync_after) instead of hand-rolled $git->pull / $git->push.
# These tests pin the *behaviour* the switch must preserve -- which refs end up
# where -- not the sync progress text (that wording is changing under #27).
#
#  * Restore rewrites refs/karr/* and its sync_after must mirror the rewrite to
#    the remote, pruning refs that are absent from the snapshot.
#  * Backup is read-only: it takes the retrying pull, but its guard is marked
#    done so the read path never pushes local-only state to the remote.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is($rc, 0, "@cmd");
}

sub _run_karr {
    my ( $cwd, $stdin, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3(
        my $stdin_fh,
        my $stdout_fh,
        $stderr,
        $^X,
        "-I$ROOT/lib",
        $BIN,
        @argv,
    );

    if ( defined $stdin ) {
        print {$stdin_fh} $stdin;
    }
    close $stdin_fh;

    my $stdout = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";
    return {
        exit   => $exit,
        stdout => defined $stdout ? $stdout : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
    return $repo;
}

sub _init_remote_pair {
    my $remote = tempdir( CLEANUP => 1 );
    my $local  = _init_repo();

    _git_ok( 'git', 'init', '--bare', '-q', $remote );
    _git_ok( 'git', '-C', $local, 'remote', 'add', 'origin', $remote );

    return ($local, $remote);
}

subtest 'restore mirrors the rewrite to the remote and prunes stale refs' => sub {
    my ( $repo, $remote ) = _init_remote_pair();
    is( _run_karr( $repo, undef, 'init', '--name', 'Restore Board' )->{exit}, 0, 'board initialized' );
    is( _run_karr( $repo, undef, 'create', 'First task' )->{exit}, 0, 'first task created' );
    is( _run_karr( $repo, undef, 'sync' )->{exit}, 0, 'first task synced to remote' );

    my $backup = _run_karr( $repo, undef, 'backup' );
    is( $backup->{exit}, 0, 'backup succeeds' );

    # Second task lands on the remote too, but is NOT in the snapshot.
    is( _run_karr( $repo, undef, 'create', 'Second task' )->{exit}, 0, 'second task created' );
    is( _run_karr( $repo, undef, 'sync' )->{exit}, 0, 'second task synced to remote' );

    my $remote_git = App::karr::Git->new( dir => $remote );
    is_deeply( [ $remote_git->list_task_refs ], [ 1, 2 ], 'remote holds both tasks before restore' );

    my $restore = _run_karr( $repo, $backup->{stdout}, 'restore', '--yes' );
    is( $restore->{exit}, 0, 'restore with --yes succeeds' );

    my $local_git = App::karr::Git->new( dir => $repo );
    is_deeply( [ $local_git->list_task_refs ], [1], 'local refs match the snapshot' );

    # sync_after must have pushed the rewrite with prune, so the remote loses
    # task 2 (present on the remote, absent from the snapshot).
    is_deeply( [ $remote_git->list_task_refs ], [1], 'remote rewrite mirrored: stale task pruned' );
};

subtest 'backup is read-only and never pushes local-only state' => sub {
    my ( $repo, $remote ) = _init_remote_pair();
    is( _run_karr( $repo, undef, 'init', '--name', 'Backup Board' )->{exit}, 0, 'board initialized' );
    is( _run_karr( $repo, undef, 'create', 'First task' )->{exit}, 0, 'task created' );
    is( _run_karr( $repo, undef, 'sync' )->{exit}, 0, 'task synced to remote' );

    # A local-only ref the remote has never seen. If backup ever pushed, this
    # would be mirrored to the remote.
    my $local_git = App::karr::Git->new( dir => $repo );
    $local_git->write_ref( 'refs/karr/log/backup-probe', qq({"probe":1}) );

    my $backup = _run_karr( $repo, undef, 'backup' );
    is( $backup->{exit}, 0, 'backup exits successfully against a repo with a remote' );

    my $snapshot = Load( $backup->{stdout} );
    is( $snapshot->{version}, 1, 'snapshot still produced' );

    my $remote_git = App::karr::Git->new( dir => $remote );
    ok( !$remote_git->ref_exists('refs/karr/log/backup-probe'),
        'read-only backup did not push the local-only ref to the remote' );
    is_deeply( [ $remote_git->list_task_refs ], [1], 'remote task refs left untouched by backup' );
};

done_testing;
