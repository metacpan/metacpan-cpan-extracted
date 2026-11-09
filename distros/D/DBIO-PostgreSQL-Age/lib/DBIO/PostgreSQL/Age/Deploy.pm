package DBIO::PostgreSQL::Age::Deploy;
# ABSTRACT: Stub: the deploy rules of Apache AGE live in DBIO::PostgreSQL::Age::Extension

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::PostgreSQL::Deploy';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Age::Deploy - Stub: the deploy rules of Apache AGE live in DBIO::PostgreSQL::Age::Extension

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

A stub (ADR 0066 section 4 of DBIO core). It adds nothing to
L<DBIO::PostgreSQL::Deploy>: no rules, no introspector, no storage hook.

What this class used to do -- keep the graph schemas of Apache AGE in the
deploy model and out of every C<DROP> -- is done by
L<DBIO::PostgreSQL::Age::Extension>, which the driver runs for a schema that
declares C<< __PACKAGE__->pg_extensions('age') >>. The storage no longer names
a deploy class of its own (C<dbio_deploy_class> belongs to the driver storage),
so nothing selects this class; it stays so that the name loads.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
