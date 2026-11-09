package DBIO::PostgreSQL::Age::Introspect;
# ABSTRACT: Stub: the graph schemas of Apache AGE are claimed by DBIO::PostgreSQL::Age::Extension

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::PostgreSQL::Introspect';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Age::Introspect - Stub: the graph schemas of Apache AGE are claimed by DBIO::PostgreSQL::Age::Extension

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

A stub (ADR 0066 section 4 of DBIO core). It adds nothing to
L<DBIO::PostgreSQL::Introspect>: no C<graphs> section, no filter, and no
introspector class is synthesised beside another extension any more.

The graphs are read by C<inspect> of L<DBIO::PostgreSQL::Age::Extension>
(C<ag_catalog.ag_graph>), and the graph schemas leave the model through its
C<claims>: the driver removes each claimed schema with its tables, columns,
indexes, triggers, keys, sequences, functions and types. The result is the
same -- graph schemas are known to the deploy and never dropped -- and it
holds beside PostGIS in either order.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
