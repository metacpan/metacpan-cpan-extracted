package DBIO::MySQL::MariaDB;
# ABSTRACT: MariaDB-specific schema management for DBIO

use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::MySQL::Storage::MariaDB');
  return $self->next::method(@info);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::MariaDB - MariaDB-specific schema management for DBIO

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');

  my $schema = MyApp::Schema->connect($dsn, $user, $pass);

=head1 DESCRIPTION

MariaDB-specific schema component for L<DBIO>. Load this component instead
of L<DBIO::MySQL> when connecting to a MariaDB server.

When C<connection()> is called, the storage class is set to
L<DBIO::MySQL::Storage::MariaDB>, which uses the C<mariadb_*> DBD attributes
provided by L<DBD::MariaDB> rather than the C<mysql_*> attributes used by
L<DBD::mysql>.

=head1 METHODS

=head2 connection

Overrides L<DBIO/connection> to set C<storage_type> to
C<+DBIO::MySQL::Storage::MariaDB> before delegating to the parent.

=seealso

=over 4

=item * L<DBIO::MySQL> - MySQL equivalent of this component

=item * L<DBIO::MySQL::Storage::MariaDB> - Storage backend activated by this component

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
