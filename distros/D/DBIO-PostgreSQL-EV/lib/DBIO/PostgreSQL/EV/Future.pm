package DBIO::PostgreSQL::EV::Future;
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
    if (my $conn = _delivering_with_more_due()) {
      my $refusal = _refusal($conn);
      # A caller still queued for a connection has nothing on the wire to
      # complete: it leaves the queue, whatever the wait ends with (karr k85).
      $self->_withdraw_queued($refusal);
      # What is on the wire completes: the dying caller drops this Future, so
      # keep its chain running.
      $self->retain;
      Carp::croak($refusal);
    }
    # Failing the queued caller this waits for settles this Future, unless its
    # chain catches the failure. Asked before every iteration, as the refusal
    # above is: the pool is not what it was before the last one.
    next if $self->_refuse_queued;
    unless (EV::run(EV::RUN_ONCE()) or $self->is_ready) {
      my $dry = "$self is pending and the EV loop has nothing left that could complete it";
      $self->_withdraw_queued($dry);   # karr k86
      Carp::croak($dry);
    }
  }
  return $self;
}

sub _refusal {
  my ($conn) = @_;
  return 'Blocking wait refused: this blocking call runs inside a callback of '
    . 'an EV::Pg connection that has ' . ($conn->pending_count - 1)
    . ' more result(s) due, and EV::Pg would hand the next of them to the '
    . 'callback that is still running, then spin. Use the *_async methods and '
    . 'chain with ->then instead (in a txn_do coderef: $ctx->select_async, '
    . '$ctx->insert_async, ...)';
}


# The mark is kept as Future's user data (udata, Future 0.49), never in the
# instance itself: [ $waiter, $pool ], both weak -- the pool holds the waiter,
# and the waiter and everything chained off it share the one arrayref.
my $QUEUED = 'dbio_postgresql_ev_queued';

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
# that is running returns: take the caller out of the queue and fail it (karr
# k71). True when it did. Failed, not cancelled, and taken out first: a caller
# left in the queue is handed the connection once the callback has returned,
# and the call its caller was told had failed runs after all. Nothing else is
# touched -- a queued caller nobody waits for stays queued, and is served once
# those callbacks have returned.
sub _refuse_queued {
  my ($self) = @_;
  my ($waiter, $pool) = $self->_queued_caller or return 0;
  return 0 unless $pool->_pg_held_by_callbacks;
  return $self->_withdraw_queued(_queued_refusal($pool->max_size, $pool->_pg_opening));
}

# The caller this Future waits for and the pool it is queued in, while it is
# queued and pending; nothing otherwise.
sub _queued_caller {
  my ($self) = @_;
  my $queued = $self->udata($QUEUED) or return;
  my ($waiter, $pool) = @$queued;
  return unless $waiter && !$waiter->is_ready && $pool;
  return ($waiter, $pool);
}

# The one way a wait that is given up takes the caller it waits for out of the
# pool (karr k71, k85, k86): out of the queue first, then failed with $message.
# A caller that has no connection yet and is not taken out would be handed one
# when the next is released, and run after its caller was told the wait had
# failed -- or, its chain dropped with the dying caller, lose the connection
# and wedge the pool. True when it was queued and is out. A callback that dies
# as the caller is failed does not undo that; it is warned about.
sub _withdraw_queued {
  my ($self, $message) = @_;
  my ($waiter, $pool) = $self->_queued_caller or return 0;
  return 0 unless $pool->_withdraw_waiter($waiter);
  eval { $waiter->fail($message); 1 }
    or warn "DBIO::PostgreSQL::EV: a callback died as a refused blocking call was failed: $@";
  return 1;
}

# $opening: how many of the pool's connections a spawn that is running holds
# (karr k88). Without one the callbacks on the call stack hold them all, and
# the text is that of karr k71.
sub _queued_refusal {
  my ($size, $opening) = @_;
  my $queued = 'Blocking wait refused: this blocking call is queued for a '
    . "connection of a pool of $size, and ";
  return $queued . 'every one of them is held by a callback this '
    . 'call runs inside -- a then on a statement, or the coderef of a txn_do '
    . '-- which gives its connection back only after it has returned, so '
    . 'waiting here would never end. Use the *_async methods of the storage '
    . 'and chain with ->then instead of blocking (to run on the connection of '
    . 'a transaction, use its context: $ctx->select_async, $ctx->insert_async, '
    . '...), or raise pool_size'
    unless $opening;
  return $queued . 'none of them can come back while it waits: the pool is '
    . "opening $opening of them in a call this one runs inside -- this call "
    . 'was made where the AccessBroker is asked for connect info, or in a '
    . 'callback the EV loop ran while that, or the replay of on_connect_do / '
    . 'on_connect_call, waited -- and a connection being opened is handed out '
    . 'only after that call has returned; any other is held by a callback '
    . 'this call runs inside. Waiting here would never end. Use the *_async '
    . 'methods of the storage and chain with ->then instead of blocking (an '
    . 'AccessBroker cannot wait for the storage it answers), or raise '
    . 'pool_size';
}

