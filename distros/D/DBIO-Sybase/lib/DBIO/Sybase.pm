package DBIO::Sybase;
our $VERSION = '0.900000';
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

version 0.900000

=head1 SYNOPSIS

    package MySchema;
    use DBIO Schema => -syb;

    # ... later ...
    my $schema = MySchema->connect($dsn, $user, $pass);
    # Storage is automatically set to DBIO::Sybase::Storage

=head1 DESCRIPTION

This class is a thin L<DBIO> subclass that automatically sets the storage
class to L<DBIO::Sybase::Storage> when a connection is established. Load it
into your schema instead of the base L<DBIO> class when connecting to Sybase
databases.

The recommended way to load the driver is the C<-syb> shortcut
(L<DBIO::Shortcut::syb>):

    use DBIO 'Schema', -syb;

which pins L<DBIO::Sybase::Storage> as the schema's C<storage_type>.

The storage will introspect the connected server type and rebless itself into
the appropriate subclass: L<DBIO::Sybase::Storage::ASE> for Sybase ASE
servers, or L<DBIO::MSSQL::Storage::Sybase> for Microsoft SQL Server accessed
via L<DBD::Sybase>.

=head1 METHODS

=head2 connection

    $schema->connection($dsn, $user, $pass, \%attrs);

Sets the storage type to L<DBIO::Sybase::Storage> before delegating to the
parent C<connection> method.

=head1 SEE ALSO

=over

=item * L<DBIO::Sybase::Storage> - Sybase storage dispatcher

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
