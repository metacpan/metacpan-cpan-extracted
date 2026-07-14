package DBIO::Storage::PoolBase;
# ABSTRACT: Shared connection pool mechanics for async DBIO drivers

use strict;
use warnings;
use base 'DBIO::Storage::Pool';

use Carp 'croak';
use Scalar::Util ();
use namespace::clean;



sub new {
  my ($class, %args) = @_;
  croak('conninfo or conninfo_provider required')
    unless $args{conninfo} || $args{conninfo_provider};

  my $self = bless {
    conninfo          => $args{conninfo},
    conninfo_provider => $args{conninfo_provider},
    max_size          => $args{size} || 5,
    on_error          => $args{on_error} || sub { warn "Pool error: $_[0]\n" },
    _connections      => [],
    _idle             => [],
    _waiters          => [],
  }, $class;

  $self->{future_class} = $args{future_class} if $args{future_class};
  my $fc = $self->future_class;
  eval "require $fc" or croak "Cannot load future class $fc: $@";

  # karr #68: optional back-reference to the owning DBIO::Storage::Async, held
  # weakly (the storage owns the pool, not the other way round). When present,
  # the pool replays the storage's configured on_connect / on_disconnect actions
  # against every freshly-spawned / torn-down connection -- see the connect-action
  # hooks in L</_spawn_connection> and L</shutdown>. A pool used standalone, or an
  # async pool whose owner does not wire it, simply carries no {storage} and skips
  # the hooks entirely.
  if (defined $args{storage}) {
    $self->{storage} = $args{storage};
    Scalar::Util::weaken($self->{storage}) if ref $self->{storage};
  }

  return $self;
}


sub future_class { $_[0]->{future_class} || 'Future' }


sub acquire {
  my ($self) = @_;
  return $self->_acquire_slot->then(sub {
    my $conn = shift;
    return $self->_connection_ready_future($conn);
  });
}

# Raw pool-slot acquisition: idle reuse / capacity spawn / waiter queue, WITHOUT
# readiness gating. Returns a Future resolving to a connection object (or a
# pending waiter Future that resolves to one on release). acquire() wraps this in
# the _connection_ready_future seam so all three paths are gated identically and
# in exactly one place -- an async subclass overrides the seam, never this or
# acquire() (karr #75). Kept as a distinct method so a subclass can still reach
# the un-gated slot logic if it ever needs to.
sub _acquire_slot {
  my ($self) = @_;

  if (@{ $self->{_idle} }) {
    # FIFO: hand out the connection that has been idle longest (the one at
    # the front of the queue). Release pushes onto the tail, so shift takes
    # from the head — this cycles every conn through instead of always
    # reusing the most-recently-released one (LIFO), which caused 1 hot
    # conn and N-1 cold conns under bursty load.
    return $self->future_class->done(shift @{ $self->{_idle} });
  }

  if (@{ $self->{_connections} } < $self->{max_size}) {
    my $conn = $self->_spawn_connection;
    return $self->future_class->done($conn);
  }

  my $f = $self->future_class->new;
  push @{ $self->{_waiters} }, $f;
  return $f;
}


sub _connection_ready_future {
  my ($self, $conn) = @_;
  return $self->future_class->done($conn);
}


sub _register_connection_ready {
  my ($self, $conn, $ready) = @_;
  $self->{_ready}{ Scalar::Util::refaddr($conn) } = $ready;
  return $ready;
}


sub _connection_ready_lookup {
  my ($self, $conn) = @_;
  return unless $self->{_ready};
  return $self->{_ready}{ Scalar::Util::refaddr($conn) };
}


sub _clear_connection_ready {
  my ($self, $conn) = @_;
  return unless $self->{_ready};
  delete $self->{_ready}{ Scalar::Util::refaddr($conn) };
}


sub acquire_txn {
  my $self = shift;
  return $self->acquire;  # same behavior, caller manages lifecycle
}


sub release {
  my ($self, $conn) = @_;

  if (@{ $self->{_waiters} }) {
    my $waiter = shift @{ $self->{_waiters} };
    $waiter->done($conn);
    return;
  }

  push @{ $self->{_idle} }, $conn;
}


sub size { scalar @{ $_[0]->{_connections} } }


sub available { scalar @{ $_[0]->{_idle} } }


sub max_size { $_[0]->{max_size} }


sub shutdown {
  my $self = shift;
  for my $conn (@{ $self->{_connections} }) {
    # karr #68: on_disconnect_do / on_disconnect_call run against the connection
    # while it is still live, before it is closed. Best-effort like the close.
    eval { $self->_dbio_run_pool_disconnect_actions($conn) };
    eval { $self->_shutdown_connection($conn) };
    # karr #75: drop the connection's readiness Future from the side table here,
    # centrally, so an async _shutdown_connection override never has to remember
    # to clean up the bookkeeping itself. No-op for synchronous pools.
    $self->_clear_connection_ready($conn);
  }
  $self->{_connections} = [];
  $self->{_idle} = [];
}

