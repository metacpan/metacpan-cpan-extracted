use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);

use DBIO::Forked::Storage;

# --- Mock driver: a sync storage whose CRUD returns fixed data, and a schema
# --- whose ->storage hands it back. No DBI, no real database. This exercises
# --- the full Model A path: fork -> inherited sync CRUD -> Storable -> Future.

{
  package t::Mock::Storage;
  sub new { bless {}, shift }
  sub select { shift; return ([ 1, 'Alice' ], [ 2, 'Bob' ]) }
  sub insert { shift; return ([ 99 ]) }
  sub update { die "update boom\n" }   # error-path op

  package t::Mock::Schema;
  sub new { my ($c, $storage) = @_; bless { storage => $storage }, $c }
  sub storage { $_[0]->{storage} }
}

my $schema  = t::Mock::Schema->new(t::Mock::Storage->new);
my $storage = DBIO::Forked::Storage->new($schema);

# --- success roundtrip ------------------------------------------------------
{
  my $f = $storage->select_async('artist');
  isa_ok($f, 'DBIO::Forked::Future', 'select_async returns a Forked::Future');
  is_deeply(
    [ $f->get ],
    [ [ 1, 'Alice' ], [ 2, 'Bob' ] ],
    'select_async roundtrips rows through a real fork',
  );
  ok($f->is_ready, 'future is_ready after get');
  is_deeply([ $f->get ], [ [ 1, 'Alice' ], [ 2, 'Bob' ] ], 'get is idempotent');
}

# --- a second CRUD op (insert) ----------------------------------------------
{
  my $f = $storage->insert_async('artist', { name => 'Carol' });
  is_deeply([ $f->get ], [ [ 99 ] ], 'insert_async roundtrips its result');
}

# --- EOF-clean non-blocking is_ready: poll until the child finishes ----------
{
  my $f = $storage->select_async('artist');
  my $tries = 0;
  while (!$f->is_ready && $tries++ < 2000) {
    select undef, undef, undef, 0.005;   # 5ms tick, no event loop
  }
  ok($f->is_ready, 'is_ready becomes true (EOF) without blocking');
  is_deeply([ $f->get ], [ [ 1, 'Alice' ], [ 2, 'Bob' ] ], 'get after is_ready');
}

# --- error path: a die() in the child surfaces as an exception from get ------
{
  my $f = $storage->update_async('artist', { x => 1 });
  my @r = eval { $f->get };
  ok($@, 'child error propagates as an exception from get');
  like($@, qr/update boom/, 'the child error message is preserved');
  ok($f->is_failed, 'is_failed is true for an errored future');
}

# --- no zombies left behind --------------------------------------------------
{
  my $reaped = waitpid(-1, WNOHANG);
  ok($reaped == -1 || $reaped == 0, "no unreaped child processes left (got $reaped)");
}

done_testing;
