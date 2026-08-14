use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;

# Ticket #90. The id counter lives in refs/karr/meta/next-id, and `karr
# materialize` copies it into the file view because kanban-md validates it
# (#60) -- but `karr import` threw the view's copy away and re-seeded from the
# highest card it could see.
#
# That is only safe while the view's counter can never be ahead of its cards,
# and it can: kanban-md keeps next_id after a card is gone, on purpose. Its own
# rule for this value is max(stored, highest id + 1), never lower -- see
# syncNextID in internal/task/consistency.go -- so a kanban-md board that ever
# lost a card carries a counter past its highest id, and karr walked it back
# and handed the next `karr create` an id kanban-md had already retired.
#
# Verified against a kanban-md binary built from the reference implementation:
# three creates then removing the third card leaves next_id at 4 with 002 as
# the highest card, and kanban-md holds it at 4 across further loads.
#
# The counter moves forward across the bridge in both directions and never
# backwards. t/58 pins the same seeding for a view with no config.yml at all,
# where there is no counter to read and nothing here changes.

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  return $repo;
}

# A minimal file view: cards with the given ids, plus a config.yml carrying the
# counter -- the shape kanban-md leaves behind.
sub _write_view {
  my ( $repo, $next_id, @ids ) = @_;
  my $tasks = path($repo)->child('tasks');
  $tasks->mkpath;
  for my $id (@ids) {
    App::karr::Task->new(
      id       => $id,
      title    => "Imported task $id",
      status   => 'backlog',
      priority => 'medium',
      class    => 'standard',
    )->save($tasks);
  }
  path($repo)->child('config.yml')->spew_utf8( <<"END" );
version: 1
board:
  name: Bridged Board
next_id: $next_id
END
  return $tasks;
}

sub _store {
  my ($repo) = @_;
  return App::karr::BoardStore->new( git => App::karr::Git->new( dir => $repo ) );
}

subtest 'a view counter ahead of its cards is adopted, not walked back' => sub {
  my $repo  = _init_repo();
  my $store = _store($repo);
  # What a kanban-md board looks like once it has lost a card: cards 1 and 2,
  # counter already at 9 because ids 3..8 were handed out and are gone.
  _write_view( $repo, 9, 1, 2 );

  $store->serialize_from( path($repo)->stringify );

  is( $store->peek_next_id, 9,
    'the counter the other tool reached survives the crossing' );
  is( $store->allocate_next_id, 9,
    'so the next created task cannot collide with a retired id' );
};

subtest 'a view counter behind its cards is still seeded past them' => sub {
  my $repo  = _init_repo();
  my $store = _store($repo);
  # A hand-edited or stale view: the config says 2 but there are cards up to 5.
  _write_view( $repo, 2, 1, 2, 3, 4, 5 );

  $store->serialize_from( path($repo)->stringify );

  is( $store->peek_next_id, 6,
    'the highest card still sets the floor when the view lags behind it' );
};

subtest 'a counter already ahead of the view is left alone' => sub {
  my $repo  = _init_repo();
  my $store = _store($repo);
  $store->set_next_id(20);
  _write_view( $repo, 9, 1, 2 );

  $store->serialize_from( path($repo)->stringify );

  is( $store->peek_next_id, 20,
    'import never lowers a healthy board counter to match the view' );
};

subtest 'a next_id the view cannot mean is ignored' => sub {
  my $repo  = _init_repo();
  my $store = _store($repo);
  _write_view( $repo, 3, 1, 2 );
  # Replace the counter with something that is not one.
  my $config = path($repo)->child('config.yml');
  ( my $yaml = $config->slurp_utf8 ) =~ s/^next_id: 3$/next_id: "not a number"/m
    or die 'fixture no longer carries next_id';
  $config->spew_utf8($yaml);

  $store->serialize_from( path($repo)->stringify );

  is( $store->peek_next_id, 3,
    'the cards alone decide when the view\'s counter is unusable' );
};

done_testing;
