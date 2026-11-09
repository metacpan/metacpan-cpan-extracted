package DBIO::PostgreSQL::PostGIS::Deploy;
# ABSTRACT: Stub: the PostGIS rules of a deploy live in DBIO::PostgreSQL::PostGIS::Extension

use strict;
use warnings;

our $VERSION = '0.900004';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Deploy - Stub: the PostGIS rules of a deploy live in DBIO::PostgreSQL::PostGIS::Extension

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

This class is a stub and carries no code. It used to be a subclass of
L<DBIO::PostgreSQL::Deploy> that a storage layer answered through
C<dbio_deploy_class>, chained with the deploy classes of other layers, and that
registered a C<USING> hook into L<DBIO::PostgreSQL::Diff::Column>. ADR 0066
replaces that composition with a declared list of extensions that the driver's
Deploy runs: the rules of PostGIS are in L<DBIO::PostgreSQL::PostGIS::Extension>
(geometry metadata of a column, the verdict on a change of the spatial type),
and an application gets them by declaring the extension,

  __PACKAGE__->pg_extensions('postgis');

not by loading a component or a layer. C<dbio_deploy_class> has one owner, the
driver storage.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
