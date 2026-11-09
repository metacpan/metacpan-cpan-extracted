package DBIO::MySQL::EV::Future;
# ABSTRACT: A Future whose get waits on the EV loop

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'Future';

use Carp ();
use Scalar::Util ();
use EV ();


sub await {
  my $self = shift;
  until ($self->is_ready) {
    # Failing the queued caller this waits for settles this Future, unless its
    # chain catches the failure. Asked again when the loop has run dry: the
    # answer to the last statement in flight is what makes the wait hopeless.
    next if $self->_refuse_queued;
    EV::run(EV::RUN_ONCE())
      or $self->is_ready
      or $self->_refuse_queued
      or $self->_dry_loop;
  }
  return $self;
}

# The loop is dry and nothing settled the Future: it dies, and a caller queued
# for a connection that this Future waits for is taken out of the queue with
# it (karr k69). Left queued, the next release would hand a connection to a
# caller nobody waits for any more, and the pool would lose it.
sub _dry_loop {
  my ($self) = @_;
  my $msg = "$self is pending and the EV loop has nothing left that could complete it";
  $self->_drop_queued($msg);
  Carp::croak($msg);
}


# The mark is kept as Future's user data (udata, Future 0.49), never in the
# instance itself: [ $waiter, $pool ], both weak -- the pool holds the waiter,
# and the waiter and everything chained off it share the one arrayref.
my $QUEUED = 'dbio_mysql_ev_queued';

sub new {
  my $proto = shift;
  my $self  = $proto->SUPER::new(@_);
  if (ref $proto and my $queued = $proto->udata($QUEUED)) {
    $self->set_udata($QUEUED => $queued)
      if $queued->[0] && !$queued->[0]->is_ready;
  }
  return $self;
}


sub _queued_in {
  my ($self, $pool) = @_;
  my $queued = [ $self, $pool ];
  Scalar::Util::weaken($_) for @$queued;
  return $self->set_udata($QUEUED => $queued);
}

# Refuse the wait when this Future waits for a caller queued for a pooled
# connection, and no connection of that pool can come back before a callback
# that is running returns: take the caller out of the queue and fail it. True
# when it did. Nothing else is touched -- a queued caller nobody waits for
# stays queued, and is served once those callbacks have returned.
sub _refuse_queued {
  my ($self) = @_;
  my $queued = $self->udata($QUEUED) or return 0;
  my ($waiter, $pool) = @$queued;
  return 0 unless $waiter && !$waiter->is_ready && $pool;
  return 0 unless $pool->_mysql_held_by_callbacks;
  return 0 unless $pool->_withdraw_waiter($waiter);
  $waiter->fail(_queued_refusal($pool->max_size));
  return 1;
}

# Take the caller queued for a connection that this Future waits for out of the
# pool's queue and fail it with $reason, for a wait that dies instead of
# ending. True when there was one. Unlike _refuse_queued it asks nothing of the
# pool's state: the wait is hopeless already.
sub _drop_queued {
  my ($self, $reason) = @_;
  my $queued = $self->udata($QUEUED) or return 0;
  my ($waiter, $pool) = @$queued;
  return 0 unless $waiter && !$waiter->is_ready && $pool;
  return 0 unless $pool->_withdraw_waiter($waiter);
  $waiter->fail($reason);
  return 1;
}

