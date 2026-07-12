package DBIO::PostgreSQL::PostGIS::Deploy;
# ABSTRACT: Deploy orchestrator for PostGIS-enabled PostgreSQL schemas

use strict;
use warnings;

use base 'DBIO::PostgreSQL::Deploy';

use DBIO::PostgreSQL::PostGIS::Introspect;


sub _introspect_class { 'DBIO::PostgreSQL::PostGIS::Introspect' }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Deploy - Deploy orchestrator for PostGIS-enabled PostgreSQL schemas

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Subclass of L<DBIO::PostgreSQL::Deploy> that swaps in
L<DBIO::PostgreSQL::PostGIS::Introspect> so geometry column metadata
(C<geometry_type>, C<srid>) is correctly captured during both live-DB
and temp-DB introspection.

Activated automatically when L<DBIO::PostgreSQL::PostGIS::Storage> is
the active storage class via C<dbio_deploy_class>.

The orchestration itself (install/apply/upgrade/diff, temp-database
lifecycle) is inherited unchanged from L<DBIO::PostgreSQL::Deploy>, which
in turn derives from L<DBIO::Deploy::Base::TempDatabase>. This class only
swaps the introspector via L</_introspect_class>.

B<Deploying geometry columns:> C<diff> builds its target model by
deploying the schema into a freshly created temp database. That database
does not inherit the PostGIS extension, so a schema with C<geometry>/
C<geography> columns must declare the extension so the install DDL emits
C<CREATE EXTENSION>:

  __PACKAGE__->pg_extensions('postgis');

Without it the temp-database deploy fails with C<type "geometry" does not
exist>.

=head1 METHODS

=head2 _introspect_class

Override: returns L<DBIO::PostgreSQL::PostGIS::Introspect> so geometry
column metadata (C<geometry_type>, C<srid>) is captured during both
live-DB and temp-DB introspection. The inherited C<_new_introspect>
(from L<DBIO::PostgreSQL::Deploy>) instantiates this class with the
correct C<schema_filter> derived from C<< $schema->pg_schemas >>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
