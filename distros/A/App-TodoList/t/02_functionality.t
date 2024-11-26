#!/usr/bin/env perl
use strict;
use warnings;

use lib "lib";

use Test::More;
use File::Temp qw/tempfile/;
use App::TodoList;

subtest 'Adding tasks' => sub {
    my ($fh, $tempfile) = tempfile(UNLINK => 1);

    my $todo = App::TodoList->new(file => $tempfile);

    my $task_count = $todo->add_task("Learn Perl");
    is($task_count, 1, "Task added successfully");

    $task_count = $todo->add_task("Write tests");
    is($task_count, 2, "Second task added successfully");
};

subtest 'Listing tasks' => sub {
    my ($fh, $tempfile) = tempfile(UNLINK => 1);

    my $todo = App::TodoList->new(file => $tempfile);

    my $task_count = $todo->add_task("Learn Perl");

    my @tasks = $todo->list_tasks();
    is(scalar @tasks, 1, "Correct number of tasks listed");
    is($tasks[0]->{task}, "Learn Perl", "First task description matches");
    is($tasks[0]->{completed}, 0, "First task is not completed");
};

subtest 'Completing tasks' => sub {
    my ($fh, $tempfile) = tempfile(UNLINK => 1);

    my $todo = App::TodoList->new(file => $tempfile);

    my $task_count = $todo->add_task("Learn Perl");

    ok($todo->complete_task(1), "First task marked as completed");
    my @tasks = $todo->list_tasks();
    is($tasks[0]->{completed}, 1, "First task is now completed");
};

subtest 'Deleting tasks' => sub {
    my ($fh, $tempfile) = tempfile(UNLINK => 1);

    my $todo = App::TodoList->new(file => $tempfile);

    my $task_count = $todo->add_task("Learn Perl");

    ok($todo->delete_task(1), "First task deleted successfully");
    my @tasks = $todo->list_tasks();
    is(scalar @tasks, 0, "No task remaining after deletion");
};

subtest 'Invalid task operations' => sub {
    my ($fh, $tempfile) = tempfile(UNLINK => 1);

    my $todo = App::TodoList->new(file => $tempfile);

    ok(!$todo->complete_task(99), "Completing non-existent task returns false");
    ok(!$todo->delete_task(99), "Deleting non-existent task returns false");
};

subtest 'Reloading tasks from file' => sub {
    my ($fh, $tempfile) = tempfile(UNLINK => 1);

    my $todo = App::TodoList->new(file => $tempfile);

    $todo->add_task("New Task");
    undef $todo;

    my $new_todo = App::TodoList->new(file => $tempfile);
    my @new_tasks = $new_todo->list_tasks();
    is(scalar @new_tasks, 1, "Tasks loaded from file correctly after reload");
    is($new_tasks[0]->{task}, "New Task", "New task loaded correctly from file");
};

done_testing();
