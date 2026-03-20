use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile );

use App::karr::Task;
use App::karr::Config;

subtest 'handoff sets review and claim' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $tasks = path($dir);

  my $task = App::karr::Task->new(
    id => 1, title => 'Handoff Test', status => 'in-progress',
    claimed_by => 'agent-1',
  );
  $task->save($tasks->stringify);

  my $loaded = App::karr::Task->from_file($tasks->child('001-handoff-test.md'));
  $loaded->status('review');
  $loaded->claimed_by('agent-1');
  require Time::Piece;
  $loaded->claimed_at(Time::Piece::gmtime()->datetime . 'Z');
  $loaded->save;

  my $after = App::karr::Task->from_file($tasks->child('001-handoff-test.md'));
  is $after->status, 'review', 'moved to review';
  is $after->claimed_by, 'agent-1', 'claim refreshed';
  ok $after->has_claimed_at, 'claimed_at set';
};

subtest 'handoff with note' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $tasks = path($dir);

  my $task = App::karr::Task->new(
    id => 2, title => 'Note Test', status => 'in-progress',
    body => 'Original body',
  );
  $task->save($tasks->stringify);

  my $loaded = App::karr::Task->from_file($tasks->child('002-note-test.md'));
  $loaded->body($loaded->body . "\nHandoff note here");
  $loaded->status('review');
  $loaded->save;

  my $after = App::karr::Task->from_file($tasks->child('002-note-test.md'));
  like $after->body, qr/Handoff note here/, 'note appended';
};

subtest 'handoff with block' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $tasks = path($dir);

  my $task = App::karr::Task->new(
    id => 3, title => 'Block Test', status => 'in-progress',
  );
  $task->save($tasks->stringify);

  my $loaded = App::karr::Task->from_file($tasks->child('003-block-test.md'));
  $loaded->status('review');
  $loaded->blocked('waiting for feedback');
  $loaded->save;

  my $after = App::karr::Task->from_file($tasks->child('003-block-test.md'));
  is $after->blocked, 'waiting for feedback', 'blocked with reason';
};

done_testing;
