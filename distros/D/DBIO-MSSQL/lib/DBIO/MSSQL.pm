package DBIO::MSSQL;
our $VERSION = '0.900000';


# ABSTRACT: Microsoft SQL Server-specific schema management for DBIO

use strict;
use warnings;

use base 'DBIO::Base';


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::MSSQL::Storage');
  return $self->next::method(@info);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL - Microsoft SQL Server-specific schema management for DBIO

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

    package MySchema;
    use DBIO Schema => -ms;

    # ... later
    my $schema = MySchema->connect($dsn, $user, $pass);
    # Storage is automatically set to DBIO::MSSQL::Storage

=head1 DESCRIPTION

This class is a thin L<DBIO> subclass that automatically sets the storage
class to L<DBIO::MSSQL::Storage> when a connection is established. Load it
into your schema instead of the base L<DBIO> class when connecting to
Microsoft SQL Server databases.

The C<-ms> shortcut (see L<DBIO::Shortcut::ms>) is the recommended way to
enable the MSSQL driver: on a schema class C<use DBIO 'Schema', -ms;> pins
the storage to L<DBIO::MSSQL::Storage>, and on a result class
C<use DBIO 'Core', -ms;> loads the L<DBIO::MSSQL::Result> component.

For connections via L<DBD::Sybase> (including FreeTDS), see
L<DBIO::MSSQL::Storage::Sybase>.

=head1 METHODS

=head2 connection

    $schema->connection($dsn, $user, $pass, \%attrs);

Sets the storage type to L<DBIO::MSSQL::Storage> before delegating to the
parent C<connection> method.

=head1 SEE ALSO

=over

=item * L<DBIO::MSSQL::Storage> - MSSQL storage implementation

=item * L<DBIO::MSSQL::SQLMaker> - MSSQL SQL dialect

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
