package DBIO::PostgreSQL::Introspect::Schemas;
# ABSTRACT: Introspect PostgreSQL schemas (namespaces)

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      n.oid AS schema_oid,
      pg_catalog.obj_description(n.oid, 'pg_namespace') AS comment
    FROM pg_catalog.pg_namespace n
    WHERE 1=1
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_namespace', 'n.oid');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' ORDER BY n.nspname';

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %schemas;
  while (my $row = $sth->fetchrow_hashref) {
    $schemas{ $row->{schema_name} } = {
      oid     => $row->{schema_oid},
      comment => $row->{comment},
    };
  }

  return \%schemas;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Schemas - Introspect PostgreSQL schemas (namespaces)

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches PostgreSQL schema (namespace) metadata from C<pg_catalog.pg_namespace>.
System schemas (C<pg_*> and C<information_schema>) are excluded, and so is a
schema an installed extension owns (a C<pg_depend> row of deptype C<e>): one
the extension's script created, which C<DROP EXTENSION> takes with it. A
schema C<CREATE EXTENSION> itself creates because the control file names it
(C<schema = ...>) is not owned by the extension -- C<DROP EXTENSION> leaves it
behind -- and is reported like any other. The dependency runs the other way,
the extension on the schema, which is why L<DBIO::PostgreSQL::Diff> creates a
schema ahead of the extensions and drops it after them
(L<DBIO::PostgreSQL::Diff/ORDER OF OPERATIONS>).

=head1 METHODS

=head2 fetch

    my $schemas = DBIO::PostgreSQL::Introspect::Schemas->fetch($dbh, $filter);

Returns a hashref keyed by schema name. Each value is a hashref with keys
C<oid> and C<comment>. Pass an optional ArrayRef as C<$filter> to restrict
to specific schema names.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
