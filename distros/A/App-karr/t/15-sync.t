# t/15-sync.t - Test sync lifecycle in Role::SyncLifecycle
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use Path::Tiny qw( path tempdir );
use YAML::XS qw( Dump Load );

use App::karr::Git;
use App::karr::Role::BoardAccess;

# Build a tiny class that consumes BoardAccess (which includes SyncLifecycle)
{
    package TestSyncBoard;
    use Moo;
    use MooX::Options;
    with 'App::karr::Role::BoardAccess';
    # dir / has_dir now come from Role::BoardDiscovery's `option dir`, just as
    # every real command gets them by composing BoardAccess.
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

plan tests => 4;

subtest 'sync_before returns SyncGuard' => sub {
    my $repo = _init_repo();

    my $board = TestSyncBoard->new(dir => $repo->stringify);
    ok($board->can('sync_before'), 'sync_before method exists');
    ok($board->can('sync_after'), 'sync_after method exists');
    ok($board->can('append_log'), 'append_log method exists');

    my $guard = $board->sync_before;
    ok($guard->isa('App::karr::SyncGuard'), 'sync_before returns SyncGuard');
    ok($guard->can('done'), 'guard has done method');
    ok($guard->can('errs'), 'guard has errs method');

    # Mark guard done so DESTROY doesn't try to push
    $guard->done;
};

subtest 'sync_after pushes to remote' => sub {
    my ($local, $remote) = _init_remote_pair();
    my $board = TestSyncBoard->new(dir => $local->stringify);

    my $local_git = $board->git;
    $local_git->write_ref('refs/karr/config', Dump({version => 1}));

    $board->sync_after;

    my $remote_git = App::karr::Git->new(dir => $remote->stringify);
    ok($remote_git->ref_exists('refs/karr/config'), 'config ref was pushed to remote');
};

subtest 'append_log writes NDJSON to ref' => sub {
    my $repo = _init_repo();
    my $board = TestSyncBoard->new(dir => $repo->stringify);
    my $git = $board->git;

    $board->append_log($git, action => 'create', task_id => 1, ts => '2026-01-01T00:00:00Z');
    $board->append_log($git, action => 'move', task_id => 1, ts => '2026-01-02T00:00:00Z');

    my $log_content = $git->read_ref('refs/karr/log/user/test_test.com');
    ok($log_content, 'log ref exists at role-qualified path');

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
    my $board = TestSyncBoard->new(dir => $local->stringify);
    my $git = $board->git;

    # Write two task refs
    $git->write_ref('refs/karr/config', Dump({version => 1}));
    $git->write_ref('refs/karr/meta/next-id', "3\n");
    require App::karr::Task;
    my $t1 = App::karr::Task->new(id => 1, title => 'Task 1', status => 'backlog', priority => 'medium', class => 'standard');
    my $t2 = App::karr::Task->new(id => 2, title => 'Task 2', status => 'backlog', priority => 'medium', class => 'standard');
    $git->save_task_ref($t1);
    $git->save_task_ref($t2);

    $board->sync_after;

    my $remote_git = App::karr::Git->new(dir => $remote->stringify);
    is_deeply([sort {$a <=> $b} $remote_git->list_task_refs], [1, 2], 'both task refs pushed to remote');

    # Delete task 2 locally and sync
    $git->delete_ref('refs/karr/tasks/2/data');
    $board->sync_after;

    is_deeply([sort {$a <=> $b} $remote_git->list_task_refs], [1], 'task 2 ref was pruned from remote');
};

done_testing;