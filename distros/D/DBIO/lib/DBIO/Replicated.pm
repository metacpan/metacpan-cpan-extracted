package DBIO::Replicated;
# ABSTRACT: Replicated storage support for DBIO

use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::Replicated::Storage');
  return $self->next::method(@info);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Replicated - Replicated storage support for DBIO

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DBIO::Replicated');

  my $schema = __PACKAGE__->connect($dsn, $user, $pass, {
    balancer_type => 'DBIO::Replicated::Balancer::First',
  });

  $schema->storage->connect_replicants(
    [ $replica_dsn_1, $user, $pass ],
    [ $replica_dsn_2, $user, $pass ],
  );

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

Overrides L<DBIO/connection> to force C<+DBIO::Replicated::Storage> as
C<storage_type>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
