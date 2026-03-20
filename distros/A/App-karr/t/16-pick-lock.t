use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile );
use App::karr::Task;
use App::karr::Git;
use App::karr::Lock;

my $repo = tempdir( CLEANUP => 1 );
system("git init '$repo' 2>/dev/null");
system("git -C '$repo' config user.email 'test\@test.com'");
system("git -C '$repo' config user.name 'Test'");

my $board = path($repo)->child('karr');
$board->mkpath;
$board->child('tasks')->mkpath;

DumpFile($board->child('config.yml')->stringify, {
    version => 1, board => { name => 'Test' }, tasks_dir => 'tasks',
    statuses => ['backlog', 'todo', 'in-progress', 'done', 'archived'],
    priorities => ['low', 'medium', 'high', 'critical'],
    next_id => 3, claim_timeout => '1h',
    defaults => { status => 'backlog', priority => 'medium', class => 'standard' },
});

for my $i (1, 2) {
    App::karr::Task->new(
        id => $i, title => "Task $i", status => 'todo',
        priority => 'high', class => 'standard',
    )->save($board->child('tasks'));
}

my $git = App::karr::Git->new( dir => $repo );
my $lock = App::karr::Lock->new( git => $git );

# Agent A acquires lock on task 1
my ($ok1, $msg1) = $lock->acquire(1, 'agent-a@test.com');
ok $ok1, 'agent A acquires lock on task 1';

# Agent B tries same lock — fails
my ($ok2, $msg2) = $lock->acquire(1, 'agent-b@test.com');
ok !$ok2, 'agent B cannot lock task 1';
like $msg2, qr/locked by/, 'correct rejection message';

# Agent B acquires lock on task 2
my ($ok3, $msg3) = $lock->acquire(2, 'agent-b@test.com');
ok $ok3, 'agent B acquires lock on task 2';

# Agent A releases
$lock->release(1, 'agent-a@test.com');
my ($ok5, $msg5) = $lock->acquire(1, 'agent-b@test.com');
ok $ok5, 'agent B can lock task 1 after release';

# Cleanup
$lock->release(1, 'agent-b@test.com');
$lock->release(2, 'agent-b@test.com');

done_testing;
