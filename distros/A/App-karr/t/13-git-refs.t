# t/13-git-refs.t - Test Git.pm ref operations (commit-wrapped refs)
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use Path::Tiny qw( path tempdir );

use_ok('App::karr::Git');

subtest 'is_repo: true for git repo' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    system('git', 'init', '-q', $tmpdir->stringify);
    my $git = App::karr::Git->new( dir => $tmpdir->stringify );
    ok($git->is_repo, 'temp git repo detected as repo');
};

subtest 'is_repo: true for subdirectory of repo' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    system('git', 'init', '-q', $tmpdir->stringify);
    my $subdir = $tmpdir->child('sub', 'deep');
    $subdir->mkpath;
    my $git = App::karr::Git->new( dir => $subdir->stringify );
    ok($git->is_repo, 'subdirectory of git repo detected as repo');
};

subtest 'is_repo: false for non-repo' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $git = App::karr::Git->new( dir => $tmpdir->stringify );
    ok(!$git->is_repo, 'plain directory is not a repo');
};

subtest 'write_ref / read_ref roundtrip' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    system('git', 'init', '-q', $tmpdir->stringify);
    system('git', '-C', $tmpdir->stringify, 'config', 'user.email', 'test@test.com');
    system('git', '-C', $tmpdir->stringify, 'config', 'user.name', 'Test');

    my $git = App::karr::Git->new( dir => $tmpdir->stringify );

    my $content = "line one\nline two\nline three\n";
    my $ref = 'refs/karr/tasks/42/data';

    ok($git->write_ref($ref, $content), 'write_ref succeeds');

    my $read_back = $git->read_ref($ref);
    # cat-file output gets chomped by _git_cmd, so trailing newline is stripped
    is($read_back, "line one\nline two\nline three", 'read_ref returns written content (chomped)');
};

subtest 'ref points to commit object' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    system('git', 'init', '-q', $tmpdir->stringify);
    system('git', '-C', $tmpdir->stringify, 'config', 'user.email', 'test@test.com');
    system('git', '-C', $tmpdir->stringify, 'config', 'user.name', 'Test');

    my $git = App::karr::Git->new( dir => $tmpdir->stringify );

    $git->write_ref('refs/karr/test/obj', 'hello');

    # Verify the ref points to a commit, not a blob
    my $pid = open(my $fh, '-|');
    if (!$pid) {
        open(STDERR, '>', '/dev/null');
        chdir $tmpdir->stringify;
        exec('git', 'cat-file', '-t', 'refs/karr/test/obj');
    }
    my $type = do { local $/; <$fh> };
    close $fh;
    chomp $type;
    is($type, 'commit', 'ref points to a commit object');
};

subtest 'read_ref on nonexistent ref returns empty string' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    system('git', 'init', '-q', $tmpdir->stringify);

    my $git = App::karr::Git->new( dir => $tmpdir->stringify );
    my $result = $git->read_ref('refs/karr/does/not/exist');
    is($result, '', 'nonexistent ref returns empty string');
};

subtest 'delete_ref' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    system('git', 'init', '-q', $tmpdir->stringify);
    system('git', '-C', $tmpdir->stringify, 'config', 'user.email', 'test@test.com');
    system('git', '-C', $tmpdir->stringify, 'config', 'user.name', 'Test');

    my $git = App::karr::Git->new( dir => $tmpdir->stringify );

    my $ref = 'refs/karr/tasks/99/data';
    $git->write_ref($ref, 'to be deleted');
    my $before = $git->read_ref($ref);
    ok($before, 'ref exists before delete');

    $git->delete_ref($ref);
    my $after = $git->read_ref($ref);
    is($after, '', 'ref gone after delete');
};

subtest 'git_user_email and git_user_name' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    system('git', 'init', '-q', $tmpdir->stringify);
    system('git', '-C', $tmpdir->stringify, 'config', 'user.email', 'karr@example.com');
    system('git', '-C', $tmpdir->stringify, 'config', 'user.name', 'Karr Bot');

    my $git = App::karr::Git->new( dir => $tmpdir->stringify );
    is($git->git_user_email, 'karr@example.com', 'git_user_email reads config');
    is($git->git_user_name, 'Karr Bot', 'git_user_name reads config');
    is($git->git_user_identity, 'Karr Bot <karr@example.com>', 'git_user_identity combines both');
};

subtest 'save_task_ref / load_task_ref roundtrip' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    system('git', 'init', '-q', $tmpdir->stringify);
    system('git', '-C', $tmpdir->stringify, 'config', 'user.email', 'test@test.com');
    system('git', '-C', $tmpdir->stringify, 'config', 'user.name', 'Test');

    require App::karr::Task;

    my $git = App::karr::Git->new( dir => $tmpdir->stringify );
    my $task = App::karr::Task->new(
        id => 1, title => 'Test save ref', status => 'todo',
        priority => 'high', class => 'standard', body => 'Some body text',
    );

    $git->save_task_ref($task);

    my $loaded = $git->load_task_ref(1);
    ok $loaded, 'load_task_ref returns task';
    is $loaded->id, 1, 'loaded task id';
    is $loaded->title, 'Test save ref', 'loaded task title';
    is $loaded->body, 'Some body text', 'loaded task body';

    # Test load nonexistent
    my $missing = $git->load_task_ref(999);
    ok !$missing, 'load_task_ref returns undef for missing';
};

subtest 'list_task_refs' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    system('git', 'init', '-q', $tmpdir->stringify);
    system('git', '-C', $tmpdir->stringify, 'config', 'user.email', 'test@test.com');
    system('git', '-C', $tmpdir->stringify, 'config', 'user.name', 'Test');

    require App::karr::Task;

    my $git = App::karr::Git->new( dir => $tmpdir->stringify );

    my $t1 = App::karr::Task->new(
        id => 1, title => 'First', status => 'todo',
        priority => 'high', class => 'standard',
    );
    my $t2 = App::karr::Task->new(
        id => 2, title => 'Second', status => 'backlog',
        priority => 'medium', class => 'standard',
    );

    $git->save_task_ref($t1);
    $git->save_task_ref($t2);

    my @ids = $git->list_task_refs;
    is_deeply \@ids, [1, 2], 'list_task_refs returns sorted IDs';
};

done_testing;