sub _spawn_connection {
  my $self = shift;
  my $conninfo = $self->{conninfo_provider}
    ? $self->{conninfo_provider}->()
    : $self->{conninfo};

  my $conn = $self->_create_connection($self->_transform_conninfo($conninfo));
  push @{ $self->{_connections} }, $conn;

  # karr #68: a freshly spawned physical connection must receive the same
  # session setup (on_connect_do / on_connect_call) the owning sync storage was
  # configured with, before it is ever served to a caller -- otherwise pooled
  # async connections diverge silently from the sync path. Runs exactly once per
  # physical connection (idle reuse goes through acquire, not spawn).
  $self->_dbio_run_pool_connect_actions($conn);

  return $conn;
}

# karr #68: bridge the central pool-spawn / shutdown path to the owning async
# storage's connect-action seam (DBIO::Storage::Async::_setup_pool_connection /
# _teardown_pool_connection). No-op unless an async storage back-ref is wired
# and exposes the seam, so non-async pools and un-wired pools are unaffected.
sub _dbio_run_pool_connect_actions {
  my ($self, $conn) = @_;
  my $storage = $self->{storage} or return;
  return unless $storage->can('_setup_pool_connection');
  $storage->_setup_pool_connection($conn);
}

sub _dbio_run_pool_disconnect_actions {
  my ($self, $conn) = @_;
  my $storage = $self->{storage} or return;
  return unless $storage->can('_teardown_pool_connection');
  $storage->_teardown_pool_connection($conn);
}


sub _create_connection { croak 'Subclass must override _create_connection' }


sub _shutdown_connection {}


sub _transform_conninfo { $_[1] }

sub DESTROY {
  my $self = shift;
  $self->shutdown;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::PoolBase - Shared connection pool mechanics for async DBIO drivers

=head1 VERSION

version 0.900002

=head1 SYNOPSIS

  package DBIO::PostgreSQL::Async::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    return EV::Pg->new(
      conninfo   => $conninfo,
      on_connect => sub {},
      on_error   => $self->{on_error},
    );
  }

  sub _shutdown_connection { $_[1]->finish }

  sub _transform_conninfo { conninfo_string($_[1]) }

See F<t/storage/pool_base.t> for a runnable example.

=head1 DESCRIPTION

Concrete implementation of the L<DBIO::Storage::Pool> contract hosting
the pool mechanics shared by all async drivers: idle-pool handling,
capacity-bounded connection creation, the waiter queue and shutdown.

Drivers subclass this and supply only the engine seam:

=over 4

=item *

L</_create_connection> -- build one driver connection (required)

=item *

L</_shutdown_connection> -- close one driver connection (optional,
defaults to a no-op)

=item *

L</_transform_conninfo> -- adapt the stored connect info into whatever
shape the driver's connection constructor expects (optional, defaults
to passing it through unchanged)

=item *

