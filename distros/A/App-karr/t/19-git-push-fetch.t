use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use App::karr::Git;
use App::karr::Task;

# Create a bare "remote" repo
my $bare = tempdir( CLEANUP => 1 );
system("git init --bare '$bare' 2>/dev/null");

# Create "agent A" working copy
my $repo_a = tempdir( CLEANUP => 1 );
system("git init '$repo_a' 2>/dev/null");
system("git -C '$repo_a' config user.email 'a\@test.com'");
system("git -C '$repo_a' config user.name 'Agent A'");
system("git -C '$repo_a' remote add origin '$bare'");
# Need at least one commit for push to work
system("git -C '$repo_a' commit --allow-empty -m 'init' 2>/dev/null");

# Determine default branch name
my $branch = `git -C '$repo_a' rev-parse --abbrev-ref HEAD 2>/dev/null`;
chomp $branch;
system("git -C '$repo_a' push origin $branch 2>/dev/null");

# Create "agent B" working copy
my $repo_b = tempdir( CLEANUP => 1 );
system("git clone '$bare' '$repo_b' 2>/dev/null");
system("git -C '$repo_b' config user.email 'b\@test.com'");
system("git -C '$repo_b' config user.name 'Agent B'");

my $git_a = App::karr::Git->new( dir => $repo_a );
my $git_b = App::karr::Git->new( dir => $repo_b );

# Agent A writes a task ref and pushes
my $task = App::karr::Task->new(
    id => 1, title => 'Push test', status => 'todo',
    priority => 'high', class => 'standard', body => 'Test body',
);
$git_a->save_task_ref($task);
ok $git_a->push, 'agent A pushes refs';

# Agent B fetches and reads
ok $git_b->pull, 'agent B pulls refs';
my $fetched = $git_b->load_task_ref(1);
ok $fetched, 'agent B can load task from refs';
is $fetched->title, 'Push test', 'fetched task has correct title';
is $fetched->body, 'Test body', 'fetched task has correct body';

# Agent B writes a different task and pushes
my $task2 = App::karr::Task->new(
    id => 2, title => 'From agent B', status => 'backlog',
    priority => 'medium', class => 'standard',
);
$git_b->save_task_ref($task2);
ok $git_b->push, 'agent B pushes refs';

# Agent A pulls and sees both tasks
ok $git_a->pull, 'agent A pulls refs';
my @ids = $git_a->list_task_refs;
is_deeply \@ids, [1, 2], 'agent A sees both tasks after pull';

done_testing;
