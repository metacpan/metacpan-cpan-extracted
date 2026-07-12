package DBIO::PostgreSQL::EV::Pool;
# ABSTRACT: EV::Pg connection pool for DBIO

use strict;
use warnings;
use base 'DBIO::Storage::PoolBase';

use DBIO::PostgreSQL::EV::ConnectInfo 'conninfo_string';



sub _connection_ready_future {
  my ($self, $conn) = @_;
  return $self->future_class->done($conn) if $conn->is_connected;
  return $self->_connection_ready_lookup($conn) || $self->future_class->done($conn);
}


sub _create_connection {
  my ($self, $conninfo) = @_;

  my $ready = $self->future_class->new;
  my $on_error = $self->{on_error};
  my $conn;
  $conn = $self->_new_ev_pg(
    conninfo   => $conninfo,
    on_connect => sub { $ready->done($conn) unless $ready->is_ready },
    on_error   => sub {
      $ready->fail($_[0]) unless $ready->is_ready;
      $on_error->(@_);
    },
  );
  $self->_register_connection_ready($conn, $ready);
  return $conn;
}

# Construct the underlying EV::Pg handle. Isolated so the readiness wiring in
# _create_connection can be unit-tested with a fake connection (t/03).
sub _new_ev_pg {
  my ($self, %args) = @_;
  require EV::Pg;
  return EV::Pg->new(%args);
}


sub _shutdown_connection {
  my ($self, $conn) = @_;
  return unless defined $conn;
  $conn->finish;
}


sub _transform_conninfo { conninfo_string($_[1]) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::EV::Pool - EV::Pg connection pool for DBIO

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  my $pool = DBIO::PostgreSQL::EV::Pool->new(
      conninfo => 'dbname=myapp',
      size     => 10,
      on_error => sub { warn $_[0] },
  );

  my $pg = $pool->acquire;       # get idle connection
  $pool->release($pg);           # return to pool
  my $pg = $pool->acquire_txn;   # pinned for transaction

=head1 DESCRIPTION

Connection pool for L<DBIO::PostgreSQL::EV::Storage>. Manages a pool of
L<EV::Pg> connections, dispatching queries to available connections
and queuing when all are busy.

The acquire / release / capacity / shutdown mechanics, including the
connection-readiness gate, are inherited from L<DBIO::Storage::PoolBase>
(karr #75); this class supplies only the EV::Pg seam — see
L</_create_connection>, L</_connection_ready_future>,
L</_shutdown_connection> and L</_transform_conninfo>.

=head1 METHODS

=head2 _connection_ready_future

Overrides L<DBIO::Storage::PoolBase/_connection_ready_future>: the resolved
Future does not complete until the connection is actually ready for
queries.

C<EV::Pg-E<gt>new> returns before its async connect finishes, so the base's
default (immediately-C<done>) seam would hand back a brand-new handle whose
C<on_connect> has not fired — the very first query on a cold pool then
throws C<not connected> (karr #9). We look up the per-connection readiness
Future registered in L</_create_connection> via
L<DBIO::Storage::PoolBase/_connection_ready_lookup>, falling back to the
base's immediately-C<done> seam for an already-connected (idle-reused)
connection. C<acquire> (inherited, unmodified) chains through this seam for
every connection it hands out, so callers (CRUD, pipeline, C<acquire_txn>)
Just Work without pre-warming.

=head2 _create_connection

Builds one L<EV::Pg> connection from the (already-transformed)
connect info. The pool tracks the returned connection — do not
push it onto L</_connections> yourself.

Wires the connection's readiness Future (see L</_connection_ready_future>):
C<on_connect> resolves it with the connection; an error before connect
fails it, so a dependent query Future fails rather than hanging. After
connect it falls through to the pool's C<on_error>.

=head2 _shutdown_connection

Closes one L<EV::Pg> connection during L<DBIO::Storage::PoolBase/shutdown>.
Errors are swallowed by the caller. The base class clears the connection's
readiness Future from its side table (karr #75) — this override never has
to.

=head2 _transform_conninfo

Renders the stored connect info as a libpq conninfo string via
L<DBIO::PostgreSQL::EV::ConnectInfo/conninfo_string>. Accepts a
hashref, arrayref, or string and returns a single conninfo string.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
