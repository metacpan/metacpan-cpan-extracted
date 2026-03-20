use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use App::karr::Task;

my $content = <<'MD';
---
id: 42
title: Test from_string
status: todo
priority: high
class: standard
created: 2026-03-19T10:00:00Z
updated: 2026-03-19T10:00:00Z
---

This is the body.
MD

# Test from_string
my $task = App::karr::Task->from_string($content);
is $task->id, 42, 'from_string: id';
is $task->title, 'Test from_string', 'from_string: title';
is $task->status, 'todo', 'from_string: status';
is $task->body, 'This is the body.', 'from_string: body';
ok !$task->has_file_path, 'from_string: no file_path';

# Test from_file gives same result
my $dir = tempdir( CLEANUP => 1 );
my $file = path($dir)->child('042-test-from-string.md');
$file->spew_utf8($content);

my $file_task = App::karr::Task->from_file($file);
is $file_task->id, $task->id, 'from_file matches from_string: id';
is $file_task->title, $task->title, 'from_file matches from_string: title';
is $file_task->body, $task->body, 'from_file matches from_string: body';
ok $file_task->has_file_path, 'from_file: has file_path';

# Test content without body
my $no_body = <<'MD';
---
id: 99
title: No body task
status: backlog
priority: low
class: standard
created: 2026-03-19T10:00:00Z
updated: 2026-03-19T10:00:00Z
---
MD

my $nb = App::karr::Task->from_string($no_body);
is $nb->id, 99, 'no-body task: id';
is $nb->body, '', 'no-body task: empty body';

done_testing;
