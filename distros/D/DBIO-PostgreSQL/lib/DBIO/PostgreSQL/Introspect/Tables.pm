package DBIO::PostgreSQL::Introspect::Tables;
# ABSTRACT: Introspect PostgreSQL tables

use strict;
use warnings;

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      c.relname AS table_name,
      c.oid AS table_oid,
      c.relkind AS kind,
      c.relpersistence AS persistence,
      CASE c.relkind
        WHEN 'r' THEN 'table'
        WHEN 'v' THEN 'view'
        WHEN 'm' THEN 'materialized_view'
        WHEN 'f' THEN 'foreign_table'
        WHEN 'p' THEN 'partitioned_table'
      END AS kind_label,
      pg_catalog.obj_description(c.oid, 'pg_class') AS comment,
      c.relrowsecurity AS rls_enabled,
      c.relforcerowsecurity AS rls_forced,
      CASE
        WHEN c.relkind IN ('v', 'm') THEN pg_catalog.pg_get_viewdef(c.oid)
      END AS view_definition
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind IN ('r', 'v', 'm', 'f', 'p')
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' ORDER BY n.nspname, c.relname';

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %tables;
  while (my $row = $sth->fetchrow_hashref) {
    my $key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    $tables{$key} = {
      schema_name => $row->{schema_name},
      table_name  => $row->{table_name},
      oid         => $row->{table_oid},
      kind        => $row->{kind},
      kind_label  => $row->{kind_label},
      persistence => $row->{persistence},
      comment     => $row->{comment},
      rls_enabled => $row->{rls_enabled} ? 1 : 0,
      rls_forced  => $row->{rls_forced} ? 1 : 0,
      view_definition => $row->{view_definition},
    };
  }

  return \%tables;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Tables - Introspect PostgreSQL tables

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches PostgreSQL table (and view, materialized view, foreign table, and
partitioned table) metadata from C<pg_catalog.pg_class>.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::PostgreSQL::Introspect::Tables->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.table>. Each value is a hashref with
keys: C<schema_name>, C<table_name>, C<oid>, C<kind> (pg relkind char),
C<kind_label> (human-readable), C<persistence>, C<comment>, C<rls_enabled>,
C<rls_forced>, C<view_definition>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
