package DBIO::PostgreSQL::Introspect::Columns;
# ABSTRACT: Introspect PostgreSQL table columns

use strict;
use warnings;

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      c.relname AS table_name,
      a.attname AS column_name,
      a.attnum AS ordinal,
      pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
      a.attnotnull AS not_null,
      pg_catalog.pg_get_expr(d.adbin, d.adrelid) AS default_value,
      a.attidentity AS identity,
      a.attgenerated AS generated,
      col_description(c.oid, a.attnum) AS comment,
      t.typtype AS type_category,
      CASE WHEN t.typtype = 'e' THEN t.typname END AS enum_type,
      CASE WHEN t.typtype = 'c' THEN t.typname END AS composite_type,
      tn.nspname AS type_schema
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_catalog.pg_type t ON t.oid = a.atttypid
    JOIN pg_catalog.pg_namespace tn ON tn.oid = t.typnamespace
    LEFT JOIN pg_catalog.pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
    WHERE a.attnum > 0
      AND NOT a.attisdropped
      AND c.relkind IN ('r', 'v', 'm', 'f', 'p')
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' ORDER BY n.nspname, c.relname, a.attnum';

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %columns;
  while (my $row = $sth->fetchrow_hashref) {
    my $table_key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    push @{ $columns{$table_key} }, {
      column_name    => $row->{column_name},
      ordinal        => $row->{ordinal},
      data_type      => $row->{data_type},
      not_null       => $row->{not_null} ? 1 : 0,
      default_value  => $row->{default_value},
      identity       => $row->{identity},
      generated      => $row->{generated},
      comment        => $row->{comment},
      type_category  => $row->{type_category},
      enum_type      => $row->{enum_type},
      composite_type => $row->{composite_type},
      type_schema    => $row->{type_schema},
    };
  }

  return \%columns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Columns - Introspect PostgreSQL table columns

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches column metadata for all tables from C<pg_catalog.pg_attribute>,
including data types (via C<format_type>), nullability, default expressions,
identity/generated column markers, and enum/composite type names.

=head1 METHODS

=head2 fetch

    my $columns = DBIO::PostgreSQL::Introspect::Columns->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.table>. Each value is an ArrayRef of
column hashrefs ordered by C<attnum>. Each column hashref has keys:
C<column_name>, C<ordinal>, C<data_type>, C<not_null>, C<default_value>,
C<identity>, C<generated>, C<comment>, C<type_category>, C<enum_type>,
C<composite_type>, C<type_schema>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
