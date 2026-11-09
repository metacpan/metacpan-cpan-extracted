package DBIO::PostgreSQL::PostGIS::Introspect;
# ABSTRACT: Stub: the geometry metadata of a column is annotated by DBIO::PostgreSQL::PostGIS::Extension

use strict;
use warnings;

our $VERSION = '0.900004';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Introspect - Stub: the geometry metadata of a column is annotated by DBIO::PostgreSQL::PostGIS::Extension

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

This class is a stub and carries no code. It used to be a subclass of
L<DBIO::PostgreSQL::Introspect> that parsed the C<data_type> of geometry and
geography columns into C<geometry_type> and C<srid>, composed with the
introspectors of other extensions into synthesised classes. ADR 0066 replaces
that: no introspector class is synthesised, and the metadata is the
C<annotate> phase of L<DBIO::PostgreSQL::PostGIS::Extension>, which gives
C<base_type>, C<geometry_type> and C<srid> of a column whose type lives in the
PostGIS schema.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
