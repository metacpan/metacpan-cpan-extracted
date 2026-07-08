use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::Role::BoardAccess;

{
    package TestBoard;
    use Moo;
    use MooX::Options;
    with 'App::karr::Role::BoardAccess';
    # dir / has_dir now come from Role::BoardDiscovery's `option dir`, just as
    # every real command gets them by composing BoardAccess.
}

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is($rc, 0, "@cmd");
}

sub _init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
    return $repo;
}

subtest 'board access discovers a ref-backed board via store' => sub {
    my $repo = _init_repo();
    my $git = App::karr::Git->new( dir => $repo );
    $git->write_ref( 'refs/karr/config', Dump({ version => 1, board => { name => 'Ref Board' } }) );
    $git->write_ref( 'refs/karr/meta/next-id', "3\n" );

    my $board = TestBoard->new( dir => $repo );

    # Store access works
    ok( $board->store->board_exists, 'board exists via store' );
    ok( $board->git_root->is_dir, 'git_root resolves to repo' );

    # No persistent karr directory in repo root
    ok( !$board->git_root->child('karr')->exists, 'no persistent karr directory' );
    ok( !$board->git_root->child('tasks')->exists, 'no tasks directory at repo root' );

    # Config accessible via role
    my $config = $board->config;
    ok( $config->data->{board}{name} eq 'Ref Board', 'config via role' );

    # Store provides effective_config with defaults merged
    my $ec = $board->store->effective_config;
    ok( exists $ec->{statuses}, 'effective_config has statuses' );
    ok( exists $ec->{priorities}, 'effective_config has priorities' );
};

subtest 'board access fails outside git repositories' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $ok = eval { TestBoard->new( dir => $dir )->git_root; 1 };
    ok( !$ok, 'board access dies outside git repos' );
    like( $@, qr/git repository/i, 'error mentions git repository requirement' );
};

subtest 'load_tasks and find_task via store' => sub {
    my $repo = _init_repo();
    my $git = App::karr::Git->new( dir => $repo );

    # Write a task directly to refs
    $git->write_ref( 'refs/karr/config', Dump({ version => 1 }) );
    $git->write_ref( 'refs/karr/meta/next-id', "1\n" );
    my $task_yaml = Dump({
        id => 1,
        title => 'Test task',
        status => 'backlog',
        priority => 'high',
        class => 'standard',
        created => '2026-05-15T10:00:00Z',
        updated => '2026-05-15T10:00:00Z',
    });
    $git->write_ref( 'refs/karr/tasks/1/data', "---\n$task_yaml\n---\n\nTest body" );

    my $board = TestBoard->new( dir => $repo );

    my @tasks = $board->load_tasks;
    is( scalar @tasks, 1, 'load_tasks returns one task' );
    is( $tasks[0]->id, 1, 'task id is correct' );
    is( $tasks[0]->title, 'Test task', 'task title is correct' );

    my $found = $board->find_task(1);
    ok( $found, 'find_task finds task' );
    is( $found->status, 'backlog', 'task status correct' );

    my $missing = $board->find_task(999);
    ok( !$missing, 'find_task returns undef for missing id' );
};

subtest 'sync_before and sync_after exist on role' => sub {
    my $repo = _init_repo();
    my $git = App::karr::Git->new( dir => $repo );
    $git->write_ref( 'refs/karr/config', Dump({ version => 1 }) );

    my $board = TestBoard->new( dir => $repo );

    ok( $board->can('sync_before'), 'sync_before method exists' );
    ok( $board->can('sync_after'), 'sync_after method exists' );
};

done_testing;