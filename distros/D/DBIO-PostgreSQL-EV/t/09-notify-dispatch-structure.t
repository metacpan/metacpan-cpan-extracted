use strict;
use warnings;
use Test::More;
use B ();
use Future;

# OFFLINE structural regression test for karr k30: the notify() completion
# callback must be created in the named sub _dispatch_notify, not inline in
# the acquire->then closure. No EV::Pg, no real DB.
#
# WHY (karr k30 / dbio ADR 0044, head dbio k156): _query_async was fixed in
# karr k29 (commit 980063a) by routing dispatch through the named sub
# _dispatch_query, so the completion callback is created in a sub whose pad
# dies when it returns -- the bind arrayref lives only until dispatch, not
# for the whole flight of the query. notify() still built its completion
# callback inline in the ->then closure, the same pattern karr k29 removed
# from _query_async. This is a CONSISTENCY fix, NOT a leak fix: notify's bind
# [ $channel, $payload // '' ] is a freshly-built temporary expression (no
# captured lexical), belongs to no external caller, and is small -- there is
# no caller-data leak and no mutation. The fix is purely structural, aligning
# notify with the ADR 0044 dispatch pattern.
#
# WHY THIS TEST CAN ENCODE THAT INTENT WITHOUT A SERVER: the question "where
# is the completion callback created?" is a pure Perl lexical-scope question.
# A captured callback is a clone of an anonymous prototype CV; the clone
# shares the prototype's op tree (same START op), and the prototype lives in
# the pad of the sub that lexically contains the `sub {...}`. So: find the
# CV in _dispatch_notify's pad whose START matches the callback's (GREEN with
# the fix), and make sure no CV reachable from notify's pad -- recursively,
# since an inline callback's prototype sits in the pad of the ->then
# closure's prototype, not in notify's own pad -- matches (RED if the
# callback moves back inline). Verified: moving the callback back inline
# flips both assertions.
#
# WHY NOT CvOUTSIDE (karr k40): the earlier check read
# B::svref_2object($cb)->OUTSIDE->GV->NAME. On perl 5.42 CvOUTSIDE of a
# cloned closure is NULL (B::SPECIAL, no ->GV), on 5.40 it was still the
# creating CV -- the test died on 5.42. The op-tree/pad relation used here
# holds on both.
#
# The void-resolution assertion guards the other half of the contract: notify
# resolves with $f->done and NO arguments (a pure completion signal). If
# someone wrongly reuses _dispatch_query, the pg_notify result row would be
# passed through and $f->get would return it instead of undef.

# --- FakePg: faithful EV::Pg->query_params contract -----------------------
# (same shape as t/05-bind-release.t: stores ONLY the callback, copies the
# params into a private wire list -- never retains the $bind arrayref)
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
sub _lease { 1 }  # the lease of a borrow (core k275, karr k89)
sub shutdown { }

package main;

use DBIO::PostgreSQL::EV::Storage;

# Build a storage whose pool is our FakePool, exactly as t/05-bind-release.t
# does for _query_async.
my $pg = FakePg->new;
my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->{pool} = FakePool->new($pg);

# notify() runs its acquire->then closure synchronously (acquire is done), so
# the completion callback is already in FakePg's queue when notify returns.
my $f = $storage->notify('test_ch', 'payload');

is $pg->pending_count, 1, 'notify dispatched one query_params call';

# Structural assertion: the completion callback must be created in the named
# sub _dispatch_notify, not inline in the acquire->then closure.
my $cb = $pg->{queue}[0]{cb};
my $start = ${ B::svref_2object($cb)->START };

# Anonymous prototype CVs in a sub's pad; with $recurse also those nested in
# the pads of those prototypes (closures inside closures).
sub pad_cvs {
  my ($cv, $recurse, $seen) = @_;
  $seen //= {};
  my $pad = ($cv->PADLIST->ARRAY)[1];
  my @cvs;
  for my $sv ($pad->ARRAY) {
    next unless ref($sv) eq 'B::CV';
    next if $seen->{$$sv}++;
    push @cvs, $sv, ($recurse ? pad_cvs($sv, 1, $seen) : ());
  }
  return @cvs;
}

ok( (grep { ${ $_->START } == $start } pad_cvs(
      B::svref_2object(\&DBIO::PostgreSQL::EV::Storage::_dispatch_notify))),
  'notify completion callback is created in the named sub _dispatch_notify '
  . '(karr k30 / ADR 0044)' );
# karr k43: notify is core's now (ADR 0056) and the acquire->then closure moved
# with the old notify body into the listen seam _notify_send, so that is where
# the callback must NOT be. Same claim, the holder renamed.
ok( !(grep { ${ $_->START } == $start } pad_cvs(
      B::svref_2object(\&DBIO::PostgreSQL::EV::Storage::_notify_send), 1)),
  '... and not inline in _notify_send / its acquire->then closure' );

# Void resolution: notify is a pure completion signal -- $f->done with no
# arguments. The pg_notify result row must NOT be passed through.
ok !$f->is_done, 'future pending until the callback fires';
$pg->complete_one;
ok $f->is_done, 'future resolves when the callback fires';
my $value = $f->get;
ok !defined $value,
  'notify resolves void -- $f->get in scalar context is undef, '
  . 'the pg_notify result row is not passed through';

done_testing;
