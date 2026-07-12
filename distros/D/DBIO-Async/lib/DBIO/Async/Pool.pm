package DBIO::Async::Pool;
# ABSTRACT: Generic async connection pool for DBIO drivers

use strict;
use warnings;
use base 'DBIO::Storage::PoolBase';

use Carp 'croak';
use Scalar::Util ();
use Future;
use Future::IO;
use namespace::clean;



sub new {
  my ($class, %args) = @_;
  my $storage = delete $args{storage};
  croak('storage required') unless $storage;

  my $self = $class->SUPER::new(%args);
  $self->{storage} = $storage;
  Scalar::Util::weaken($self->{storage}) if ref $self->{storage};
  return $self;
}


sub acquire {
  my $self = shift;
  return $self->SUPER::acquire->then(sub {
    my $conn = shift;
    return $self->_await_conn_ready($conn);
  });
}


sub _await_conn_ready {
  my ($self, $conn) = @_;
  return $self->future_class->done($conn) unless $self->{storage};
  return $self->{storage}->_await_conn_ready($conn);
}


sub _create_connection {
  my ($self, $conninfo) = @_;
  croak 'Storage reference lost; cannot create connection' unless $self->{storage};
  return $self->{storage}->_create_pool_connection($conninfo);
}


sub _shutdown_connection {
  my ($self, $conn) = @_;
  return unless $self->{storage};
  $self->{storage}->_shutdown_pool_connection($conn);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Async::Pool - Generic async connection pool for DBIO drivers

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  my $pool = DBIO::Async::Pool->new(
      storage  => $storage,
      conninfo => { host => 'localhost', dbname => 'myapp' },
      size     => 10,
      on_error => sub { warn $_[0] },
  );

  my $conn = $pool->acquire->get;   # Future resolving to ready connection
  $pool->release($conn);            # return to pool
  my $conn = $pool->acquire_txn;    # pinned for transaction

=head1 DESCRIPTION

Connection pool for L<DBIO::Async::Storage>. Manages a pool of database
connections using the idle-list / waiter-queue / capacity mechanics
inherited from L<DBIO::Storage::PoolBase>.

This class supplies two additions over PoolBase:

=over 4

=item * Readiness gating on L</acquire> -- the resolved Future does not
complete until the connection is actually ready for queries, via
L</_await_conn_ready>.

=item * Delegation of connection lifecycle to the owning Storage via
L</_create_connection> and L</_shutdown_connection>, which call back to
L<DBIO::Async::Storage/_create_pool_connection> and
L<DBIO::Async::Storage/_shutdown_pool_connection>.

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
is weakened to avoid a cycle (storage holds pool, pool holds storage).

=head2 acquire

Like L<DBIO::Storage::PoolBase/acquire>, but the resolved Future does not
complete until the connection is actually ready for queries. This
correctly handles drivers where connection construction returns before
the async connect finishes (e.g. libpq's C<PQconnectStart>).

Readiness is checked via L</_await_conn_ready>, which delegates to the
Storage's L<DBIO::Async::Storage/_await_conn_ready>.

=head2 _await_conn_ready

  my $future = $pool->_await_conn_ready($conn);

Returns a Future that resolves to C<$conn> once it is ready for queries.
Delegates to the Storage's L<DBIO::Async::Storage/_await_conn_ready>.
If the Storage reference has been lost (DESTROY path), short-circuits
to an immediately-done Future.

=head2 _create_connection

Delegates to the owning Storage's
L<DBIO::Async::Storage/_create_pool_connection>. The pool tracks the
returned connection -- do not push it onto C<_connections> yourself.

=head2 _shutdown_connection

Delegates to the owning Storage's
L<DBIO::Async::Storage/_shutdown_pool_connection>. If the Storage
reference has been lost, returns silently (best-effort on DESTROY).

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