# The connections one of this transport's callbacks is being delivered for
# right now, by refaddr: set by the frame _delivering hands out, for exactly as
# long as that callback runs.
my %DELIVERING;

# Called first thing in every callback the storage hands to EV::Pg for $conn;
# the callback keeps the returned frame in a lexical. While the frame lives,
# $conn is delivering; when it goes out of scope -- the callback returns or
# dies -- the previous state is restored, so a callback of the same connection
# nested in another has a frame of its own. Set inside the callback rather than
# by wrapping it, so the callback EV::Pg keeps stays the one created in the
# storage's dispatch sub (karr k29 / k30).
sub _delivering {
  my ($class, $conn) = @_;
  # A callback EV::Pg runs after its connection is gone (global destruction)
  # delivers nothing: no frame, %DELIVERING untouched.
  return unless defined $conn;
  my $key   = Scalar::Util::refaddr($conn);
  my $frame = bless [ $key, $DELIVERING{$key} ], 'DBIO::PostgreSQL::EV::Future::_Frame';
  $DELIVERING{$key} = $conn;
  return $frame;
}

sub DBIO::PostgreSQL::EV::Future::_Frame::DESTROY {
  my ($key, $outer) = @{ $_[0] };
  if (defined $outer) { $DELIVERING{$key} = $outer }
  else                { delete $DELIVERING{$key} }
  return;
}

# A delivering connection with more than the delivering statement pending, or
# undef. EV::Pg counts the delivering callback in pending_count until it
# returns, so anything above one is a result due during a nested loop.
sub _delivering_with_more_due {
  for my $conn (values %DELIVERING) {
    return $conn if $conn && $conn->pending_count > 1;
  }
  return;
}


sub _held_by_callback {
  my ($class, $conn) = @_;
  my $delivering = $DELIVERING{ Scalar::Util::refaddr($conn) } or return 0;
  return $delivering->pending_count > 1 ? 0 : 1;
}


# The connections whose connect actions are being replayed right now, by
# refaddr: counted, so a frame that ends leaves the mark of one still running.
my %REPLAYING;

sub _replaying {
  my ($class, $conn) = @_;
  my $key = Scalar::Util::refaddr($conn);
  $REPLAYING{$key}++;
  return bless \$key, 'DBIO::PostgreSQL::EV::Future::_Replay';
}

sub DBIO::PostgreSQL::EV::Future::_Replay::DESTROY {
  my $key = ${ $_[0] };
  delete $REPLAYING{$key} unless --$REPLAYING{$key} > 0;
  return;
}

