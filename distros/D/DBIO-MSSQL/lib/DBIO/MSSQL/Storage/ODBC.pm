package DBIO::MSSQL::Storage::ODBC;
# ABSTRACT: Support for Microsoft SQL Server via DBD::ODBC

use strict;
use warnings;

use base qw/
  DBIO::Storage::DBI::ODBC
  DBIO::MSSQL::Storage
/;
use mro 'c3';

use namespace::clean;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Storage::ODBC - Support for Microsoft SQL Server via DBD::ODBC

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Storage driver for Microsoft SQL Server accessed via L<DBD::ODBC>
(including FreeTDS-based ODBC connections). Inherits from both
L<DBIO::Storage::DBI::ODBC> and L<DBIO::MSSQL::Storage>.

This is the class an ODBC connection to Microsoft SQL Server is reblessed
into during connector-based driver detection. It carries the transport
helpers from L<DBIO::Storage::DBI::ODBC> (such as C<_using_freetds>) on top
of the transport-neutral MSSQL semantics of L<DBIO::MSSQL::Storage>, without
pulling in any L<DBD::Sybase>-specific code.

=head1 SEE ALSO

=over

=item * L<DBIO::MSSQL> - MSSQL schema component

=item * L<DBIO::MSSQL::Storage> - MSSQL storage base class

=item * L<DBIO::MSSQL::Storage::Sybase> - MSSQL via L<DBD::Sybase>

=item * L<DBIO::Storage::DBI::ODBC> - Base class for ODBC drivers

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