L</_connection_ready_future> -- gate L</acquire> until a connection is
actually ready for queries (optional for synchronous pools, where the
default no-op is correct; B<required for every async transport>, see the
method for why and for the C<dbio-mysql-ev karr #20> footgun)

=item *

L</future_class> -- the Future implementation used for L</acquire>
(optional, defaults to L<Future>)

=back

=head1 METHODS

=head2 new

  my $pool = Driver::Pool->new(
      conninfo => 'dbname=myapp',
      size     => 10,
      on_error => sub { warn $_[0] },
  );

Requires C<conninfo> or C<conninfo_provider> (a coderef returning fresh
connect info per connection). C<size> caps the pool (default 5).
C<future_class> overrides the Future implementation per instance.

C<storage> (optional) is the owning L<DBIO::Storage::Async>, held weakly. When
given, the pool replays that storage's C<on_connect_do> / C<on_connect_call>
(and the C<on_disconnect_*> counterparts) against each physical connection at
spawn / shutdown (karr #68).

=head2 future_class

The Future implementation backing L</acquire>. Defaults to L<Future>;
override in a subclass or pass C<future_class> to L</new>.

=head2 acquire

Returns a connection wrapped in a Future. Hands out an idle connection if
one is available, otherwise creates a new connection if the pool has
capacity; if all connections are busy and the pool is at max size, queues
the request and returns a pending Future that resolves on the next
L</release>.

Whichever of those three paths supplies the connection, C<acquire> ALWAYS
chains the result through the L</_connection_ready_future> seam before it
resolves (karr #75). For synchronous pools that seam is a no-op — the
connection is usable the instant it exists — so the returned Future is
ready immediately and behaviour is unchanged. For async transports whose
connection is not usable until a background connect completes, the seam is
the single place where the Future is held pending until the connection is
actually ready; see L</_connection_ready_future>.

=head2 _connection_ready_future

  sub _connection_ready_future { my ($self, $conn) = @_; ... }

Readiness seam, chained by L</acquire> around every connection it hands out
— freshly spawned, reused-idle, or handed to a queued waiter. Returns a
Future that resolves to C<$conn> once the connection is actually ready to
run queries.

The default implementation is a safe no-op for synchronous pools:

  sub _connection_ready_future { $_[0]->future_class->done($_[1]) }

A DBI / synchronous connection is usable the instant its constructor
returns, so an immediately-C<done> Future is correct and L</acquire> stays
ready-at-once. Behaviour for every existing synchronous pool is therefore
unchanged.

B<Async transports MUST override this.> A backend whose connection is not
usable when its constructor returns — every event-loop transport: EV::Pg,
EV::MariaDB, C<future_io>, ... — is still connecting in the background when
the handle first exists. If such a driver leaves this seam at its default,
L</acquire> hands out a live-looking but unconnected handle and the very
first bound query on a cold pool dies C<not connected>. This is not a
theoretical edge: C<dbio-mysql-ev> shipped exactly this bug — its
C<_create_connection> wired C<on_connect =E<gt> sub {}>, a pure no-op, with
no readiness tracking, and the symptom was papered over with test-harness
pre-warming rather than fixed in the driver (B<dbio-mysql-ev karr #20>).
The correct override returns a per-connection Future that resolves from the
transport's C<on_connect> callback and fails from its C<on_error>.

The default deliberately does NOT auto-detect the async case — it cannot
know whether a given transport's constructor connects synchronously — so
forgetting the override stays possible by design. What the base does
provide is that the responsibility now lives at ONE documented seam, and
the bookkeeping for the common "resolve a per-connection Future from a
connect callback" pattern is supplied by L</_register_connection_ready>,
L</_connection_ready_lookup> and L</_clear_connection_ready>, so an override
only has to wire C<on_connect> / C<on_error> onto a Future instead of
building the side table from scratch. A typical async override:

  sub _connection_ready_future {
    my ($self, $conn) = @_;
    return $self->future_class->done($conn) if $conn->is_connected;
    return $self->_connection_ready_lookup($conn)
        || $self->future_class->done($conn);
  }

=head2 _register_connection_ready

  $self->_register_connection_ready($conn, $ready_future);

Bookkeeping primitive for the L</_connection_ready_future> pattern. Stores a
per-connection readiness Future keyed by C<Scalar::Util::refaddr($conn)>, so
an async L</_create_connection> can hand the Future's C<done> / C<fail> to
the transport's C<on_connect> / C<on_error> callbacks and have
L</_connection_ready_future> find it again by connection. Returns the Future.

=head2 _connection_ready_lookup

  my $ready = $self->_connection_ready_lookup($conn);

Return the readiness Future registered for C<$conn> via
L</_register_connection_ready>, or undef if none (e.g. a synchronous pool
that never registered one). An async L</_connection_ready_future> override
typically returns
C<< $self->_connection_ready_lookup($conn) || $self->future_class->done($conn) >>.

=head2 _clear_connection_ready

  $self->_clear_connection_ready($conn);

Drop C<$conn>'s readiness Future from the side table. Called for you by
L</shutdown> for every pooled connection, so an async L</_shutdown_connection>
override never has to clean the table up itself; also exposed for drivers
that retire a single connection outside shutdown. A no-op when no readiness
table exists.

=head2 acquire_txn

Acquire a connection pinned for exclusive transaction use.
Same as L</acquire> but the connection will not be released
back to the idle pool until explicitly released.

=head2 release

  $pool->release($conn);

Return a connection to the idle pool. If waiters are queued, hands the
connection straight to the oldest waiter instead.

=head2 size

Total connections (active + idle).

=head2 available

Number of idle connections.

=head2 max_size

Configured maximum pool size.

=head2 shutdown

Close all connections via L</_shutdown_connection> and clear the pool.

=head2 _create_connection

  sub _create_connection { my ($self, $conninfo) = @_; ... }

Required driver hook: build and return one connection from the
(already transformed) connect info. The pool tracks the connection;
do not push it anywhere yourself.

=head2 _shutdown_connection

  sub _shutdown_connection { my ($self, $conn) = @_; $conn->finish }

Optional driver hook: close one connection during L</shutdown>.
Defaults to a no-op; exceptions are swallowed by the caller.

=head2 _transform_conninfo

  sub _transform_conninfo { my ($self, $conninfo) = @_; ... }

Optional driver hook: adapt stored connect info into the shape the
driver's connection constructor expects (e.g. a libpq conninfo
string). Defaults to returning it unchanged.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
