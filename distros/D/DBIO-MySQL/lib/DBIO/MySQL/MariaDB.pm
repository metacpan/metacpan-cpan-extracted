package DBIO::MySQL::MariaDB;
# ABSTRACT: MariaDB-specific schema management for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

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

version 0.900004

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');

  my $schema = MyApp::Schema->connect($dsn, $user, $pass);

=head1 DESCRIPTION

Schema component for L<DBIO> that pins the storage class of the
L<DBD::MariaDB> driver. It makes no statement about the server: MySQL and
MariaDB are told apart from the server itself
(L<DBIO::MySQL::Storage/_is_mariadb>), whether this component or
L<DBIO::MySQL> is loaded.

When C<connection()> is called, the storage class is set to
L<DBIO::MySQL::Storage::MariaDB>, the registration target for the C<MariaDB>
DBI driver (a C<dbi:MariaDB:> DSN). It overrides no behaviour. The C<mysql_*>
or C<mariadb_*> attribute names are chosen per connection by the DBD that owns
the handle (see L<DBIO::MySQL::Storage/_dbd_attribute>), so this component over
a C<dbi:mysql:> DSN keeps using C<mysql_*>.

=head1 METHODS

=head2 connection

Overrides L<DBIO::Schema/connection> to set C<storage_type> to
C<+DBIO::MySQL::Storage::MariaDB> before delegating to the parent.

=head1 SEE ALSO

=pod

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
