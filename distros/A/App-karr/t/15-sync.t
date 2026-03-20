# t/15-sync.t - Test sync helpers in Role::BoardAccess
use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path tempdir );
use YAML::XS qw( DumpFile LoadFile );

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

    # Verify config ref
    my $config_ref = $git->read_ref('refs/karr/config');
    ok($config_ref, 'config ref exists after serialize');

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
};

subtest 'materialize preserves local-only tasks' => sub {
    my $tmpdir = _init_repo();
    my ($board_dir, $tasks_dir) = _setup_board($tmpdir);

    my $board = TestBoard->new(dir => $board_dir->stringify);
    my $git = App::karr::Git->new(dir => $tmpdir->stringify);

    # Save only task 1 to refs
    my $t1 = App::karr::Task->from_file(($tasks_dir->children(qr/^001-/))[0]);
    $git->save_task_ref($t1);

    # Task 2 exists only locally — materialize should preserve it
    $board->_materialize_from_refs($git);

    my @ids = $git->list_task_refs;
    ok((grep { $_ == 2 } @ids), 'local-only task 2 was serialized to refs during materialize');

    my @files = sort $tasks_dir->children(qr/\.md$/);
    is(scalar @files, 2, 'both tasks present after materialize');
};

subtest 'config next_id merge takes max' => sub {
    my $tmpdir = _init_repo();
    my ($board_dir, $tasks_dir) = _setup_board($tmpdir);

    my $board = TestBoard->new(dir => $board_dir->stringify);
    my $git = App::karr::Git->new(dir => $tmpdir->stringify);

    # Write a remote config with lower next_id
    my $remote_config = YAML::XS::Dump({
        name    => 'Remote Board',
        next_id => 2,
        columns => [qw(backlog todo done)],
    });
    $git->write_ref('refs/karr/config', $remote_config);

    # Local config has next_id=3, remote has next_id=2
    $board->_materialize_from_refs($git);

    my $merged = LoadFile($board_dir->child('config.yml')->stringify);
    is($merged->{next_id}, 3, 'next_id takes max of local (3) vs remote (2)');

    # Now test the reverse: remote higher
    $remote_config = YAML::XS::Dump({
        name    => 'Remote Board',
        next_id => 10,
        columns => [qw(backlog todo done)],
    });
    $git->write_ref('refs/karr/config', $remote_config);

    # Need a fresh board object to avoid cached config
    my $board2 = TestBoard->new(dir => $board_dir->stringify);
    $board2->_materialize_from_refs($git);

    my $merged2 = LoadFile($board_dir->child('config.yml')->stringify);
    is($merged2->{next_id}, 10, 'next_id takes max of local (3) vs remote (10)');
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

done_testing;
