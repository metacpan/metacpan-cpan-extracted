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
use App::karr::Cmd::List;
use App::karr::Cmd::Pick;

# Ticket #91: `karr list --sort priority` and `karr pick` disagreed about
# which end of the list is urgent. The #66 fix had made the list follow the
# config's priority order ascending, like kanban-md's compareTasks
# (internal/board/sort.go:29 -- PriorityIndex(a) < PriorityIndex(b)), so with
# the default priorities [low medium high critical] the least urgent task sat
# on top, while pick ranks critical first via App::karr::Config->
# priority_order. Both were defensible alone; together they were a trap.
#
# karr now deliberately deviates from kanban-md here: the list reads the
# config's priority list most-urgent-last and sorts descending, so its top
# line is the task pick would hand out. This file pins that agreement and
# fails on the pre-#91 comparator, which answered [2 4 3 1] below.

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or die "git init failed";
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
  return $repo;
}

# A default board -- the store's merged defaults supply the priorities
# [low medium high critical] -- holding one open task per priority, with ids
# deliberately not in urgency order.
sub _board {
  my $repo = _init_repo();
  my $git  = App::karr::Git->new( dir => $repo );
  $git->write_ref( 'refs/karr/config',
    Dump( { version => 1, board => { name => 'T' } } ) );
  my $store = App::karr::BoardStore->new( git => $git );
  my %prio = ( 1 => 'critical', 2 => 'low', 3 => 'high', 4 => 'medium' );
  for my $id ( sort { $a <=> $b } keys %prio ) {
    $store->save_task(
      App::karr::Task->new(
        id       => $id,
        title    => "$prio{$id} task",
        status   => 'todo',
        priority => $prio{$id},
        class    => 'standard',
      )
    );
  }
  return $store;
}

# The ids in the order `karr list` rendered them. Same capture as
# t/79-list-sort-semantics.t: the :encoding(UTF-8) layer bin/karr installs
# (App::karr::Encoding::enable_std_utf8), because reopening STDOUT drops it.
sub list_ids {
  my ( $store, %opt ) = @_;
  my $cmd = App::karr::Cmd::List->new( store => $store, %opt );
  my $buf = '';
  {
    local *STDOUT;
    open STDOUT, '>:encoding(UTF-8)', \$buf or die $!;
    $cmd->execute( [], [] );
  }
  return [ $buf =~ /^#(\d+)/mg ];
}

subtest 'list --sort priority opens with the most urgent task' => sub {
  my $store = _board();
  is_deeply list_ids( $store, sort => 'priority' ), [ 1, 3, 4, 2 ],
    'critical, high, medium, low -- the config order read most-urgent-first';
};

subtest '--reverse turns that into least-urgent-first' => sub {
  my $store = _board();
  is_deeply list_ids( $store, sort => 'priority', reverse => 1 ), [ 2, 4, 3, 1 ],
    'low, medium, high, critical';
};

subtest 'pick takes the tasks in exactly the list order' => sub {
  my $store = _board();
  my @picked;
  for my $round ( 1 .. 4 ) {
    my $cmd = App::karr::Cmd::Pick->new( store => $store, claim => 'agent-test' );
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
    is $err, '', "pick round $round does not die" or diag "died with: $err";
    my ($id) = $buf =~ /^Picked task (\d+):/m;
    push @picked, $id;
  }
  is_deeply \@picked, [ 1, 3, 4, 2 ],
    'pick order is the list order: the top line is what pick would take'
    or diag 'pre-#91 the list opened with task 2 (low) while pick took task 1 (critical)';
};

done_testing;
