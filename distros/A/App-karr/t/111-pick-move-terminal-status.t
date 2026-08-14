# t/111-pick-move-terminal-status.t
#
# Ticket #101: the last leftover of the #67 terminal-status sweep. Every other
# status-change path hands the board's own config to
# App::karr::Task::update_timestamps -- move, edit --status, archive and
# handoff all go through Role::TaskMutation::apply_status_change, which got
# the config under #98. Pick does not use that path (it has its own
# compare-and-swap loop, see EXCLUSIVITY in App::karr::Cmd::Pick), and its
# direct call kept the three-argument form, so the terminal question was still
# answered for the default board -- the literal done + archived.
#
# On a board whose columns run backlog / doing / shipped / archived:
#
#   karr pick --claim agent-x --move shipped
#     -> status: shipped
#     -> started: 2026-...Z
#     -> (no completed key)      # shipped is not terminal on the default board
#
# so a card picked straight into the board's final column was never recorded
# as finished, and everything built on that stamp (karr context's
# recently-completed, the cycle times karr metrics is meant to report) stayed
# empty for it.

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Pick;

my @CUSTOM = qw( backlog doing shipped archived );

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
  $store->save_task(
    App::karr::Task->new(
      id       => 1,
      title    => 'Ship me',
      status   => $statuses[0],
      priority => 'medium',
      class    => 'standard',
    )
  );
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

subtest 'pick --move into the board final column stamps completed' => sub {
  my $store = board(@CUSTOM);
  my ( $err ) = run_execute(
    App::karr::Cmd::Pick->new(
      store => $store, claim => 'agent-x', move => 'shipped' ) );
  is( $err, '', 'pick does not die' ) or diag("died with: $err");

  my ($task) = $store->load_tasks;
  is( $task->status,     'shipped', 'the card is in the final column' );
  is( $task->claimed_by, 'agent-x', 'and carries the claim' );
  ok( $task->has_started, 'started is stamped' );
  ok( $task->has_completed, 'completed is stamped too' );
};

subtest 'pick --move to a working column does not stamp completed' => sub {
  my $store = board(@CUSTOM);
  my ( $err ) = run_execute(
    App::karr::Cmd::Pick->new(
      store => $store, claim => 'agent-x', move => 'doing' ) );
  is( $err, '', 'pick does not die' ) or diag("died with: $err");

  my ($task) = $store->load_tasks;
  is( $task->status, 'doing', 'the card moved' );
  ok( $task->has_started, 'started is stamped (left the first column)' );
  ok( !$task->has_completed, 'but a working column is not a finish' );
};

subtest 'the default board is unchanged' => sub {
  my $store = board(qw( backlog todo done archived ));
  my ( $err ) = run_execute(
    App::karr::Cmd::Pick->new(
      store => $store, claim => 'agent-x', move => 'done' ) );
  is( $err, '', 'pick does not die' ) or diag("died with: $err");

  my ($task) = $store->load_tasks;
  ok( $task->has_completed, 'done still completes where done is the last column' );
};

done_testing;