sub _held_by_spawn {
  my ($class, $conn) = @_;
  return $REPLAYING{ Scalar::Util::refaddr($conn) } ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::EV::Future - A Future whose get waits on the EV loop

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The L<Future> class of L<DBIO::PostgreSQL::EV::Storage> (its
L<DBIO::PostgreSQL::EV::Storage/future_class>). Every Future this transport
hands out is settled from the L<EV> loop, by an L<EV::Pg> callback, so waiting
for one means running that loop. A plain L<Future> cannot: its C<get> on a
pending instance calls C<await>, which L<Future> leaves to subclasses and by
default dies with I<"... is not yet complete and does not provide
-E<gt>await">. This class supplies it, the pattern of L<IO::Async::Future> and
the L<Future::IO> implementations.

It is what makes the blocking storage methods work -- C<select>, C<insert>,
C<txn_do>, C<deploy>, ..., each C<< $self->X_async(@_)->get >> -- and it makes
C<get> on any other Future of this transport block the same way (ADR 0001).
Inside a callback of one of the transport's own connections it dies instead
(L</await>) where the wait could not end: when it would make L<EV::Pg> hand a
result to the wrong callback and spin, and when it is queued for a pooled
connection while the callbacks it runs inside hold every one of them. The
second it refuses as well inside a connection's opening -- in the
AccessBroker's answer, or in a callback the loop ran while the pool waited for
it or for a connect statement.

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

B<It refuses a wait that could never end> inside a callback of one of this
transport's own connections -- a C<then> or C<on_done> on its Futures, or the
coderef of C<txn_do> / C<txn_do_async>, which runs inside the C<BEGIN>'s
callback on the pinned connection. L<EV::Pg> keeps the callback it is
delivering to at the head of the connection's queue until that callback
returns. A nested loop that reads the next result on the same connection
therefore hands it to that callback a second time instead of to its own, shifts
every later result onto the wrong callback, and then spins inside L<EV::Pg>
with 100% CPU -- no EV timer and no C<alarm> fires there (measured with EV::Pg
0.07; the 0.02 source delivers the same way). The next result is due
whenever more than the delivering statement is pending on that connection: a
statement issued from the callback -- L<EV::Pg> sends it at once, with or
without bind values, so the failure is certain -- or the rest of a pipeline
batch, where it depends on whether the server flushes the next result while
the wait runs.
While one of this transport's callbacks runs for a connection whose
L<EV::Pg/pending_count> is above one, C<await> dies -- on entry, and again
before every iteration of the loop, because such a statement may be issued
while the wait runs -- with I<"Blocking wait refused: ...">, pointing to the
C<*_async> methods. Chain with C<then> there instead of blocking.

In a C<txn_do> coderef this refuses every blocking C<$ctx> method: each sends
its statement on the pinned connection whose C<BEGIN> callback is running. Use
C<< $ctx->select_async >> and its siblings.

What the refusal does and does not do:

=over 4

=item * It cancels nothing. The statement is already on the wire and completes
once the callback has returned.

=item * The refused operation still completes, when it is on the wire. Before
it dies, C<await> keeps the Future it was asked to wait for alive until that is
ready (L<Future/retain>): L<Future> holds a sequence Future only weakly, so the
chain the dying caller drops would otherwise lose its remaining steps -- the
release of a pooled connection among them. A call that is still queued for a
connection has no statement on the wire: it is taken out of the pool's queue
and failed, and does not run (below).

=item * A refused C<txn_do> coderef rolls back cleanly. The coderef dies while
its statement is still running on the pinned connection, and the pinned
connection runs its statements one at a time, so the C<ROLLBACK> core sends
goes out once that statement has its result: C<txn_do> fails with the refusal,
and the connection goes back to the pool IDLE
(L<DBIO::PostgreSQL::EV::Storage/_query_async_pinned>).

=item * It is over-strict in one window: while more results are due on the
connection, every blocking wait is refused, also one that does not depend on
them, and in a pipeline also one the server would have answered in time.

=item * It only knows the callbacks L<DBIO::PostgreSQL::EV::Storage> hands to
L<EV::Pg> to settle its Futures, which are the ones a C<then> chain or a
C<txn_do> coderef runs in. The C<LISTEN> / C<UNLISTEN> on the
dedicated listen connection are among them; the notifications it delivers and
the pool's connect-action replay are not.

=back

A blocking call waiting only on other connections completes, as does one made
from a plain EV callback -- a timer, an L<AnyEvent> or L<IO::Async> handler
running on EV. So does one inside a C<then> on a pooled Future, as long as the
pool can hand it another connection: the connection whose callback runs is
still checked out then.

B<It refuses a wait for a pooled connection that cannot come back> while the
wait lasts (ADR 0001 amendment). A blocking call on the storage
takes a connection from the pool, and is queued when none is idle and the pool
has no room to open one: it is at its size, or what it has left is taken by a
connection it is opening right now (below). Two callers hold a connection for
as long as they run. A C<then> or C<on_done> on a pooled statement's Future:
the statement's
callback settles the Future first and hands the connection back after
(L<DBIO::PostgreSQL::EV::Storage/_dispatch_query>). And the coderef of a
C<txn_do> / C<txn_do_async>: the transaction gives its connection back only
once the coderef has returned and C<COMMIT> or C<ROLLBACK> has been answered.
A blocking call on the storage made there -- C<< $storage->select >> in a
coderef where C<< $ctx->select_async >> was meant -- needs another connection.
With a pool of one, or with every connection held by a callback this call is
nested in, it is queued for a connection its own caller holds. Nothing is
sent, so nothing is due and the refusal above does not see it; and L<EV::Pg>
keeps the held connection's read watcher counted while the callback it
delivers to runs, so the loop does not run dry either.

B<A connection that is being opened is held the same way>. The pool opens a
connection synchronously, inside the C<acquire> that found room for it, and
calls code on the way that is not its own: the AccessBroker asked for the
connect info, and the replay of C<on_connect_do> / C<on_connect_call>, which
runs the loop until the server has answered
(L<DBIO::PostgreSQL::EV::Storage/_run_pool_connect_statement>). The spawn
holds its slot throughout (L<DBIO::Storage::PoolBase/acquire>), so a call on
the storage made from inside it -- by the broker itself, or by a callback the
loop runs while the broker's client fetches or the replay waits, a timer of
the application, say -- finds no room and is queued behind it, although the
pool holds fewer connections than its size. The spawn is a frame below that
call on the call stack: the connection is handed out only after it has
returned, and a blocking wait for it cannot end. A wait that does not see this
dies with I<"... the EV loop has nothing left that could complete it"> when
nothing else is on the loop; with a watcher that keeps the loop alive -- the
storage's own C<LISTEN> connection is one -- it hangs (measured against
PostgreSQL, F<t/78-blocking-behind-spawn-live.t>).

