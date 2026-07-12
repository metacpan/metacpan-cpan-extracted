package DBIO::PostgreSQL::Introspect::Indexes;
# ABSTRACT: Introspect PostgreSQL indexes

use strict;
use warnings;

use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Introspect::Parse ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      sn.nspname AS schema_name,
      ct.relname AS table_name,
      ci.relname AS index_name,
      am.amname AS access_method,
      i.indisunique AS is_unique,
      i.indisprimary AS is_primary,
      i.indisvalid AS is_valid,
      pg_catalog.pg_get_indexdef(i.indexrelid) AS definition,
      pg_catalog.pg_get_expr(i.indpred, i.indrelid) AS predicate,
      pg_catalog.pg_get_expr(i.indexprs, i.indrelid) AS expressions,
      array_agg(a.attname ORDER BY k.n) AS column_names,
      ci.reloptions AS storage_params
    FROM pg_catalog.pg_index i
    JOIN pg_catalog.pg_class ci ON ci.oid = i.indexrelid
    JOIN pg_catalog.pg_class ct ON ct.oid = i.indrelid
    JOIN pg_catalog.pg_namespace sn ON sn.oid = ct.relnamespace
    JOIN pg_catalog.pg_am am ON am.oid = ci.relam
    LEFT JOIN LATERAL unnest(i.indkey) WITH ORDINALITY AS k(attnum, n) ON true
    LEFT JOIN pg_catalog.pg_attribute a
      ON a.attrelid = i.indrelid AND a.attnum = k.attnum
    WHERE ct.relkind IN ('r', 'm', 'p')
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('sn');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND sn.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= q{
    GROUP BY sn.nspname, ct.relname, ci.relname, am.amname,
             i.indisunique, i.indisprimary, i.indisvalid,
             i.indexrelid, i.indrelid, i.indpred, i.indexprs,
             ci.reloptions
    ORDER BY sn.nspname, ct.relname, ci.relname
  };

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %indexes;
  while (my $row = $sth->fetchrow_hashref) {
    my $table_key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    my $columns = $row->{column_names};
    if (!ref $columns) {
      my @parts = grep { $_ ne 'NULL' } @{ DBIO::PostgreSQL::Introspect->normalize_array($columns) // [] };
      $columns = \@parts;
    }
    $indexes{$table_key}{ $row->{index_name} } = {
      index_name    => $row->{index_name},
      access_method => $row->{access_method},
      is_unique     => $row->{is_unique} ? 1 : 0,
      is_primary    => $row->{is_primary} ? 1 : 0,
      is_valid      => $row->{is_valid} ? 1 : 0,
      definition    => $row->{definition},
      predicate     => $row->{predicate},
      expressions   => $row->{expressions},
      columns         => $columns,
      include_columns => DBIO::PostgreSQL::Introspect::Parse->include_columns($row->{definition}),
      storage_params  => DBIO::PostgreSQL::Introspect::Parse->storage_params($row->{storage_params}),
    };
  }

  return \%indexes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Indexes - Introspect PostgreSQL indexes

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches index metadata from C<pg_catalog.pg_index>, including access method,
uniqueness, primary key flag, validity, the full index definition string from
C<pg_get_indexdef>, partial index predicates, and expression index expressions.

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::PostgreSQL::Introspect::Indexes->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.table>. Each value is a hashref keyed by
index name. Each index entry has: C<index_name>, C<access_method>, C<is_unique>,
C<is_primary>, C<is_valid>, C<definition> (full C<pg_get_indexdef> output),
C<predicate>, C<expressions>, C<columns> (ArrayRef of column names, empty for
expression-only indexes).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
