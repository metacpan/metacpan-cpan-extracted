package DBIO::Async::Pool;
# ABSTRACT: Generic async connection pool for DBIO drivers

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage::PoolBase';

use Carp 'croak';
use Scalar::Util ();
use DBIO::Async::Future;
use namespace::clean;



sub new {
  my ($class, %args) = @_;
  croak('storage required') unless $args{storage};

  # Handed on to core: it reads the pool's limits (acquire_timeout, max_waiters,
  # reset_timeout) off the storage, and keeps the reference weak.
  return $class->SUPER::new(%args);
}


sub _connection_ready_future {
  my ($self, $conn) = @_;
  return $self->_await_conn_ready($conn);
}


sub _await_conn_ready {
  my ($self, $conn) = @_;
  # No `use Future` in this file on purpose: DBIO::Storage::PoolBase::new
  # require()s whatever future_class names, so the CONFIGURED class -- not just
  # the default -- is loaded before any instance method can run.
  return $self->future_class->done($conn) unless $self->{storage};
  return $self->{storage}->_await_conn_ready($conn);
}


sub _idle_connection_alive {
  my ($self, $conn) = @_;
  return 1 unless $self->{storage};
  return $self->{storage}->_idle_connection_alive($conn);
}


sub _new_waiter {
  my ($self) = @_;
  return DBIO::Async::Future->new->mark_pool_wait($self);
}


sub _create_connection {
  my ($self, $conninfo) = @_;
  croak 'Storage reference lost; cannot create connection' unless $self->{storage};
  return $self->{storage}->_create_pool_connection($conninfo);
}


sub _shutdown_connection {
  my ($self, $conn) = @_;
  return unless $self->{storage};
  $self->{storage}->_abandon_flights_on($conn);
  $self->{storage}->_shutdown_pool_connection($conn);
}


