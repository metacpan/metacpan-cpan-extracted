package DBIO::PostgreSQL::Async::Pool;
# ABSTRACT: EV::Pg connection pool for DBIO

use strict;
use warnings;
use base 'DBIO::Storage::PoolBase';

use DBIO::PostgreSQL::Async::ConnectInfo 'conninfo_string';



sub _create_connection {
  my ($self, $conninfo) = @_;

  require EV::Pg;
  return EV::Pg->new(
    conninfo   => $conninfo,
    on_connect => sub {},
    on_error   => $self->{on_error},
  );
}


sub _shutdown_connection { $_[1]->finish }


sub _transform_conninfo { conninfo_string($_[1]) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Async::Pool - EV::Pg connection pool for DBIO

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  my $pool = DBIO::PostgreSQL::Async::Pool->new(
      conninfo => 'dbname=myapp',
      size     => 10,
      on_error => sub { warn $_[0] },
  );

  my $pg = $pool->acquire;       # get idle connection
  $pool->release($pg);           # return to pool
  my $pg = $pool->acquire_txn;   # pinned for transaction

=head1 DESCRIPTION

Connection pool for L<DBIO::PostgreSQL::Async::Storage>. Manages a pool of
L<EV::Pg> connections, dispatching queries to available connections
and queuing when all are busy.

The acquire / release / capacity / shutdown mechanics are inherited from
L<DBIO::Storage::PoolBase>; this class supplies only the EV::Pg
seam — see L</_create_connection>, L</_shutdown_connection> and
L</_transform_conninfo>.

=head1 METHODS

=head2 _create_connection

Builds one L<EV::Pg> connection from the (already-transformed)
connect info. The pool tracks the returned connection — do not
push it onto L</_connections> yourself.

=head2 _shutdown_connection

Closes one L<EV::Pg> connection during L<DBIO::Storage::PoolBase/shutdown>.
Errors are swallowed by the caller.

=head2 _transform_conninfo

Renders the stored connect info as a libpq conninfo string via
L<DBIO::PostgreSQL::Async::ConnectInfo/conninfo_string>. Accepts a
hashref, arrayref, or string and returns a single conninfo string.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
