package DBIO::Sybase;
our $VERSION = '0.900004';
# ABSTRACT: Sybase-specific schema management for DBIO

use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::Sybase::Storage');
  return $self->next::method(@info);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase - Sybase-specific schema management for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

    package MySchema;
    use DBIO Schema => -syb;

    # ... later ...
    my $schema = MySchema->connect($dsn, $user, $pass);
    # Storage is DBIO::Sybase::Storage, and at its first use
    # DBIO::Sybase::Storage::ASE

=head1 DESCRIPTION

This class is a schema component that declares the Sybase ASE driver: it sets
the storage class to L<DBIO::Sybase::Storage> when a connection is
established. Load it into your schema when connecting to Sybase ASE.

The recommended way to load the driver is the C<-syb> shortcut
(L<DBIO::Shortcut::syb>):

    use DBIO 'Schema', -syb;

which pins L<DBIO::Sybase::Storage> as the schema's C<storage_type>.

A schema that declares the driver either way has said what its server is. At
the first use that needs the driver -- not at C<connect> -- the storage becomes
L<DBIO::Sybase::Storage::ASE>, without asking the server what it is, and then
adapts to the client library L<DBD::Sybase> was built against: placeholders or
L<DBIO::Sybase::Storage::ASE::NoBindVars>, and the FreeTDS fixups of
L<DBIO::Sybase::Storage::FreeTDS>
(L<DBIO::Sybase::Storage/_adapt_to_access_path>, core ADR 0059).

It never becomes the storage of another product. A server that
L<DBD::Sybase> found to be Microsoft SQL Server is reported as a driver
mismatch -- a warning by default, an error with
L<DBIO::Schema/driver_strict>, nothing with L<DBIO::Schema/driver_warnings>
off; declare L<DBIO::MSSQL> for such a server.

=head1 METHODS

=head2 connection

    $schema->connection($dsn, $user, $pass, \%attrs);

Sets the storage type to L<DBIO::Sybase::Storage> before delegating to the
parent C<connection> method.

=head1 SEE ALSO

=over

=item * L<DBIO::Sybase::Storage> - the storage class this component declares

=item * L<DBIO::Sybase::Storage::ASE> - Sybase ASE storage

=item * L<DBIO::Sybase::Storage::FreeTDS> - FreeTDS connection layer

=item * L<DBIO::MSSQL::Storage::Sybase> - MSSQL via L<DBD::Sybase>

=item * L<DBIO> - Base ORM class

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
