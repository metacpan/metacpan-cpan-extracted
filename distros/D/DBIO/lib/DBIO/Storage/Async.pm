package DBIO::Storage::Async;
# ABSTRACT: Base class for async storage implementations

use strict;
use warnings;
use base 'DBIO::Storage';

use Carp 'croak';
use Scalar::Util 'blessed';
use namespace::clean;



sub future_class {
  croak 'Subclass must override future_class';
}


sub pool {
  croak 'Subclass must override pool';
}


sub _is_access_broker_connect_info {
  my ($self, $info) = @_;

  return 0 unless ref $info eq 'ARRAY' && @$info == 1;
  return 0 unless blessed($info->[0]);

  return $info->[0]->isa('DBIO::AccessBroker');
}


sub _setup_access_broker {
  my ($self, $broker) = @_;

  $self->set_access_broker($broker, 'write');
  $self->{_conninfo_provider} = sub {
    return $self->_async_broker_conninfo($self->access_broker_mode);
  };

  return $self;
}


sub _clear_access_broker {
  my $self = shift;

  $self->clear_access_broker;
  $self->{_conninfo_provider} = undef;

  return $self;
}


sub _conninfo_provider { $_[0]->{_conninfo_provider} }


sub _async_broker_conninfo {
  croak 'Subclass must override _async_broker_conninfo to consume an AccessBroker';
}


sub select_async { croak 'Subclass must override select_async' }


sub select_single_async { croak 'Subclass must override select_single_async' }


sub insert_async { croak 'Subclass must override insert_async' }


sub update_async { croak 'Subclass must override update_async' }


sub delete_async { croak 'Subclass must override delete_async' }


sub txn_do_async { croak 'Subclass must override txn_do_async' }


sub pipeline { croak 'Pipeline mode not supported by this storage driver' }


sub listen { croak 'LISTEN/NOTIFY not supported by this storage driver' }


sub unlisten { croak 'LISTEN/NOTIFY not supported by this storage driver' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::Async - Base class for async storage implementations

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  # Users don't instantiate this directly -- use a concrete driver:
  my $schema = MyApp::Schema->connect(
      'DBIO::EV::Pg',
      { host => 'localhost', dbname => 'myapp', pool_size => 10 },
  );

  # Async queries return Futures
  $schema->resultset('Artist')->all_async->then(sub {
      my @artists = @_;
      say $_->name for @artists;
  });

=head1 DESCRIPTION

Abstract base class for async DBIO storage drivers. Extends
L<DBIO::Storage> with async-specific infrastructure: connection
pooling, transaction pinning, and Future-based query execution.

Concrete implementations live in separate distributions:

=over 4

=item * L<DBIO::EV::Pg::Storage> -- uses L<EV::Pg> (libpq, no DBI)

=item * L<Net::Async::DBIO::Storage> -- uses L<IO::Async>

=item * L<Mojo::DBIO::Storage> -- uses L<Mojo::IOLoop>

=back

=head1 METHODS

=head2 future_class

Must be overridden by subclasses to return the event-loop-specific
Future class (e.g. C<'Future'> for L<Future.pm|Future>).

=head2 pool

Returns the connection pool object. Must be overridden by subclasses.

=head2 _is_access_broker_connect_info

  if ($self->_is_access_broker_connect_info($info)) { ... }

True when the supplied connect info is a broker-style invocation: a
single-element arrayref whose sole member is a blessed
L<DBIO::AccessBroker> instance. Mirrors the same check on the DBI side
(L<DBIO::Storage::DBI::AccessBroker>).

=head2 _setup_access_broker

  $self->_setup_access_broker($info->[0]);

Attach the broker (via the inherited L<DBIO::Storage/set_access_broker>)
and install the per-spawn C<conninfo_provider> coderef. Call this from a
driver's C<connect_info> when L</_is_access_broker_connect_info> matched.
The coderef closes over C<$self> and, on each invocation, calls the
driver's L</_async_broker_conninfo> to obtain freshly-refreshed,
storage-native connect info for one new pool connection.

=head2 _clear_access_broker

  $self->_clear_access_broker;

Detach any broker (via the inherited L<DBIO::Storage/clear_access_broker>)
and tear down the C<conninfo_provider>, so a subsequent non-broker
connect uses the static conninfo path. Call from a driver's
C<connect_info> on the non-broker branch.

=head2 _conninfo_provider

The per-spawn credential coderef installed by L</_setup_access_broker>, or
C<undef> when no broker is attached. Hand this to the pool as its
C<conninfo_provider> so every NEW pool connection is built from fresh
credentials (see L<DBIO::Storage::PoolBase/_spawn_connection>).

=head2 _async_broker_conninfo

  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    ...
    return $conninfo;  # one fresh, storage-native conninfo value
  }

Required driver seam hook when a broker is in use: return one fresh
storage-native connect-info value for a single new pool connection, in the
shape the pool's C<_transform_conninfo> expects (e.g. the libpq parameter
hashref for the PostgreSQL pool). Invoked once per pool spawn by the
L</_conninfo_provider> coderef. Defaults to croaking; a driver that
consumes the broker must override it.

=head2 select_async

  my $future = $storage->select_async($source, $select, $where, $attrs);

Must be overridden by subclasses with a non-blocking implementation
that returns a Future.

=head2 select_single_async

Must be overridden by subclasses.

=head2 insert_async

Must be overridden by subclasses.

=head2 update_async

Must be overridden by subclasses.

=head2 delete_async

Must be overridden by subclasses.

=head2 txn_do_async

  my $future = $storage->txn_do_async(sub { ... });

Acquires a connection from the pool, issues BEGIN, executes the
coderef, and issues COMMIT on success or ROLLBACK on failure.
The coderef receives a transaction-bound storage. Must be overridden.

=head2 pipeline

  my $future = $storage->pipeline(sub {
      my $storage = shift;
      # ... batch multiple queries ...
  });

Execute multiple queries in pipeline mode for reduced round-trips.
Optional -- not all async drivers support this. Default croaks.

=head2 listen

  $storage->listen($channel, sub { my ($channel, $payload, $pid) = @_; });

Subscribe to database notifications (e.g. PostgreSQL LISTEN/NOTIFY).
Optional -- not all databases support this. Default croaks.

=head2 unlisten

  $storage->unlisten($channel);

Unsubscribe from a notification channel.

=head1 ACCESSBROKER CONSUMPTION

The async storage tier is the second consumer of the
L<DBIO::AccessBroker> credential seam (the first being L<DBIO::Storage::DBI>;
see L<CONTEXT.md> and the ADRs). The broker-management API itself
(C<set_access_broker>, C<clear_access_broker>,
C<current_access_broker_connect_info>) lives on the base L<DBIO::Storage>,
so it is inherited here unchanged.

What this class adds is the I<async> consumption wiring that was previously
re-implemented by every async driver: detecting a broker passed as connect
info, building the per-spawn C<conninfo_provider> coderef that pulls fresh
credentials, and feeding it to the pool so every NEW pool connection gets
freshly-refreshed connect info. Drivers supply only the one storage-native
seam hook, L</_async_broker_conninfo>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