C<await> therefore asks, on entry and before every iteration of the loop,
whether the Future it waits for is chained off a caller queued for a
connection (L</new>), and whether every connection of that pool is held by
something on the call stack: none idle, and each either with a callback of
this transport on the call stack and nothing but that callback's statement
pending, or being opened by a spawn that is running
(L<DBIO::PostgreSQL::EV::Pool/_pg_held_by_callbacks>). If so, it takes the
caller out of the pool's queue and fails it with I<"Blocking wait refused:
...">, naming the size of the pool, what holds its connections -- the
callbacks this call runs inside, or how many of them the pool is opening in a
call this one runs inside -- and what to do instead: the C<*_async> methods
chained with C<then>; in a C<txn_do> coderef the context's, to run on the
transaction's connection; or a larger C<pool_size>. The failure reaches the
waiting Future through its chain, so C<get> dies with it. An AccessBroker
that makes the blocking call itself and lets the refusal through fails the
call whose connection was being opened; the spawn then took no slot.

=over 4

=item * The refused call does not run, then or later -- unlike the refusal
above, which cancels nothing. It never had a connection, and taken out of the
queue it gets none: a refused C<insert> writes nothing. Left queued it would
be handed the connection once the callback has returned, and run after its
caller was told it had failed. In a C<txn_do> coderef the refusal fails the
coderef, so the transaction is rolled back and its connection goes back to
the pool.

=item * A wait that can end is not refused: one for a connection that is idle
or still connecting, that a statement in flight will give back, or that is
held by a transaction none of whose callbacks is running -- and any wait at
top level or in a plain EV callback, where no callback of a connection runs
and no connection is being opened below it. A connection being opened is no
reason by itself: with another one busy with a statement in flight, the call
waits for that one and runs on it.

=item * Only the caller that is waited for is failed. A call queued for the
connection without anybody blocking on it -- an unawaited
C<< $storage->select_async >> in the callback -- stays queued and runs once
the callback has returned.

=item * Where both refusals apply, the first one speaks: a blocking call on
the storage in a C<txn_do> coderef that has a C<$ctx> statement in flight is
refused for the result that is due, with that refusal's text. The call is
queued for the transaction's connection, has none yet, and is taken out of the
queue and failed all the same: it does not run once the transaction has given
its connection back. The statement of the C<$ctx> that is on the
wire completes. A convergent that holds the queued call beside a statement
already on the wire fails with it, as L<Future> has a convergent do.

=item * It sees the queued caller through L</new>, that is, in a Future
chained off it with C<then> and its siblings, or in a convergent whose first
component is. A blocking wait on a Future that reaches a queued caller another
way -- a C<then> callback that returned the Future of a storage call, on a
Future that was pending before -- is not refused and waits as before.

=item * It refuses only what the call stack makes certain. A connection held
with none of its callbacks running counts as one that can come back, whoever
holds it: a blocking call queued behind a transaction that waits for
something that never happens still waits as long as that does.

