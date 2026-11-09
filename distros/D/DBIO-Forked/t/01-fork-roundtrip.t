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

# --- update/delete resolve the affected-row COUNT, a plain scalar -------------
# A real DBI storage's update()/delete() return ($rv, $sth, @bind) in list
# context and $rv in scalar context (DBIO::Storage::DBI::_execute). The child
# must ask for the count, or the statement handle -- full of code refs -- goes
# into Storable and the Future fails with "cannot serialize" although the
# statement ran. The contract (DBIO::Storage::Async::update_async, which
# Row::update_async relies on for "row not found") is the count alone.
{
  package t::Mock::DBI::Storage;
  sub new { bless {}, shift }
  sub update { shift; return wantarray ? (3, sub { 'sth' }, 'bind') : 3 }
  sub delete { shift; return wantarray ? (1, sub { 'sth' }, 'bind') : 1 }

  package main;
  my $dbi_schema = t::Mock::Schema->new(t::Mock::DBI::Storage->new);   # held: the backend keeps it weakly
  my $dbi = DBIO::Forked::Storage->new($dbi_schema);

  my @upd = eval { $dbi->update_async('artist', { x => 1 }, { y => 2 })->get };
  is($@, '', 'update_async whose sync update returns a statement handle in list context does not fail');
  is_deeply(\@upd, [ 3 ], 'update_async resolves with the affected-row count alone');

  my @del = eval { $dbi->delete_async('artist', { y => 2 })->get };
  is($@, '', 'delete_async whose sync delete returns a statement handle in list context does not fail');
  is_deeply(\@del, [ 1 ], 'delete_async resolves with the affected-row count alone');
}

# --- no zombies left behind --------------------------------------------------
{
  my $reaped = waitpid(-1, WNOHANG);
  ok($reaped == -1 || $reaped == 0, "no unreaped child processes left (got $reaped)");
}

done_testing;
