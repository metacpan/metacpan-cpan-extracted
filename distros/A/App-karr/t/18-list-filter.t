use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile );
use App::karr::Task;

my $dir = tempdir( CLEANUP => 1 );
my $board = path($dir)->child('karr');
$board->mkpath;
$board->child('tasks')->mkpath;

DumpFile($board->child('config.yml')->stringify, {
    version => 1, tasks_dir => 'tasks',
    statuses => ['backlog', 'todo', 'in-progress', 'done', 'archived'],
    priorities => ['low', 'medium', 'high', 'critical'],
    next_id => 4,
    defaults => { status => 'backlog', priority => 'medium', class => 'standard' },
});

App::karr::Task->new(
    id => 1, title => 'Claimed by A', status => 'in-progress',
    priority => 'high', class => 'standard', claimed_by => 'agent-a',
)->save($board->child('tasks'));

App::karr::Task->new(
    id => 2, title => 'Claimed by B', status => 'in-progress',
    priority => 'medium', class => 'standard', claimed_by => 'agent-b',
)->save($board->child('tasks'));

App::karr::Task->new(
    id => 3, title => 'Unclaimed', status => 'todo',
    priority => 'low', class => 'standard',
)->save($board->child('tasks'));

my @all_tasks = map { App::karr::Task->from_file($_) }
    sort $board->child('tasks')->children(qr/\.md$/);

my @claimed_a = grep { $_->has_claimed_by && $_->claimed_by eq 'agent-a' } @all_tasks;
is scalar @claimed_a, 1, 'one task claimed by agent-a';
is $claimed_a[0]->id, 1, 'correct task for agent-a';

my @unclaimed = grep { !$_->has_claimed_by } @all_tasks;
is scalar @unclaimed, 1, 'one unclaimed task';

done_testing;
