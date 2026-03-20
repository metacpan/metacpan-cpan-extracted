use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile );

use App::karr::Task;
use App::karr::Config;

subtest 'archive a task' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $board = path($dir)->child('karr');
  $board->mkpath;
  my $tasks = $board->child('tasks');
  $tasks->mkpath;
  DumpFile($board->child('config.yml')->stringify, App::karr::Config->default_config);

  my $task = App::karr::Task->new(
    id => 1, title => 'Test Archive', status => 'done',
  );
  $task->save($tasks->stringify);

  # Reload and verify
  my $loaded = App::karr::Task->from_file($tasks->child('001-test-archive.md'));
  is $loaded->status, 'done', 'starts as done';

  # Simulate archive
  $loaded->status('archived');
  $loaded->save;
  my $after = App::karr::Task->from_file($tasks->child('001-test-archive.md'));
  is $after->status, 'archived', 'now archived';
};

subtest 'already archived is idempotent' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $tasks = path($dir);

  my $task = App::karr::Task->new(
    id => 2, title => 'Already Archived', status => 'archived',
  );
  $task->save($tasks->stringify);

  my $loaded = App::karr::Task->from_file($tasks->child('002-already-archived.md'));
  is $loaded->status, 'archived', 'still archived';
};

done_testing;