sub _queued_refusal {
  my ($size) = @_;
  return 'Blocking wait refused: this blocking call is queued for a connection '
    . "of a pool of $size, and every one of them is held by a callback this "
    . 'call runs inside -- the coderef of a txn_do, or a then on a statement of '
    . 'a transaction -- which gives its connection back only after it has '
    . 'returned, so waiting here would deadlock. To run on the connection of '
    . 'the transaction, use its context: $ctx->select_async, '
    . '$ctx->insert_async, ..., chained with ->then. For a statement outside '
    . 'the transaction, use the *_async methods of the storage and chain with '
    . '->then instead of blocking, or raise pool_size';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::EV::Future - A Future whose get waits on the EV loop

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The L<Future> class of L<DBIO::MySQL::EV::Storage> (its
L<DBIO::MySQL::EV::Storage/future_class>). Every Future this transport hands
out is settled from the L<EV> loop -- by an idle watcher that follows the
L<EV::MariaDB> callback of its statement, or by an L<EV> timer -- so waiting
for one means running that loop. A plain L<Future> cannot: its C<get> on a pending instance calls C<await>, which L<Future> leaves
to subclasses and by default dies with I<"... is not yet complete and does not
provide -E<gt>await">. This class supplies it, the pattern of
L<IO::Async::Future> and the L<Future::IO> implementations.

It is what makes the blocking storage methods work -- C<select>, C<insert>,
C<txn_do>, C<deploy>, ..., each C<< $self->X_async(@_)->get >> -- and it
makes C<get> on any other Future of this transport block the same way
(ADR 0001). It works inside a callback of one of the transport's own
connections too -- a C<then> on its Futures, the coderef of C<txn_do>: those
run from the idle watcher, outside every callback of the L<EV::MariaDB> handle
(ADR 0001 addendum). What
it still refuses is a wait for a pooled connection that cannot come back while
the callbacks it runs inside hold every one of them (L</await>).

Nothing else changes. Everything but L</await> and L</new> is L<Future>'s own,
and its combinators keep the class: C<then> and friends on a pending instance,
and C<needs_all> / C<wait_any> and the other convergents over instances of
this class, return instances of this class.

=head1 METHODS

=head2 await

  $f = $f->await;

Runs the EV loop one iteration at a time (C<< EV::run(EV::RUN_ONCE) >>) until
the Future is ready, then returns it; L<Future/get> calls it for a pending
Future.

It may be called from inside an EV callback: libev runs loops recursively, so
the nested run serves every watcher, the caller's own ones included, and
returns to the callback once the Future is ready.

B<It waits inside a callback of the transport's own connections.> A C<then> or
C<on_done> on its Futures and the coderef of C<txn_do> / C<txn_do_async> run
from the idle watcher that settles the Future
(L<DBIO::MySQL::EV::QueryExecutor/execute>), not from inside the
L<EV::MariaDB> callback that delivered the answer, so the handle's callback
depth is 0 there and a statement they send -- with or without bind values -- is
sent at once. A blocking call waiting for it returns. (L<EV::MariaDB> only
queues a C<query> issued while a callback of its handle runs and sends it when
that callback returns; the transport's Futures settle outside it.) The nested
loop serves every watcher, the idle
watcher included, so the statements of other connections settle meanwhile and
their callbacks run in the order the handles answered.

B<It refuses a wait for a pooled connection that cannot come back> while the
wait lasts (ADR 0001 addendum). A blocking call on the storage
takes a connection from the pool, and is queued when every one is checked out.
Made inside a C<txn_do> coderef -- C<< $storage->select >> where
C<< $ctx->select_async >> was meant -- it needs another connection than the
transaction's, and the transaction gives its own back only after the coderef
has returned and C<COMMIT> or C<ROLLBACK> has been answered. With a pool of
one, or with every connection held by a transaction this call is nested in,
the queued call is never served.

C<await> therefore asks, on entry and around every iteration of the loop,
whether the Future it waits for is chained off a caller queued for a
connection (L</new>), and whether every connection of that pool is held by a
callback that is running: a callback of its own on the call stack, and no
statement in flight (L<DBIO::MySQL::EV::Pool/_mysql_held_by_callbacks>). If
so, it takes the caller out of the pool's queue and fails it with
I<"Blocking wait refused: ...">, naming the size of the pool and what to do
instead: the transaction context's C<*_async> methods chained with C<then>,
to run on the transaction's connection; the storage's C<*_async> methods
chained with C<then>, for a statement that belongs outside it; or a larger
C<pool_size>. The failure reaches the waiting Future through its chain, so
C<get> dies with it.

The other wait that dies rather than ends -- the loop that has run dry with
nothing left to settle the Future -- takes such a queued caller out of the
queue as well, and fails it, before it dies. It would otherwise
stay queued: the next C<release> would hand its connection to a caller nobody waits for, and the
pool would lose that connection.

=over 4

=item * The refused call does not run, then or later. It never had a
connection; taken out of the queue, it gets none. A refused C<insert> writes
nothing. In a C<txn_do> coderef the refusal fails the coderef, so the
transaction is rolled back, and its connection goes back to the pool.

=item * A wait that can end is not refused: one for a connection that is idle
or still connecting, that a statement in flight will give back, or that is
held by a transaction none of whose callbacks is running -- and any wait at
top level or in a plain EV callback, where no callback of a connection runs.
A connection whose callback is running but that still has a statement in
flight keeps the wait going; the wait is refused when that statement has been
answered and nothing else gives a connection back.

=item * Only the caller that is waited for is failed. A call queued for the
connection without anybody blocking on it -- an unawaited
C<< $storage->select_async >> in the coderef -- stays queued and runs once the
transaction has ended.

=item * It sees the queued caller through L</new>, that is, in a Future
chained off it with C<then> and its siblings, or in a convergent whose first
component is. A blocking wait on a Future that reaches a queued caller another
way -- a C<then> callback that returned the Future of a storage call, on a
Future that was pending before -- is not refused and waits as before.

=item * A transaction whose coderef has returned a Future that itself depends
on a call queued for the transaction's connection --
C<< txn_do(sub { $storage->select_async(...) }) >> with a pool of one -- is
not a blocking wait inside a callback, and is not detected: the transaction
waits for the call and the call for the transaction's connection.

=back

It B<dies instead of spinning> when the loop has nothing left that could
settle the Future: an iteration after which no watcher that keeps the loop
alive is active -- no statement in flight, no timer -- while the Future is
still pending. Such a Future would never become ready (EV answers at once when
there is nothing to wait for, so a plain C<until> loop would burn a core
forever). A watcher that is active does keep it waiting, as it should; a
Future that nothing is going to settle while, say, a listen poll timer runs
therefore waits as long as that timer does, like an L<IO::Async::Future>
would.

=head2 new

  $f = DBIO::MySQL::EV::Future->new;
  $f = $other->new;

L<Future/new>. Called on an instance that waits for a caller queued for a
pooled connection (L</_queued_in>), the new Future waits for that caller too:
this is how L<Future> makes the Future of every C<then> and its siblings on a
pending instance, and the one a convergent (C<needs_all>, ...) returns. So
everything chained off a queued caller knows it -- the Future a blocking call
finally waits on, which is what L</await> looks at. A queued caller that has
been served, or failed, is no longer carried along.

=head2 _queued_in

  $waiter->_queued_in($pool);

Mark this pending Future as the one a caller queued for a connection of
C<$pool> waits on. L<DBIO::MySQL::EV::Pool/_new_waiter> calls it on the Future
it hands to L<DBIO::Storage::PoolBase/acquire>. Returns the Future.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
