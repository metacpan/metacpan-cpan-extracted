# t/15-sync.t - Test sync helpers in Role::BoardAccess
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use Path::Tiny qw( path tempdir );
use YAML::XS qw( DumpFile LoadFile Load );

use_ok('App::karr::Git');
use_ok('App::karr::Task');
use_ok('App::karr::Role::BoardAccess');

# Build a tiny class that consumes BoardAccess with a fixed board_dir
{
    package TestBoard;
    use Moo;
    with 'App::karr::Role::BoardAccess';
    has dir => (is => 'ro', required => 1);
    has has_dir => (is => 'ro', default => sub { 1 });
    sub _build_board_dir { path($_[0]->dir) }
}

sub _init_repo {
    my $tmpdir = tempdir(CLEANUP => 1);
    system('git', 'init', '-q', $tmpdir->stringify);
    system('git', '-C', $tmpdir->stringify, 'config', 'user.email', 'test@test.com');
    system('git', '-C', $tmpdir->stringify, 'config', 'user.name', 'Test User');
    return $tmpdir;
}

sub _init_remote_pair {
    my $remote = tempdir(CLEANUP => 1);
    my $local  = tempdir(CLEANUP => 1);

    system('git', 'init', '--bare', '-q', $remote->stringify);
    system('git', 'init', '-q', $local->stringify);
    system('git', '-C', $local->stringify, 'config', 'user.email', 'test@test.com');
    system('git', '-C', $local->stringify, 'config', 'user.name', 'Test User');
    system('git', '-C', $local->stringify, 'remote', 'add', 'origin', $remote->stringify);

    return ($local, $remote);
}

sub _setup_board {
    my ($tmpdir) = @_;
    my $board_dir = $tmpdir->child('karr');
    $board_dir->mkpath;
    my $tasks_dir = $board_dir->child('tasks');
    $tasks_dir->mkpath;

    DumpFile($board_dir->child('config.yml')->stringify, {
        name    => 'Test Board',
        next_id => 3,
        columns => [qw(backlog todo in-progress done)],
    });

    my $t1 = App::karr::Task->new(
        id => 1, title => 'First task', status => 'todo',
        priority => 'high', class => 'standard', body => 'Body one',
    );
    my $t2 = App::karr::Task->new(
        id => 2, title => 'Second task', status => 'backlog',
        priority => 'medium', class => 'standard', body => 'Body two',
    );
    $t1->save($tasks_dir);
    $t2->save($tasks_dir);

    return ($board_dir, $tasks_dir);
}

subtest 'serialize and materialize roundtrip' => sub {
    my $tmpdir = _init_repo();
    my ($board_dir, $tasks_dir) = _setup_board($tmpdir);

    my $board = TestBoard->new(dir => $board_dir->stringify);
    my $git = App::karr::Git->new(dir => $tmpdir->stringify);

    # Serialize local files to refs
    $board->_serialize_to_refs($git);

    # Verify refs exist
    my @ids = $git->list_task_refs;
    is_deeply(\@ids, [1, 2], 'list_task_refs returns both task IDs after serialize');

    my $config_ref = Load($git->read_ref('refs/karr/config'));
    ok($config_ref, 'config ref exists after serialize');
    ok(!exists $config_ref->{next_id}, 'config ref does not persist next_id');

    # Delete local files
    for my $file ($tasks_dir->children(qr/\.md$/)) {
        $file->remove;
    }
    my @remaining = $tasks_dir->children(qr/\.md$/);
    is(scalar @remaining, 0, 'all task files deleted');

    # Materialize from refs
    $board->_materialize_from_refs($git);

    # Verify files recreated
    my @recreated = sort $tasks_dir->children(qr/\.md$/);
    is(scalar @recreated, 2, 'two task files recreated');

    # Verify content
    my $loaded1 = App::karr::Task->from_file($recreated[0]);
    is($loaded1->id, 1, 'first task id correct');
    is($loaded1->title, 'First task', 'first task title correct');
    is($loaded1->body, 'Body one', 'first task body correct');

    my $loaded2 = App::karr::Task->from_file($recreated[1]);
    is($loaded2->id, 2, 'second task id correct');
    is($loaded2->title, 'Second task', 'second task title correct');
    is($git->read_next_id_ref, 1, 'next-id metadata defaults to 1 when not yet allocated');
};

subtest 'serialize removes deleted task refs' => sub {
    my $tmpdir = _init_repo();
    my ($board_dir, $tasks_dir) = _setup_board($tmpdir);

    my $board = TestBoard->new(dir => $board_dir->stringify);
    my $git = App::karr::Git->new(dir => $tmpdir->stringify);

    $board->_serialize_to_refs($git);
    is_deeply([$git->list_task_refs], [1, 2], 'both refs exist before deletion');

    my ($task2) = $tasks_dir->children(qr/^002-/);
    $task2->remove;

    $board->_serialize_to_refs($git);
    is_deeply([$git->list_task_refs], [1], 'deleted local task is removed from refs on serialize');
};

subtest 'append_log writes NDJSON' => sub {
    my $tmpdir = _init_repo();
    my ($board_dir) = _setup_board($tmpdir);

    my $board = TestBoard->new(dir => $board_dir->stringify);
    my $git = App::karr::Git->new(dir => $tmpdir->stringify);

    $board->append_log($git, action => 'create', task_id => 1, ts => '2026-01-01T00:00:00Z');
    $board->append_log($git, action => 'move', task_id => 1, ts => '2026-01-02T00:00:00Z');

    my $log_content = $git->read_ref('refs/karr/log/test_test.com');
    ok($log_content, 'log ref exists');

    require JSON::MaybeXS;
    my @lines = split /\n/, $log_content;
    is(scalar @lines, 2, 'two log lines');

    my $first = JSON::MaybeXS::decode_json($lines[0]);
    is($first->{action}, 'create', 'first log entry action');
    is($first->{task_id}, 1, 'first log entry task_id');

    my $second = JSON::MaybeXS::decode_json($lines[1]);
    is($second->{action}, 'move', 'second log entry action');
};

subtest 'push prunes deleted refs on the remote' => sub {
    my ($local, $remote) = _init_remote_pair();
    my ($board_dir, $tasks_dir) = _setup_board($local);

    my $board = TestBoard->new(dir => $board_dir->stringify);
    my $git = App::karr::Git->new(dir => $local->stringify);

    $board->_serialize_to_refs($git);
    ok( $git->push, 'initial push succeeds' );

    my ($task2) = $tasks_dir->children(qr/^002-/);
    $task2->remove;
    $board->_serialize_to_refs($git);
    ok( $git->push, 'pruning push succeeds after deleting a task ref' );

    my $remote_git = App::karr::Git->new(dir => $remote->stringify);
    is_deeply(
        [ $remote_git->list_task_refs ],
        [1],
        'remote task refs are pruned to match the local namespace'
    );
};

done_testing;
