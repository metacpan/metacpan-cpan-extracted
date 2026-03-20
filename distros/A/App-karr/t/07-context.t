use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile );
use Time::Piece;

use App::karr::Task;
use App::karr::Config;

subtest 'context markdown rendering' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $board = path($dir)->child('karr');
  $board->mkpath;
  my $tasks = $board->child('tasks');
  $tasks->mkpath;
  DumpFile($board->child('config.yml')->stringify, App::karr::Config->default_config);

  # Create tasks in various states
  App::karr::Task->new(
    id => 1, title => 'Active Task', status => 'in-progress',
    priority => 'high',
  )->save($tasks->stringify);

  App::karr::Task->new(
    id => 2, title => 'Blocked Task', status => 'in-progress',
    priority => 'medium', blocked => 'waiting on API',
  )->save($tasks->stringify);

  App::karr::Task->new(
    id => 3, title => 'Done Task', status => 'done',
    priority => 'low', completed => gmtime->strftime('%Y-%m-%d'),
  )->save($tasks->stringify);

  # Load and verify tasks
  my @files = sort $tasks->children(qr/\.md$/);
  is scalar @files, 3, 'three task files created';

  my @loaded = map { App::karr::Task->from_file($_) } @files;
  my @in_progress = grep { $_->status eq 'in-progress' && !$_->has_blocked } @loaded;
  is scalar @in_progress, 1, 'one active non-blocked task';

  my @blocked = grep { $_->has_blocked } @loaded;
  is scalar @blocked, 1, 'one blocked task';
};

subtest 'write-to with sentinels' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $file = path($dir)->child('AGENTS.md');

  # Write initial content
  my $context = "<!-- BEGIN kanban-md context -->\n## Board: Test\n<!-- END kanban-md context -->\n";
  $file->spew_utf8("# My Agents\n\n" . $context);

  # Update with new context
  my $new_context = "<!-- BEGIN kanban-md context -->\n## Board: Updated\n<!-- END kanban-md context -->\n";
  my $content = $file->slurp_utf8;
  $content =~ s/<!-- BEGIN kanban-md context -->.*<!-- END kanban-md context -->\n?/$new_context/s;
  $file->spew_utf8($content);

  my $result = $file->slurp_utf8;
  like $result, qr/# My Agents/, 'preserves existing content';
  like $result, qr/Board: Updated/, 'updated context';
  unlike $result, qr/Board: Test/, 'old context replaced';
};

done_testing;
