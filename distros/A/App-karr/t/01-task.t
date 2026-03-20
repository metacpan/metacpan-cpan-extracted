use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;

use App::karr::Task;

subtest 'task creation' => sub {
  my $task = App::karr::Task->new(
    id    => 1,
    title => 'Test Task',
  );
  is $task->id, 1;
  is $task->title, 'Test Task';
  is $task->status, 'backlog';
  is $task->priority, 'medium';
  is $task->class, 'standard';
};

subtest 'slug generation' => sub {
  my $task = App::karr::Task->new(id => 1, title => 'Fix Login Bug');
  is $task->slug, 'fix-login-bug';

  $task = App::karr::Task->new(id => 1, title => 'Hello, World! Test');
  is $task->slug, 'hello-world-test';
};

subtest 'filename' => sub {
  my $task = App::karr::Task->new(id => 3, title => 'My Task');
  is $task->filename, '003-my-task.md';
};

subtest 'save and load' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $task = App::karr::Task->new(
    id       => 1,
    title    => 'Test Save',
    status   => 'todo',
    priority => 'high',
    tags     => [qw(backend api)],
    body     => 'This is the task body.',
  );
  $task->save($dir);

  my $file = path($dir)->child('001-test-save.md');
  ok $file->exists, 'task file created';

  my $loaded = App::karr::Task->from_file($file);
  is $loaded->id, 1;
  is $loaded->title, 'Test Save';
  is $loaded->status, 'todo';
  is $loaded->priority, 'high';
  is_deeply $loaded->tags, [qw(backend api)];
  is $loaded->body, 'This is the task body.';
};

subtest 'to_frontmatter' => sub {
  my $task = App::karr::Task->new(
    id       => 5,
    title    => 'FM Test',
    assignee => 'alice',
  );
  my $fm = $task->to_frontmatter;
  is $fm->{id}, 5;
  is $fm->{assignee}, 'alice';
  ok !exists $fm->{due}, 'no due in frontmatter when not set';
};

done_testing;
