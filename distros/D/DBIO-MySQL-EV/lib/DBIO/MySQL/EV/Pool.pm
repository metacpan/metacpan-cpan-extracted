package DBIO::MySQL::EV::Pool;
# ABSTRACT: EV::MariaDB connection pool for DBIO

use strict;
use warnings;
use base 'DBIO::Storage::PoolBase';



sub _create_connection {
  my ($self, $conninfo) = @_;
  my %args = ref($conninfo) eq 'HASH' ? %$conninfo : ( conninfo => $conninfo );

  my $ready = $self->future_class->new;
  my $on_error = $self->{on_error};
  my $conn;
  $conn = $self->_new_ev_mariadb(
    %args,
    on_connect => sub { $ready->done($conn) unless $ready->is_ready },
    on_error   => sub {
      $ready->fail($_[0]) unless $ready->is_ready;
      $on_error->(@_);
    },
  );
  $self->_register_connection_ready($conn, $ready);
  return $conn;
}

# Construct the underlying EV::MariaDB handle. Isolated so the readiness
# wiring in _create_connection can be unit-tested with a fake connection
# (t/08), mirroring dbio-postgresql-ev's _new_ev_pg seam.
sub _new_ev_mariadb {
  my ($self, %args) = @_;
  require EV::MariaDB;
  return EV::MariaDB->new(%args);
}


sub _connection_ready_future {
  my ($self, $conn) = @_;
  return $self->future_class->done($conn) if $conn->is_connected;
  return $self->_connection_ready_lookup($conn) || $self->future_class->done($conn);
}


sub _shutdown_connection {
  my ($self, $mdb) = @_;
  $mdb->close_async;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::EV::Pool - EV::MariaDB connection pool for DBIO

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  my $pool = DBIO::MySQL::EV::Pool->new(
      conninfo => { host => 'localhost', database => 'myapp', user => 'myapp' },
      size     => 10,
      on_error => sub { warn $_[0] },
  );

  my $mdb = $pool->acquire;       # get idle connection
  $pool->release($mdb);           # return to pool
  my $mdb = $pool->acquire_txn;   # pinned for transaction

=head1 DESCRIPTION

Connection pool for L<DBIO::MySQL::EV::Storage>. Manages a pool of
L<EV::MariaDB> connections, dispatching queries to available connections
and queuing when all are busy.

The acquire / release / capacity / shutdown mechanics, including the
connection-readiness gate, are inherited from L<DBIO::Storage::PoolBase>;
this class supplies only the EV::MariaDB seam — see L</_create_connection>,
L</_connection_ready_future> and L</_shutdown_connection>.

=head1 METHODS

=head2 _create_connection

Builds one L<EV::MariaDB> connection from the (already-transformed)
connect info. Accepts a hashref of L<EV::MariaDB> named parameters or
a plain string (passed as the C<conninfo> argument). The pool tracks
the returned connection — do not push it onto L</_connections>
yourself.

Wires the connection's readiness Future (see L</_connection_ready_future>):
C<on_connect> resolves it with the connection; an error before connect
fails it, so a dependent L<DBIO::Storage::PoolBase/acquire> Future fails
rather than hanging (karr #20).

=head2 _connection_ready_future

Overrides L<DBIO::Storage::PoolBase/_connection_ready_future>: the resolved
Future does not complete until the connection is actually ready for queries.

C<EV::MariaDB-E<gt>new> returns before its async connect finishes, so the
base's default (immediately-C<done>) seam would hand back a brand-new
handle whose C<on_connect> has not fired — the very first bound query on a
cold pool then throws C<not connected> (karr #20; this pool previously
wired C<on_connect =E<gt> sub {}>, a pure no-op, with no readiness tracking
at all). We look up the per-connection readiness Future registered in
L</_create_connection> via L<DBIO::Storage::PoolBase/_connection_ready_lookup>,
falling back to the base's immediately-C<done> seam for an already-connected
(idle-reused) connection.

=head2 _shutdown_connection

Closes one L<EV::MariaDB> connection during L<DBIO::Storage::PoolBase/shutdown>.
Errors are swallowed by the caller.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
