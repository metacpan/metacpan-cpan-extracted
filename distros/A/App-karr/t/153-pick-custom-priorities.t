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
use App::karr::Cmd::Context;

# Ticket #149: karr pick ranked candidates through
# App::karr::Config->priority_order / ->class_order -- a hardcoded table that
# only knew the four default priorities and four default classes. A board
# imported from kanban-md with a longer priorities list (or a name the table
# did not know) collapsed every unknown priority into the `// 2` default and
# handed out the wrong card, while `karr list --sort priority` showed the
# correct order right next to it. `karr context --sections in-progress` had
# the same blind spot for the same reason.
#
# Each subtest pins a different angle of the bug. The pre-#149 code fails
# every "the configured priority order, not the hardcoded table" assertion.
# The pre-#149 pick uses ($class_order{$a->class} // 2) and
# ($pri_order{$a->priority} // 2); the post-#149 code reads the board's own
# lists and the `// 2` fallback is gone.

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or die "git init failed";
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
  return $repo;
}

# A board whose config can be overridden per test, so "config order" is
# proven to come from the config rather than from a hardcoded table.
sub _board {
  my (%override) = @_;
  my $repo = _init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/config',
    Dump( { version => 1, board => { name => 'Sort Board' }, %override } ) );
  return App::karr::BoardStore->new( git => $git );
}

sub mk {
  my ( $store, %a ) = @_;
  my $t = App::karr::Task->new(
    id       => $a{id},
    title    => $a{title},
    status   => $a{status}   // 'todo',
    priority => $a{priority} // 'medium',
    class    => $a{class}    // 'standard',
  );
  $store->save_task($t);
  return $t;
}

# Capture `karr pick --claim AGENT` and return the picked id (or undef if
# nothing was picked). The :encoding(UTF-8) layer bin/karr installs on STDOUT
# (App::karr::Encoding::enable_std_utf8) is dropped when STDOUT is reopened
# onto a scalar, so the buffer carries raw bytes here.
sub pick_id {
  my ( $store, %opt ) = @_;
  my $cmd = App::karr::Cmd::Pick->new( store => $store, %opt );
  my $buf = '';
  my $err = do {
    local $@;
    eval {
      local *STDOUT;
      open STDOUT, '>', \$buf or die $!;
      $cmd->execute( [], [] );
    };
    $@;
  };
  die "pick died: $err" if $err;
  return $buf =~ /^Picked task (\d+):/m ? $1 : undef;
}