=item * A transaction whose coderef returns the Future of a call on the
storage -- C<< txn_do(sub { $storage->select_async(...) }) >> with a pool of
one -- is no blocking wait for a queued caller: the transaction waits for the
call and the call for the transaction's connection, and C<await> is not
involved. It is refused where core asks for the Future the coderef returned
(L<DBIO::Storage::Async/_txn_inner_future>):
L<DBIO::PostgreSQL::EV::Storage/_txn_inner_future> calls
C<_refuse_queued> on it, and when every connection of the pool is held by a
callback on the call stack -- the C<BEGIN>'s callback running the coderef is
one -- the call is taken out of the queue and failed with the refusal above.
The coderef's Future fails, the transaction is rolled back, C<txn_do> dies with
the refusal and the connection goes back to the pool; the refused call never
runs. A call on the storage that finds a connection idle (a pool of two) is no
wait that cannot end: it runs on that connection, outside the transaction, and
nothing is refused.

=item * It knows the callbacks the refusal above knows, and no others: a
connection counts as held by a callback only inside one
L<DBIO::PostgreSQL::EV::Storage> handed to L<EV::Pg>. And of a connection
being opened it knows the two stretches the pool and this transport run
themselves (L<DBIO::PostgreSQL::EV::Pool/_pg_opening>): whatever else runs
the loop inside a spawn, not through the connect statement seam, is not seen,
and a blocking call made in that loop waits as before.

=item * It does not wait for what only something outside the call stack could
do. A timer that shuts the pool down (C<< $storage->disconnect >>) would fail
the queued caller too; the wait is refused before it gets there.

=back

It B<dies instead of spinning> when the loop has nothing left that could
settle the Future: an iteration after which no watcher that keeps the loop
alive is active -- no statement in flight, no timer -- while the Future is
still pending. Such a Future would never become ready (EV answers at once when
there is nothing to wait for, so a plain C<until> loop would burn a core
forever). A watcher that is active does keep it waiting, as it should, like an
L<IO::Async::Future> would.

Whichever way a wait is given up on while the Future hangs off a caller that is
still queued for a connection -- the refusal above, the one for more results
due, or the loop running dry -- that caller is taken out of the pool's queue
and failed, with the text of the refusal that was raised. Left
queued, the next release would hand it the connection: it would run after its
caller was told the wait had failed, or, its chain dropped with the dying
caller, the connection would be lost and a pool of one wedged. A callback that
dies as the queued caller is failed is warned about; the pool is in order
before it runs.

=head2 new

  $f = DBIO::PostgreSQL::EV::Future->new;
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
C<$pool> waits on. L<DBIO::PostgreSQL::EV::Pool/_new_waiter> calls it on the
Future it hands to L<DBIO::Storage::PoolBase/acquire>. Returns the Future.

=head2 _held_by_callback

  my $held = DBIO::PostgreSQL::EV::Future->_held_by_callback($conn);

Class method. True while one of this transport's callbacks is being delivered
for C<$conn> and nothing but that callback's statement is pending on it
(L<EV::Pg/pending_count> at most one): the connection has nothing in flight
the loop could answer, and whatever is to happen on it next -- the release of
a pooled statement's connection, a transaction's C<COMMIT> or C<ROLLBACK> --
waits for that callback to return. False for a connection none of whose
callbacks runs, whatever holds it, and for one with more pending: a result is
due there, and L</await> refuses a wait for that reason first.
L<DBIO::PostgreSQL::EV::Pool/_pg_held_by_callbacks> asks it of each of its
connections.

=head2 _replaying

  my $replaying = DBIO::PostgreSQL::EV::Future->_replaying($conn);

Class method. Marks C<$conn> as a connection whose connect actions are being
replayed, for as long as the returned frame lives.
L<DBIO::PostgreSQL::EV::Storage/_run_pool_connect_statement> keeps it in a
lexical while it runs the L<EV> loop for a connect statement: the pool counts
the connection by then, it is not idle, and no callback of this transport is
being delivered for it -- yet it is handed out only once the spawn that
replays on it has returned, and whatever runs in that loop runs above the
spawn on the call stack. L</_held_by_spawn> answers from the mark.

=head2 _held_by_spawn

  my $held = DBIO::PostgreSQL::EV::Future->_held_by_spawn($conn);

Class method. True while the connect actions of C<$conn> are being replayed
(L</_replaying>): the spawn that opens it is running, and the connection
cannot be handed out before that has returned.
L<DBIO::PostgreSQL::EV::Pool/_pg_held_by_callbacks> asks it of each of its
connections, beside L</_held_by_callback>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
