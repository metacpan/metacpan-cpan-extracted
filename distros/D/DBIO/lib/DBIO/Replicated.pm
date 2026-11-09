package DBIO::Replicated;
# ABSTRACT: Replicated storage support for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;

  # The master and every replicant are storages of the declared driver
  # (ADR 0067), read before the storage class becomes the replicated one. A
  # repeated connect finds the replicated storage_type set here, and the
  # driver in its arguments.
  my ($declared, $args) = $self->_resolved_storage_type;
  my $replicated = $declared eq 'DBIO::Replicated::Storage';
  my $backend = $replicated ? ($args || {})->{backend_storage_class} : $declared;

  # backend_storage_class in the connect info wins, and is a declaration too.
  my $given = grep {
    ref $_ eq 'HASH' && defined $_->{backend_storage_class}
  } @info;

  # A component after this one with a connection() of its own -- a driver
  # component loaded after Replicated -- decides the storage class itself;
  # that order is refused below, naming the class it set.
  my $decided_later = do {
    my @mro = @{ mro::get_linear_isa(ref $self || $self) };
    my ($at) = grep { $mro[$_] eq __PACKAGE__ } 0 .. $#mro;
    no strict 'refs';
    grep { $_ ne 'DBIO::Schema' && defined &{"${_}::connection"} }
      @mro[ $at + 1 .. $#mro ];
  };

  $self->_refuse_undeclared_driver(
    $backend // 'DBIO::Storage::DBI',
    'DBIO::Replicated runs the master and every replicant on the driver the '
  . 'schema declares when it connects: declare it with the shortcut, or load '
  . 'the driver component before Replicated: '
  . 'load_components(qw(PostgreSQL Replicated)).',
  ) unless $given or $decided_later;

  $self->storage_type([ '+DBIO::Replicated::Storage', {
    ( $replicated ? %{ $args || {} } : () ),
    ( defined $backend ? ( backend_storage_class => $backend ) : () ),
  } ]);

  my $ret = $self->next::method(@info);

  if (@info) {
    my $storage = $self->storage;
    if ($storage && !$storage->isa('DBIO::Replicated::Storage')) {
      my $class = ref $storage;
      $self->storage(undef);
      $self->throw_exception(
        "DBIO::Replicated is loaded before the driver component, whose "
      . "storage class ($class) took the place of DBIO::Replicated::Storage "
      . "and left the schema without replication. Load the driver component "
      . "first and Replicated last: "
      . "load_components(qw(PostgreSQL Replicated))"
      );
    }
  }

  return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Replicated - Replicated storage support for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::Schema;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('Replicated');

  my $schema = __PACKAGE__->connect($dsn, $user, $pass, {
    balancer_type => 'DBIO::Replicated::Balancer::First',
  });

  $schema->storage->connect_replicants(
    [ $replica_dsn_1, $user, $pass ],
    [ $replica_dsn_2, $user, $pass ],
  );

See F<t/test/08_replicated.t> for a runnable example.

=head1 DESCRIPTION

L<DBIO::Replicated> is the DBIO core component for replicated storage
setups. It configures the schema to use L<DBIO::Replicated::Storage>,
which then coordinates a master backend plus optional replicant
backends.

Writes, transactions, deploy operations, and other master-only work go
through the master backend. Read-oriented operations are delegated to the
configured balancer, which selects from the active replicants.

For shared test suites, L<DBIO::Test> can wrap a requested backend
storage in replicated mode with:

  my $schema = DBIO::Test->init_schema(
    replicated   => 1,
    storage_type => 'DBIO::MySQL::Storage',
  );

=head1 METHODS

=head2 connection

Overrides L<DBIO::Schema/connection> to force C<+DBIO::Replicated::Storage>
as C<storage_type>.

Replication runs on the driver the schema declares (ADR 0067): the master and
every replicant are storages of that driver. C<connection> reads the declared
driver's storage class before it sets the replicated one and passes it on as
C<backend_storage_class> (L<DBIO::Replicated::Storage/new>); a repeated connect
keeps it. A C<backend_storage_class> in the connect info wins over it. A schema
that declares no driver, and gives no C<backend_storage_class>, is refused
before any storage is built.

The component is loaded after the driver component, so that the driver is
declared when it connects and C<DBIO::Replicated::Storage> is the storage
class the schema ends up with:

  __PACKAGE__->load_components(qw(PostgreSQL Replicated));

A schema whose connect leaves another storage class behind throws,
naming that class and this order.

=head1 READING FROM THE MASTER AND THE REPLICANTS

A replicant answers with the data it has replicated so far; after a write on
the master it may still show the earlier state for a short time (replication
lag). Reads that tolerate this are balanced over the replicants.

Reads that go with a write are answered by the master, so they see what the
writers see:

=over 4

=item * every select inside a transaction on the master

=item * L<DBIO::Row/discard_changes>

=item * L<DBIO::ResultSet/find_or_create>, L<DBIO::ResultSet/find_or_new>,
L<DBIO::ResultSet/update_or_create>, L<DBIO::ResultSet/update_or_new> and the
C<update_or_create> fallback of L<DBIO::ResultSet/upsert>: the lookup carries
C<< force_pool => 'master' >>, supplied by the storage hook
C<_read_pool_for_read_modify_write> (ADR 0076)

=item * every select with a lock, C<< for => 'update' >>, C<< for => 'shared' >>
or any other defined C<for>

=back

A C<force_pool> in the attributes of a search names the pool for that one read
(C<'master'> or the name of a replicant). To run a whole block of reads on the
master, wrap it in L<DBIO::Replicated::Storage/execute_reliably>:

  $schema->storage->execute_reliably(sub {
    my $artist = $schema->resultset('Artist')->find($id);
    ...
  });

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