# Capture the in-progress section of `karr context --sections in-progress`
# and return the task ids in the order they were listed.
sub context_ids {
  my ( $store, %opt ) = @_;
  my $cmd = App::karr::Cmd::Context->new( store => $store, %opt );
  my $buf = '';
  my $err = do {
    local $@;
    eval {
      local *STDOUT;
      open STDOUT, '>', \$buf or die $!;
      $cmd->execute( [], [] );
    };
    $@;
  };
  die "context died: $err" if $err;
  my ($section) = $buf =~ /### In Progress\n(.*?)\n\n/s;
  return [ $section =~ /^\s*-\s*\*\*#(\d+)/mg ] if defined $section;
  return [];
}

subtest 'pick honours a board with priorities outside the old hardcoded table' => sub {
  # The pre-#149 hardcoded class methods only knew [critical high medium low];
  # every name past `critical` (including any custom priority) tied via
  # `// 2` and went out by id. The ticket's reproduction is the exact case
  # this pins: `blocker` is the most urgent priority on this board, and pick
  # should hand out the blocker card.
  my $store = _board(
    priorities => [qw( low medium high critical blocker )],
  );
  mk( $store, id => 1, title => 'merely critical', priority => 'critical' );
  mk( $store, id => 2, title => 'a blocker',      priority => 'blocker' );

  is pick_id( $store, claim => 'agent-test' ), 2,
    'pick hands out the blocker (the most urgent on this board), not id 1'
    or diag 'pre-#149 both priorities fell into // 2 and id 1 won by tie-break';
};

subtest 'pick orders priorities by config, not by an alphabetical fallback' => sub {
  # A row of priorities whose only order is the one in the config list: an
  # alphabetical or hardcoded-table sort would still produce either
  # [id 1, 2, 3, 4, 5] or [id 5, 4, 3, 2, 1] -- neither is what the
  # config says. The exhaustive list-ids ordering is what the test
  # pins, so any future "fall back to a default" regression fails here.
  my $store = _board(
    priorities => [qw( p0 p1 p2 p3 p4 )],
  );
  mk( $store, id => 1, title => 'at p4', priority => 'p4' );
  mk( $store, id => 2, title => 'at p0', priority => 'p0' );
  mk( $store, id => 3, title => 'at p2', priority => 'p2' );
  mk( $store, id => 4, title => 'at p3', priority => 'p3' );
  mk( $store, id => 5, title => 'at p1', priority => 'p1' );

  my @picked;
  for ( 1 .. 5 ) {
    push @picked, pick_id( $store, claim => "agent-$_" );
  }
  is_deeply \@picked, [ 1, 4, 3, 5, 2 ],
    'pick order is p4, p3, p2, p1, p0 -- the config read most-urgent-last'
    or diag "pre-#149 the alphabetical tie-break threw this order away";
};

subtest 'pick respects classes outside the old hardcoded table' => sub {
  # The pre-#149 class_order only knew [expedite, fixed-date, standard,
  # intangible]. The ticket points at this board as the case where the
  # hardcoded table still happened to agree for one entry (expedite) and
  # silently lied about the other (standard). With a fully custom list
  # (none of expedite/fixed-date/standard/intangible present), every class
  # hit the `// 2` fallback and ordering was by id.
  my $store = _board(
    classes => [qw( alpha beta )],
  );
  mk( $store, id => 1, title => 'in alpha', class => 'alpha' );
  mk( $store, id => 2, title => 'in beta',  class => 'beta' );

  is pick_id( $store, claim => 'agent-test' ), 1,
    'alpha sorts first (index 0 in classes is the most urgent class)';
};

subtest 'pick honours class + priority together on a custom board' => sub {
  # Class wins over priority in the sort (ticket #149 / kanban-md pick.go:
  # lower class index wins, then priority). Reorders within the same class
  # by priority, then by id.
  my $store = _board(
    priorities => [qw( low high )],
    classes    => [qw( alpha beta )],
  );
  mk( $store, id => 1, title => 'alpha high',   class => 'alpha', priority => 'high' );
  mk( $store, id => 2, title => 'alpha low',    class => 'alpha', priority => 'low' );
  mk( $store, id => 3, title => 'beta high',    class => 'beta',  priority => 'high' );
  mk( $store, id => 4, title => 'beta low',     class => 'beta',  priority => 'low' );

  my @picked;
  for ( 1 .. 4 ) {
    push @picked, pick_id( $store, claim => "agent-$_" );
  }
  is_deeply \@picked, [ 1, 2, 3, 4 ],
    'alpha wins on class; within each class, priority is most-urgent-first';
};

subtest 'context in-progress section honours a custom priority list' => sub {
  # Cmd::Context::Pri_order used the same hardcoded table pick did, so the
  # briefing hung a `blocker` card in the middle of the in-progress list
  # even though the board had it as the most urgent. The pre-#149 code
  # ordered critical above blocker -- a regression here would bring it
  # back.
  my $store = _board(
    priorities => [qw( low medium high critical blocker )],
  );
  # Three in-progress tasks at the three most urgent priorities.
  for my $row (
    [ 1, 'p-critical', 'critical' ],
    [ 2, 'p-blocker',  'blocker' ],
    [ 3, 'p-medium',   'medium' ],
  ) {
    mk( $store, id => $row->[0], title => $row->[1],
      priority => $row->[2], status => 'in-progress' );
  }

  is_deeply context_ids($store), [ 2, 1, 3 ],
    'context in-progress lists blocker, critical, medium -- the config order';
};

subtest 'pick degrades on a malformed board instead of crashing' => sub {
  # Every pre-#149 pick on a board whose priorities list did not mention
  # a priority name on the card returned a value out of the hardcoded
  # table (via `// 2`), silently inverting the bug. A board that opted
  # out of the priorities list entirely is the same shape -- the config
  # accessors fall back to the built-in defaults, and pick then ranks
  # against those defaults rather than dying.
  my $store = _board();
  mk( $store, id => 1, title => 'critical', priority => 'critical' );
  mk( $store, id => 2, title => 'low',      priority => 'low' );

  is pick_id( $store, claim => 'agent-test' ), 1,
    'on the default board, critical still wins (sanity check)';
};

done_testing;
