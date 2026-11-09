package DBIO::Storage::Pool;
# ABSTRACT: Abstract connection pool interface for async storage

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp 'croak';
use namespace::clean;



sub acquire { croak 'Subclass must override acquire' }


sub release { croak 'Subclass must override release' }


sub acquire_txn { croak 'Subclass must override acquire_txn' }


sub size { croak 'Subclass must override size' }


sub available { croak 'Subclass must override available' }


sub max_size { croak 'Subclass must override max_size' }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::Pool - Abstract connection pool interface for async storage

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  # Implemented by async distributions, e.g.:
  package DBIO::PostgreSQL::EV::Pool;
  use base 'DBIO::Storage::Pool';

  sub acquire  { ... }   # return Future resolving to a connection
  sub release  { ... }   # return connection to pool
  sub shutdown { ... }   # terminal, idempotent teardown

See F<t/storage/pool_base.t> for a runnable example.

=head1 DESCRIPTION

Defines the interface contract for connection pools used by
L<DBIO::Storage::Async> drivers. This is an abstract base -- concrete
implementations live in async driver distributions.

Sync storage (L<DBIO::Storage::DBI>) does not use a pool -- it manages
a single connection directly. This interface is only relevant for async
storage drivers that need to multiplex queries across multiple
connections.

=head1 METHODS

=head2 acquire

  my $future = $pool->acquire;

Acquire a connection from the pool. Returns a Future that resolves
to a connection handle. If no connections are available, the Future
waits until one is released.

An implementation must report failure through that Future too -- a connection
that cannot be created, or whose connect actions the server refuses, fails the
Future rather than throwing. A caller holds a Future and reaches
errors with C<< ->on_fail >>; an exception raised instead arrives nowhere.
After L</shutdown>, C<acquire> and L</acquire_txn> keep that contract by
returning a failed Future rather than throwing or starting new work.

=head2 release

  $pool->release($connection);
  $pool->release($connection, $lease);

Return a connection to the pool, making it available for other
queries. Once L</shutdown> starts, a late release has no effect.

An implementation may take a second argument, the lease of the borrow the
release ends, and ignore a release whose lease is not the connection's current
one (L<DBIO::Storage::PoolBase/_lease>). A caller that has no
lease passes none.

=head2 acquire_txn

  my $future = $pool->acquire_txn;

Acquire a connection pinned for exclusive transaction use. The
connection will not be returned to the general pool until the
transaction completes (COMMIT or ROLLBACK).

=head2 size

  my $n = $pool->size;

Returns the total number of connections in the pool (active + idle).

=head2 available

  my $n = $pool->available;

Returns the number of idle connections ready for use.

=head2 max_size

  my $n = $pool->max_size;

Returns the configured maximum pool size.

=head2 shutdown

  $pool->shutdown;

Permanently shut down this pool instance. Implementations must make this
transition terminal and idempotent: fail queued and readiness-pending acquire
Futures, refuse later acquires through failed Futures, ignore late releases,
and close each connection at most once. Reconnection is owned above the pool
and creates a new pool instance.

This is the existing teardown contract consumed by
L<DBIO::Storage::Async/disconnect>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
