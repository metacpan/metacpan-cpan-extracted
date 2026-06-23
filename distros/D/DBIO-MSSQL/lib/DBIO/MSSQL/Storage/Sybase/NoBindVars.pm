package DBIO::MSSQL::Storage::Sybase::NoBindVars;
# ABSTRACT: Support for Microsoft SQL Server via DBD::Sybase without placeholders

use strict;
use warnings;

use base qw/
  DBIO::Storage::DBI::NoBindVars
  DBIO::MSSQL::Storage::Sybase
/;
use mro 'c3';

use namespace::clean;


sub _init {
  my $self = shift;

  $self->disable_sth_caching(1);

  $self->next::method(@_);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Storage::Sybase::NoBindVars - Support for Microsoft SQL Server via DBD::Sybase without placeholders

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Storage driver for Microsoft SQL Server accessed via L<DBD::Sybase> when your
combination of L<DBD::Sybase> and libraries (most likely FreeTDS) does not
support C<?> style placeholders. L<DBIO::MSSQL::Storage::Sybase> reblesses the
storage into this class automatically on connect when no placeholder support is
detected.

This driver uses L<DBIO::Storage::DBI::NoBindVars> as a base, so bind variables
are interpolated (properly quoted) into the SQL query itself instead of being
passed as placeholders. Because that renders prepared statement caching
useless, caching is explicitly disabled.

In all other respects it behaves as L<DBIO::MSSQL::Storage::Sybase>.

=head1 SEE ALSO

=over

=item * L<DBIO::MSSQL::Storage::Sybase> - MSSQL via L<DBD::Sybase>

=item * L<DBIO::Storage::DBI::NoBindVars> - placeholder-less interpolation base

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
