# t/107-completed-stamp-terminal-status.t
#
# Ticket #98, second half: App::karr::Task::update_timestamps asked
# App::karr::Config->is_terminal_status on the *class*, which has no board to
# consult and so answers for the default one -- the literal `done` and
# `archived`. Ticket #67 had already derived the real terminal statuses from
# the board's own config (last configured status, or the one before it when the
# last is `archived`), but this one caller never got the board handed to it.
#
# On a board whose columns run backlog / doing / shipped / archived:
#
#   karr move 1 shipped
#     -> started: 2026-...Z      # the first-status rule worked
#     -> (no completed key)      # nothing was ever recorded as finished
#
# Which silently emptied everything built on that stamp -- `karr context`'s
# recently-completed section (ticket #99) and the cycle-time arithmetic
# `karr metrics` is meant to do.
#
# The one caller this did not go through -- App::karr::Cmd::Pick, which calls
# update_timestamps directly for `karr pick --move` -- got the same config
# under ticket #101; t/111-pick-move-terminal-status.t covers that path.

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use YAML::XS qw( Dump );

use App::karr::Config;
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Move;
use App::karr::Cmd::Edit;

my @CUSTOM = qw( backlog doing shipped archived );

sub task {
  return App::karr::Task->new(
    id       => 1,
    title    => 'Ship me',
    status   => 'backlog',
    priority => 'medium',
    class    => 'standard',
  );
}

sub board {
  my (@statuses) = @_;
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or BAIL_OUT('git init failed');
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
    or BAIL_OUT('git config failed');
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
    or BAIL_OUT('git config failed');
  my $git = App::karr::Git->new( dir => $repo );
  $git->write_ref(
    'refs/karr/config',
    Dump(
      { version  => 1,
        board    => { name => 'Custom' },
        statuses => [@statuses],
      }
    )
  );
  $git->write_ref( 'refs/karr/meta/next-id', "9\n" );
  my $store = App::karr::BoardStore->new( git => $git );
  $store->save_task( task() );
  return $store;
}

sub run_execute {
  my ( $cmd, @args ) = @_;
  my $out = '';
  my $err = do {
    local $@;
    eval {
      local *STDOUT;
      open STDOUT, '>', \$out or die $!;
      $cmd->execute( \@args, [] );
    };
    $@;
  };
  return ( $err, $out );
}

subtest 'the board decides which move counts as finishing' => sub {
  my $config = App::karr::Config->from_merged( { statuses => [@CUSTOM] } );

  my $t = task();
  $t->update_timestamps( 'doing', 'shipped', 'backlog', $config );
  ok( $t->has_completed, 'a move into the board\'s final column is completion' );
  like( $t->completed, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/,
    'stamped as a full timestamp, like created/updated' );

  my $reopened = task();
  $reopened->update_timestamps( 'doing', 'shipped', 'backlog', $config );
  $reopened->started('2026-01-01T00:00:00Z');
  $reopened->update_timestamps( 'shipped', 'doing', 'backlog', $config );
  ok( !$reopened->has_completed, 'and reopening out of it clears the stamp' );
  is( $reopened->started, '2026-01-01T00:00:00Z',
    'while started is deliberately kept' );
};

subtest 'a status that is only terminal on the default board is not' => sub {
  my $config = App::karr::Config->from_merged( { statuses => [@CUSTOM] } );
  my $t = task();
  # `done` is not a column this board has at all.
  $t->update_timestamps( 'doing', 'done', 'backlog', $config );
  ok( !$t->has_completed, 'done does not finish work on a board without it' );
};

subtest 'without a config the default board still decides' => sub {
  # The documented fallback, and what every caller that has no board to hand
  # keeps getting.
  my $t = task();
  $t->update_timestamps( 'todo', 'done', 'backlog' );
  ok( $t->has_completed, 'done completes on the default board' );

  my $u = task();
  $u->update_timestamps( 'doing', 'shipped', 'backlog' );
  ok( !$u->has_completed, 'shipped does not, with no board to ask' );
};

subtest 'karr move records the completion on a custom board' => sub {
  my $store = board(@CUSTOM);
  my ( $err ) = run_execute(
    App::karr::Cmd::Move->new( store => $store ), 1, 'shipped' );
  is( $err, '', 'move does not die' ) or diag("died with: $err");

  my ($task) = $store->load_tasks;
  is( $task->status, 'shipped', 'the card is in the final column' );
  ok( $task->has_completed, 'and it carries a completion stamp' );
  ok( $task->has_started,   'plus the start it was dragged past' );
};

subtest 'karr edit --status records it too' => sub {
  # edit --status goes through the same one status-change path (ticket #55),
  # so it must not disagree with move about what finishing means.
  my $store = board(@CUSTOM);
  my ( $err ) = run_execute(
    App::karr::Cmd::Edit->new( store => $store, status => 'shipped' ), 1 );
  is( $err, '', 'edit does not die' ) or diag("died with: $err");

  my ($task) = $store->load_tasks;
  ok( $task->has_completed, 'edit --status shipped completes the card' );
};

subtest 'the default board is unchanged' => sub {
  my $store = board(qw( backlog todo done archived ));
  my ( $err ) = run_execute(
    App::karr::Cmd::Move->new( store => $store ), 1, 'done' );
  is( $err, '', 'move does not die' ) or diag("died with: $err");

  my ($task) = $store->load_tasks;
  ok( $task->has_completed, 'done still completes where done is the last column' );
};

subtest 'reopening through the command path clears it again' => sub {
  my $store = board(@CUSTOM);
  run_execute( App::karr::Cmd::Move->new( store => $store ), 1, 'shipped' );
  my ($shipped) = $store->load_tasks;
  ok( $shipped->has_completed, 'there is a stamp to clear in the first place' );

  my ( $err ) = run_execute(
    App::karr::Cmd::Move->new( store => $store ), 1, 'doing' );
  is( $err, '', 'move back does not die' ) or diag("died with: $err");

  my ($task) = $store->load_tasks;
  ok( !$task->has_completed, 'a reopened card is not completed any more' );
};

done_testing;
