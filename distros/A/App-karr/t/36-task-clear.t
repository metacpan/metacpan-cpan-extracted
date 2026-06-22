use strict;
use warnings;
use Test::More;
use App::karr::Task;

# Optional fields are addressed through their predicate everywhere in the code
# base. Clearing one must drop the predicate, not leave it true-but-undef, and
# a cleared field must not be serialized (otherwise a reload re-creates the
# stale predicate). Regression for the release/unblock round trip.

subtest 'clear_X drops the predicate in memory' => sub {
  my $task = App::karr::Task->new( id => 1, title => 'x' );
  $task->claimed_by('agent-a');
  $task->claimed_at('2026-01-01T00:00:00Z');
  $task->blocked('waiting on API');
  ok $task->has_claimed_by, 'claimed_by set';
  ok $task->has_blocked,    'blocked set';

  $task->clear_claimed_by;
  $task->clear_claimed_at;
  $task->clear_blocked;
  ok !$task->has_claimed_by, 'clear_claimed_by drops predicate';
  ok !$task->has_claimed_at, 'clear_claimed_at drops predicate';
  ok !$task->has_blocked,    'clear_blocked drops predicate';
};

subtest 'cleared fields are not serialized and survive a reload' => sub {
  my $task = App::karr::Task->new( id => 2, title => 'y' );
  $task->claimed_by('agent-a');
  $task->claimed_at('2026-01-01T00:00:00Z');
  $task->clear_claimed_by;
  $task->clear_claimed_at;

  my $md = $task->to_markdown;
  unlike $md, qr/^claimed_by:/m, 'claimed_by not written after release';
  unlike $md, qr/^claimed_at:/m, 'claimed_at not written after release';

  my $reloaded = App::karr::Task->from_string($md);
  ok !$reloaded->has_claimed_by, 'reloaded task is unclaimed';
  ok !$reloaded->has_claimed_at, 'reloaded task has no claim timestamp';
};

subtest 'an explicit null in a loaded file is normalized to unset' => sub {
  # Older karr writes and external kanban-md edits may carry explicit nulls.
  my $legacy = App::karr::Task->from_string(<<'MD');
---
id: 3
title: legacy null
status: todo
priority: medium
class: standard
created: 2026-03-19T10:00:00Z
updated: 2026-03-19T10:00:00Z
claimed_by: ~
claimed_at: ~
blocked: ~
---
MD
  ok !$legacy->has_claimed_by, 'null claimed_by loads as unset';
  ok !$legacy->has_claimed_at, 'null claimed_at loads as unset';
  ok !$legacy->has_blocked,    'null blocked loads as unset';
};

done_testing;
