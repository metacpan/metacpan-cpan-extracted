package DBIO::MySQL::Async::Pool;
# ABSTRACT: EV::MariaDB connection pool for DBIO

use strict;
use warnings;
use base 'DBIO::Storage::PoolBase';



sub _create_connection {
  my ($self, $conninfo) = @_;
  require EV::MariaDB;
  my %args = ref($conninfo) eq 'HASH' ? %$conninfo : ( conninfo => $conninfo );

  return EV::MariaDB->new(
    %args,
    on_connect => sub {},
    on_error   => $self->{on_error},
  );
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

DBIO::MySQL::Async::Pool - EV::MariaDB connection pool for DBIO

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  my $pool = DBIO::MySQL::Async::Pool->new(
      conninfo => { host => 'localhost', database => 'myapp', user => 'myapp' },
      size     => 10,
      on_error => sub { warn $_[0] },
  );

  my $mdb = $pool->acquire;       # get idle connection
  $pool->release($mdb);           # return to pool
  my $mdb = $pool->acquire_txn;   # pinned for transaction

=head1 DESCRIPTION

Connection pool for L<DBIO::MySQL::Async::Storage>. Manages a pool of
L<EV::MariaDB> connections, dispatching queries to available connections
and queuing when all are busy.

The acquire / release / capacity / shutdown mechanics are inherited from
L<DBIO::Storage::PoolBase>; this class supplies only the EV::MariaDB
seam — see L</_create_connection> and L</_shutdown_connection>.

=head1 METHODS

=head2 _create_connection

Builds one L<EV::MariaDB> connection from the (already-transformed)
connect info. Accepts a hashref of L<EV::MariaDB> named parameters or
a plain string (passed as the C<conninfo> argument). The pool tracks
the returned connection — do not push it onto L</_connections>
yourself.

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
