use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::XS qw( DumpFile );
use Time::Piece;

use App::karr::Task;
use App::karr::Config;
use App::karr::Cmd::Context;
use MockStore;

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

# Regression: karr context crashed with
#   Can't locate object method "strftime" via package "Sun May 24 ..."
# because Cmd::Context never did `use Time::Piece`, so gmtime returned a
# plain string in the overdue / recently-completed / _count_overdue paths.
# These subtests drive the real command through every gmtime->strftime branch.
subtest 'context command runs without strftime crash' => sub {
  my $today  = gmtime->strftime('%Y-%m-%d');
  my @tasks = (
    App::karr::Task->new(
      id => 1, title => 'Active', status => 'in-progress', priority => 'high',
    ),
    App::karr::Task->new(
      id => 2, title => 'Overdue', status => 'todo', priority => 'medium',
      due => '2000-01-01',
    ),
    App::karr::Task->new(
      id => 3, title => 'Recently Done', status => 'done', priority => 'low',
      completed => $today,
    ),
  );

  # Plain markdown output exercises overdue (line ~112) and _count_overdue
  # (line ~221) gmtime->strftime calls.
  my $cmd = App::karr::Cmd::Context->new( store => MockStore->new( tasks => \@tasks ) );
  my $md;
  my $err = do {
    local $@;
    eval {
      local *STDOUT;
      open STDOUT, '>', \$md or die $!;
      $cmd->execute( [], [] );
    };
    $@;
  };
  is $err, '', 'plain context does not die on gmtime->strftime';
  like $md, qr/due 2000-01-01/, 'overdue section rendered via Time::Piece';
  like $md, qr/1 overdue/,      'overdue count rendered via Time::Piece';
};

subtest 'context --json runs without strftime crash' => sub {
  my @tasks = (
    App::karr::Task->new(
      id => 2, title => 'Overdue', status => 'todo', priority => 'medium',
      due => '2000-01-01',
    ),
  );
  my $cmd = App::karr::Cmd::Context->new(
    store => MockStore->new( tasks => \@tasks ),
    json  => 1,
  );
  my $out;
  my $err = do {
    local $@;
    eval {
      local *STDOUT;
      open STDOUT, '>', \$out or die $!;
      $cmd->execute( [], [] );
    };
    $@;
  };
  is $err, '', 'context --json does not die on gmtime->strftime';
  like $out, qr/"overdue":1/, 'json summary includes overdue count';
};

subtest 'context recently-completed section exercises cutoff strftime' => sub {
  # Selecting only recently-completed forces the line ~117 gmtime arithmetic
  # ((gmtime() - N*86400)->strftime) to run.
  my $cmd = App::karr::Cmd::Context->new(
    store    => MockStore->new,
    sections => 'recently-completed',
    days     => 14,
  );
  my $out;
  my $err = do {
    local $@;
    eval {
      local *STDOUT;
      open STDOUT, '>', \$out or die $!;
      $cmd->execute( [], [] );
    };
    $@;
  };
  is $err, '', 'recently-completed cutoff arithmetic does not die';
};

done_testing;