sub _retire_connection {
  my ($self, $conn) = @_;
  $self->SUPER::_retire_connection($conn);
  # The pool's own flag: during shutdown the pool fails its callers with its
  # own reason and cancels the chain on the readiness Future itself.
  $self->{storage}->_ready_end($conn) if $self->{storage} && !$self->{_shutdown};
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Async::Pool - Generic async connection pool for DBIO drivers

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  my $pool = DBIO::Async::Pool->new(
      storage  => $storage,
      conninfo => { host => 'localhost', dbname => 'myapp' },
      size     => 10,
      on_error => sub { warn $_[0] },
  );

  my $conn  = $pool->acquire->get;  # Future resolving to ready connection
  my $lease = $pool->_lease($conn); # the borrow's lease, right after the acquire
  $pool->release($conn, $lease);    # return to pool; a release that comes
                                    # after the connection went on is no-op

  # same checkout as acquire; the caller holds it until release
  my $txn_conn  = $pool->acquire_txn->get;
  my $txn_lease = $pool->_lease($txn_conn);
  $pool->release($txn_conn, $txn_lease);

=head1 DESCRIPTION

Connection pool for L<DBIO::Async::Storage>. Manages a pool of database
connections using the idle-list / waiter-queue / capacity mechanics
inherited from L<DBIO::Storage::PoolBase>.

This class supplies four additions over PoolBase:

=over 4

=item * Readiness gating through the L</_connection_ready_future> seam --
L<DBIO::Storage::PoolBase/acquire> chains every connection it hands out
through that seam, and this class answers it with L</_await_conn_ready>, so
the resolved Future does not complete until the connection is actually ready
for queries.

=item * Delegation of connection lifecycle to the owning Storage via
L</_create_connection> and L</_shutdown_connection>, which call back to
L<DBIO::Async::Storage/_create_pool_connection> and
L<DBIO::Async::Storage/_shutdown_pool_connection>.

=item * Delegation of the borrow-time liveness check to the owning Storage via
L</_idle_connection_alive>, which calls back to
L<DBIO::Async::Storage/_idle_connection_alive> -- so a driver can tell the
pool that an idle connection died before it is handed out.

=item * The end of a statement still in flight on a connection the pool
closes. L<DBIO::Storage::PoolBase/shutdown>, L<DBIO::Storage::PoolBase/release>
and the rest are core's and not overridden; but a connection is closed through
L</_shutdown_connection>, and that asks the Storage to end what is on its wire
first (L<DBIO::Async::Storage/STATEMENTS IN FLIGHT>).

=back

Drivers that need a different pool implementation can subclass this or
provide their own L<DBIO::Storage::PoolBase> subclass.

=head1 METHODS

=head2 new

  my $pool = DBIO::Async::Pool->new(
      storage  => $storage,       # required
      conninfo => $conninfo,      # or conninfo_provider
      size     => 10,
      on_error => sub { warn $_[0] },
  );

Like L<DBIO::Storage::PoolBase/new>, but requires a C<storage> argument
(the L<DBIO::Async::Storage> that owns this pool). The storage reference
is weakened to avoid a cycle (storage holds pool, pool holds storage). The
pool's limits -- C<acquire_timeout>, C<max_waiters>, C<reset_timeout> -- are
the storage's async options (L<DBIO::Async::Storage/TIMEOUTS AND LIMITS>).

=head2 _connection_ready_future

  my $future = $pool->_connection_ready_future($conn);

Overrides L<DBIO::Storage::PoolBase/_connection_ready_future>, the seam
L<DBIO::Storage::PoolBase/acquire> chains around every connection it hands
out -- freshly spawned, reused-idle, or handed to a queued waiter. Gating
lives there and only there, so all three acquire paths and
L<DBIO::Storage::PoolBase/acquire_txn> are gated identically.
Delegates to L</_await_conn_ready>; the resolved Future does not complete
until the connection is actually ready for queries, which is what makes a
driver whose connection construction returns before the async connect
finishes (e.g. libpq's C<PQconnectStart>) safe to hand out.

Why this transport overrides the seam instead of inheriting the base
default: that default resolves from the readiness side table
L<DBIO::Storage::PoolBase/_create_ready_connection> fills, which is
B<callback-shaped> -- it wires a transport's C<on_connect> / C<on_error>
onto a per-connection Future. This transport is B<poll-shaped>: readiness is
a question asked of the driver (L<DBIO::Async::Storage/_conn_ready>) and
waited on with C<< Future::IO->poll >> on the connection's socket fd, and the
C<future_io> seam contract has no connect callbacks to hang such a Future
off. Nothing is ever registered in the side table here, so the inherited
default would resolve immediately and hand out a still-connecting handle --
the case core's own POD reserves for an override ("a transport whose
readiness is not expressible that way").

=head2 _await_conn_ready

  my $future = $pool->_await_conn_ready($conn);

Returns a Future that resolves to C<$conn> once it is ready for queries.
Delegates to the Storage's L<DBIO::Async::Storage/_await_conn_ready>.
If the Storage reference has been lost (DESTROY path), short-circuits
to an immediately-done Future.

=head2 _idle_connection_alive

  my $alive = $pool->_idle_connection_alive($conn);

Overrides L<DBIO::Storage::PoolBase/_idle_connection_alive>, the borrow-time
liveness seam L<DBIO::Storage::PoolBase/acquire> asks about every idle
connection it is about to hand out. Delegates to the
owning Storage's L<DBIO::Async::Storage/_idle_connection_alive>, the same way
L</_await_conn_ready> delegates readiness.

Why the override: core asks the B<pool>, and the inherited default answers
true without looking. A C<future_io> driver writes a storage adapter and never
a pool of its own, so without this delegation a driver that fills the storage
seam would never be asked. The storage seam carries the same name and the same
contract as core's, so a driver following core's instruction to "override
C<_idle_connection_alive>" does exactly that on the class it writes.

A throw from the storage is B<not> caught here. It reaches core's acquire,
which counts it as not vouching for the connection, passes it to the pool's
C<on_error> and retires the connection -- one rule for every pool, decided in
one place.

If the Storage reference has been lost (DESTROY path), answers true without
asking: no check, the default's behaviour, just as L</_await_conn_ready>
short-circuits to a done Future.

=head2 _new_waiter

  my $waiter = $pool->_new_waiter;

Overrides core's L<DBIO::Storage::PoolBase/_new_waiter> seam,
which L<DBIO::Storage::PoolBase/acquire> calls once for every caller it has to
queue, and answers a new, pending L<DBIO::Async::Future> marked with this pool
(weakly). Core queues it, wires the cancel hook and settles it.

Why: every Future built on the wait is of the waiter's class, and a plain
L<Future> cannot C<get> while pending. With the pool exhausted, a sync storage
method -- C<< select_async(...)->get >> (ADR 0001) -- croaked I<is not yet
complete and does not provide ->await>. On a L<DBIO::Async::Future> it waits for
its connection and drives L<Future::IO> meanwhile (ADR 0008). If that
blocking wait dies -- the built-in loop refusing to sit idle, because the
connection is held by the caller itself -- the waiter is withdrawn through
L<DBIO::Storage::PoolBase/_withdraw_waiter> and failed, and the pool is not
left handing a connection to it. Async callers see no difference. The pool's
C<future_class> is untouched; only the waiter has this class.

=head2 _create_connection

Delegates to the owning Storage's
L<DBIO::Async::Storage/_create_pool_connection>. The pool tracks the
returned connection -- do not push it onto C<_connections> yourself.

=head2 _shutdown_connection

Delegates to the owning Storage's
L<DBIO::Async::Storage/_shutdown_pool_connection>. If the Storage
reference has been lost, returns silently (best-effort on DESTROY).

Before the driver closes the connection, the Storage ends whatever statement
is still in flight on it (L<DBIO::Async::Storage/_abandon_flights_on>): the
statement's caller gets a failed Future and the L<Future::IO> poll on the
connection's socket is let go of. With or without one, the connection is
marked finished, so the transport sends nothing more on it. Core's pool cannot
do that -- it knows the connection, not the Future of a statement on it -- and
this is the one seam every close goes through: each connection at
L<DBIO::Storage::PoolBase/shutdown>, which is what the storage's C<disconnect>
runs, and each one the pool retires. A connection core does B<not> close is
not touched: none in a forked child that inherited the pool
(L<DBIO::Storage::PoolBase/_verify_pid>), so the parent's statements are not
settled there.

=head2 _retire_connection

Core's L<DBIO::Storage::PoolBase/_retire_connection>, followed by the end of
the connection's readiness wait. A connection retired while it is
coming up has had the poll of that wait let go of in L</_shutdown_connection>;
the readiness Future above the poll is core's pool's to hear about, and it
hears it here: it is failed once the pool has parked its hand-over, so the
caller who waited for the connection has already been told why and
the slot the connection held goes to the next caller waiting.
L<DBIO::Storage::PoolBase/shutdown> fails and cancels what it holds itself, and
is left to: during it nothing is failed here.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
