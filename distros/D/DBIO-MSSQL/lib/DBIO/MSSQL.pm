package DBIO::MSSQL;
our $VERSION = '0.900004';


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

version 0.900004

=head1 SYNOPSIS

    package MySchema;
    use DBIO Schema => -ms;

    # ... later
    my $schema = MySchema->connect($dsn, $user, $pass);
    # The storage is declared as DBIO::MSSQL::Storage, and at its first use
    # becomes that driver's class for the DBD of the DSN:
    #   dbi:ODBC:...    DBIO::MSSQL::Storage::ODBC
    #   dbi:Sybase:...  DBIO::MSSQL::Storage::Sybase

=head1 DESCRIPTION

This class is the schema component that declares Microsoft SQL Server as the
driver of a schema: it sets the storage class to L<DBIO::MSSQL::Storage> when
a connection is established. Load it into your schema instead of the base
L<DBIO> class when connecting to Microsoft SQL Server databases.

The C<-ms> shortcut (see L<DBIO::Shortcut::ms>) is the recommended way to
enable the MSSQL driver: on a schema class C<use DBIO 'Schema', -ms;> pins
the storage to L<DBIO::MSSQL::Storage>, and on a result class
C<use DBIO 'Core', -ms;> loads the L<DBIO::MSSQL::Result> component.

L<DBIO::MSSQL::Storage> is the class that is declared, and it is the
transport-neutral base: there is no C<DBD::MSSQL>, and SQL Server is reached
through L<DBD::ODBC> or L<DBD::Sybase>. The storage is that class from
C<connect> until its first use; then it adapts itself to the DBD the connect
info leads through (L<DBIO::MSSQL::Storage/_adapt_to_access_path>) and is
L<DBIO::MSSQL::Storage::ODBC> or L<DBIO::MSSQL::Storage::Sybase> from there
on -- both are subclasses of the declared class, and the storage never
becomes the class of another driver. The DBD::Sybase class needs the optional
DBIO::Sybase distribution.

=head1 METHODS

=head2 connection

    $schema->connection($dsn, $user, $pass, \%attrs);

Sets the storage type to L<DBIO::MSSQL::Storage> before delegating to the
parent C<connection> method. That pin declares the driver; which of its
classes the storage ends as is decided at the first use, by the DBD (see
L</DESCRIPTION>).

=head1 SEE ALSO

=over

=item * L<DBIO::MSSQL::Storage> - MSSQL storage implementation

=item * L<DBIO::MSSQL::SQLMaker> - MSSQL SQL dialect

=item * L<DBIO::MSSQL::Storage::ODBC> - MSSQL via L<DBD::ODBC>

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
