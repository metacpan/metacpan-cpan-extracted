use strict;
use warnings;
use Test::More;
use Scalar::Util 'weaken';
use Future;

# OFFLINE regression test for karr #11 / CurtisPoe review #5 N1:
# "async bind-value leak". No EV::Pg, no real DB.
#
# WHAT THE TICKET FEARED (ported from the sync DBI driver's contract):
#   bind values issued through the async pool are retained on an in-flight
#   future / per-pool cache, so (1) a re-issued query could see stale binds
#   and (2) memory grows with total binds ever issued, not with outstanding
#   queries.
#
# WHAT THIS DRIVER ACTUALLY DOES: it bypasses DBI and hands each freshly-built
# @bind arrayref straight to EV::Pg->query_params, which serializes the params
# into libpq's wire buffer. The completion closure in _query_async /
# _query_async_pinned captures $f, $self, $pg, $sql -- but NOT $bind. So the
# ONLY live Perl reference to the bind arrayref is the lexical in the issuing
# scope, which dies when that scope returns. There is no storage/pool cache
# that accumulates binds (the pool's _ready table holds readiness Futures
# only). The "bind-clearing contract" is therefore lexical lifetime, not an
# explicit wipe -- and there is nothing to leak.
#
# WHY THIS TEST CAN ENCODE THAT INTENT WITHOUT A SERVER: the bind-retention
# question is a pure Perl reference-graph question. FakePg below faithfully
# emulates libpq's query_params contract -- it COPIES the params into private
# storage and retains ONLY the callback, never the $bind arrayref. We run the
# real _query_async / _query_async_pinned code through it, hold a weak ref to
# each bind arrayref, let the strong issuing-scope lexical drop, and assert the
# weak ref is gone. This FAILS the moment _query_async's closure starts closing
# over $bind, or the storage/pool starts stashing it anywhere keyed by query --
# i.e. exactly the leak shape the ticket describes. (Verified by hand: a variant
# whose completion closure captures $bind keeps every weak ref alive here.)

# --- FakePg: faithful EV::Pg->query_params contract -----------------------
#
# Stores ONLY the callback (like libpq keeping a pending-result slot), and
# copies the params into a private string list (like PQsendQueryParams
# serializing them onto the wire). It deliberately does NOT keep the $bind
# arrayref, so anything that survives must be held by DBIO's own code.
package FakePg;
sub new { bless { queue => [] }, shift }
sub query_params {
  my ($self, $sql, $bind, $cb) = @_;
  my @serialized = map { defined $_ ? "$_" : undef } @$bind;
  push @{ $self->{queue} }, { cb => $cb, wire => \@serialized };
}
sub pending_count { scalar @{ $_[0]->{queue} } }
# Complete the oldest in-flight query, firing its callback like a finished
# libpq result. The dequeued entry (cb + wire copy) is dropped here.
sub complete_one {
  my $self = shift;
  my $entry = shift @{ $self->{queue} } or return;
  $entry->{cb}->([[1]], undef);
}

# --- FakePool: hands back the FakePg, no per-query bookkeeping -------------
package FakePool;
sub new { bless { pg => $_[1] }, $_[0] }
sub acquire { Future->done($_[0]->{pg}) }
sub release { }   # no-op: the pool stores the connection, never the bind
sub shutdown { }

package main;

use DBIO::PostgreSQL::EV::Storage;

# Build a storage whose pool is our FakePool. _query_async acquires from the
# pool and calls query_params on whatever connection it gets.
sub new_storage {
  my $pg = FakePg->new;
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->{pool} = FakePool->new($pg);
  return ($storage, $pg);
}

# --- 1. single pooled query: bind released once the future completes -------
{
  my ($storage, $pg) = new_storage;

  my $weak;
  my $f;
  {
    my $bind = [ 'payload' x 64 ];   # a large-ish bind, like the repro
    weaken($weak = $bind);
    $f = $storage->_query_async('SELECT $1', $bind);
  }   # the issuing-scope strong lexical dies here

  $pg->complete_one;
  $f->get;

  ok !defined $weak,
    'pooled query: bind arrayref is freed after the future completes '
    . '(completion closure does not retain it)';
}

# --- 2. pinned (transaction) query: same release contract ------------------
{
  my ($storage, $pg) = new_storage;

  my $weak;
  my $f;
  {
    my $bind = [ 'txn-payload' x 64 ];
    weaken($weak = $bind);
    $f = $storage->_query_async_pinned($pg, 'SELECT $1', $bind);
  }

  $pg->complete_one;
  $f->get;

  ok !defined $weak,
    'pinned (txn) query: bind arrayref is freed after completion too';
}

# --- 3. many in-flight queries: each bind released, no accumulation --------
#
# This is the ticket's core repro: N concurrent async queries with bind
# payloads. With a faithful libpq contract, NONE of the bind arrayrefs should
# survive their issuing scope -- the wire copy lives in FakePg, but the Perl
# arrayref is not held by DBIO. So even with all N still in-flight, every weak
# ref is already gone. (If DBIO leaked via a closure capture or a per-query
# cache, the count here would be N, then stay N after completion -- a growing
# leak proportional to total binds issued, exactly issue N1.)
{
  my ($storage, $pg) = new_storage;

  my $N = 8;
  my @weak;
  my @f;
  for my $i (1 .. $N) {
    my $w;
    {
      my $bind = [ "row$i" x 32 ];
      weaken($w = $bind);
      push @f, $storage->_query_async("SELECT \$1 -- $i", $bind);
    }
    push @weak, $w;
  }

  is $pg->pending_count, $N, "all $N queries are in-flight at once";

  my $held_inflight = grep { defined } @weak;
  is $held_inflight, 0,
    "no bind arrayref is retained while $N queries are in-flight "
    . '(no per-pool/per-future bind cache)';

  # Drain them; completion must not resurrect or accumulate any bind.
  for my $i (0 .. $N - 1) {
    $pg->complete_one;
    $f[$i]->get;
  }

  my $held_after = grep { defined } @weak;
  is $held_after, 0,
    "after completing all $N queries, still zero binds held "
    . '(memory bounded by outstanding queries, not total issued)';
}

# --- 4. no _prepared_cache slot on the storage hash ------------------------
#
# _prepared_cache used to be declared (unused) in the constructor and was
# removed as dead code (karr #12). Guard against it being silently reintroduced
# as a per-query stash: the key must not exist on the storage hash even after an
# issued+completed query.
{
  my ($storage, $pg) = new_storage;
  {
    my $bind = [ 'cache-probe' x 16 ];
    my $f = $storage->_query_async('SELECT $1', $bind);
    $pg->complete_one;
    $f->get;
  }
  ok !exists $storage->{_prepared_cache},
    'no _prepared_cache slot -- nothing stashes binds per query';
}

done_testing;
