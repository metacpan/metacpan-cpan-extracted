# t/112-handoff-derived-target.t
#
# Ticket #102: karr handoff moved the task to the literal status `review`,
# whatever the board configures. kanban-md's handoff targets `review` too, but
# it checks the board first and refuses one without that column
# (cmd/handoff.go:105-110: "board has no 'review' status; add one to use
# handoff"). karr's handoff goes through apply_status_change, whose
# validate_status turns the same situation into an invalid-status usage error
# -- so on a board whose columns do not include review, handoff was simply
# unusable.
#
# The target is now derived from the board config: `review` whenever the board
# configures it (kanban-md's own behavior, so every board kanban-md can hand
# off on behaves exactly the same), otherwise the column a card sits in right
# before it is finished -- the last non-terminal status, per the same
# terminal-status rule ticket #67 took from kanban-md's IsTerminalStatus.

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
use App::karr::Cmd::Handoff;

# backlog todo doing shipped archived: terminal is shipped + archived, so the
# derived handoff target is doing -- a visible move for a card sitting in todo.
my @CUSTOM = qw( backlog todo doing shipped archived );

sub cfg {
  my (@statuses) = @_;
  return App::karr::Config->from_merged( { statuses => \@statuses } );
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
  $store->save_task(
    App::karr::Task->new(
      id         => 1,
      title      => 'Review me',
      status     => 'todo',
      priority   => 'medium',
      class      => 'standard',
      claimed_by => 'agent-x',
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

subtest 'the target is derived from the board config' => sub {
  is( App::karr::Config->handoff_status, 'review',
    'asked on the class, the default board answers review' );
  is( cfg(qw( backlog todo in-progress review done archived ))->handoff_status,
    'review', 'and so does an explicit default-shaped board' );
  is( cfg(@CUSTOM)->handoff_status, 'doing',
    'a board without review hands off to its last non-terminal column' );
  is( cfg(qw( backlog review doing shipped ))->handoff_status, 'review',
    'a configured review wins even when it is not the last working column' );
};

subtest 'a board with no working column at all cannot hand off' => sub {
  my $err = do {
    local $@;
    eval { cfg(qw( done archived ))->handoff_status; 1 } ? undef : $@;
  };
  like( $err, qr/^Usage error: /, 'dies as a usage error' );
  like( $err, qr/no .*review/i, 'and names the missing column' );
};

subtest 'handoff lands on the derived column' => sub {
  my $store = board(@CUSTOM);
  my ( $err, $out ) = run_execute(
    App::karr::Cmd::Handoff->new( store => $store, claim => 'agent-x' ), 1 );
  is( $err, '', 'handoff does not die' ) or diag("died with: $err");
  like( $out, qr/Handed off task 1 -> doing/, 'and says where the card went' );

  my ($task) = $store->load_tasks;
  is( $task->status, 'doing', 'the card is in the derived column' );
  is( $task->claimed_by, 'agent-x', 'with the claim refreshed, not lost' );
  ok( !$task->has_completed, 'and no completion was recorded for it' );
};

subtest 'the default board still hands off to review' => sub {
  my $store = board(qw( backlog todo in-progress review done archived ));
  my ( $err, $out ) = run_execute(
    App::karr::Cmd::Handoff->new( store => $store, claim => 'agent-x' ), 1 );
  is( $err, '', 'handoff does not die' ) or diag("died with: $err");
  like( $out, qr/Handed off task 1 -> review/, 'same message as before' );

  my ($task) = $store->load_tasks;
  is( $task->status, 'review', 'review is still the target where it exists' );
};

done_testing;
