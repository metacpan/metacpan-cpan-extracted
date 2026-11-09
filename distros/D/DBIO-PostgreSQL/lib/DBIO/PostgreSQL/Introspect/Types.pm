package DBIO::PostgreSQL::Introspect::Types;
# ABSTRACT: Introspect PostgreSQL types (enums, composites, ranges)

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $types = {};

  $class->_fetch_enums($dbh, $filter, $types);
  $class->_fetch_composites($dbh, $filter, $types);
  $class->_fetch_ranges($dbh, $filter, $types);

  return $types;
}

sub _fetch_enums {
  my ($class, $dbh, $filter, $types) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      t.typname AS type_name,
      array_agg(e.enumlabel ORDER BY e.enumsortorder)
        FILTER (WHERE e.enumlabel IS NOT NULL) AS enum_values
    FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    LEFT JOIN pg_catalog.pg_enum e ON e.enumtypid = t.oid
    WHERE t.typtype = 'e'
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_type', 't.oid');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' GROUP BY n.nspname, t.typname ORDER BY n.nspname, t.typname';

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  while (my $row = $sth->fetchrow_hashref) {
    my $key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    # DBD::Pg returns array_agg as a string like {val1,val2}
    my $values = $row->{enum_values} // [];
    $values = DBIO::PostgreSQL::Introspect->normalize_array($values)
      if !ref $values;
    $types->{$key} = {
      schema_name => $row->{schema_name},
      type_name   => $row->{type_name},
      type_kind   => 'enum',
      values      => $values,
    };
  }
}

sub _fetch_composites {
  my ($class, $dbh, $filter, $types) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      t.typname AS type_name,
      a.attname AS attr_name,
      a.attnum AS ordinal,
      pg_catalog.format_type(a.atttypid, a.atttypmod) AS attr_type,
      CASE WHEN a.attcollation <> 0 AND a.attcollation <> att.typcollation THEN (
        SELECT pg_catalog.quote_ident(cn.nspname) || '.' || pg_catalog.quote_ident(co.collname)
        FROM pg_catalog.pg_collation co
        JOIN pg_catalog.pg_namespace cn ON cn.oid = co.collnamespace
        WHERE co.oid = a.attcollation) END AS attr_collation
    FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    JOIN pg_catalog.pg_class c ON c.oid = t.typrelid
    LEFT JOIN pg_catalog.pg_attribute a
      ON a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped
    LEFT JOIN pg_catalog.pg_type att ON att.oid = a.atttypid
    WHERE t.typtype = 'c'
      AND c.relkind = 'c'
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_type', 't.oid');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' ORDER BY n.nspname, t.typname, a.attnum';

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  while (my $row = $sth->fetchrow_hashref) {
    my $key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    $types->{$key} //= {
      schema_name => $row->{schema_name},
      type_name   => $row->{type_name},
      type_kind   => 'composite',
      attributes  => [],
    };
    next unless defined $row->{attr_name};
    push @{ $types->{$key}{attributes} }, {
      name    => $row->{attr_name},
      type    => $row->{attr_type},
      ordinal => $row->{ordinal},
      ( defined $row->{attr_collation} ? (collation => $row->{attr_collation}) : () ),
    };
  }
}

sub _fetch_ranges {
  my ($class, $dbh, $filter, $types) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      t.typname AS type_name,
      pg_catalog.format_type(r.rngsubtype, NULL) AS subtype,
      CASE WHEN r.rngcollation <> 0 AND r.rngcollation <> st.typcollation THEN (
        SELECT pg_catalog.quote_ident(cn.nspname) || '.' || pg_catalog.quote_ident(co.collname)
        FROM pg_catalog.pg_collation co
        JOIN pg_catalog.pg_namespace cn ON cn.oid = co.collnamespace
        WHERE co.oid = r.rngcollation) END AS collation,
      CASE WHEN NOT oc.opcdefault THEN (
        SELECT pg_catalog.quote_ident(opn.nspname) || '.' || pg_catalog.quote_ident(oc.opcname)
        FROM pg_catalog.pg_namespace opn WHERE opn.oid = oc.opcnamespace) END AS subtype_opclass,
      CASE WHEN r.rngcanonical <> 0 THEN (
        SELECT pg_catalog.quote_ident(pn.nspname) || '.' || pg_catalog.quote_ident(pp.proname)
        FROM pg_catalog.pg_proc pp
        JOIN pg_catalog.pg_namespace pn ON pn.oid = pp.pronamespace
        WHERE pp.oid = r.rngcanonical) END AS canonical,
      CASE WHEN r.rngsubdiff <> 0 THEN (
        SELECT pg_catalog.quote_ident(pn.nspname) || '.' || pg_catalog.quote_ident(pp.proname)
        FROM pg_catalog.pg_proc pp
        JOIN pg_catalog.pg_namespace pn ON pn.oid = pp.pronamespace
        WHERE pp.oid = r.rngsubdiff) END AS subtype_diff
    FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    JOIN pg_catalog.pg_range r ON r.rngtypid = t.oid
    JOIN pg_catalog.pg_type st ON st.oid = r.rngsubtype
    JOIN pg_catalog.pg_opclass oc ON oc.oid = r.rngsubopc
    WHERE 1=1
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_type', 't.oid');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' ORDER BY n.nspname, t.typname';

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  while (my $row = $sth->fetchrow_hashref) {
    my $key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    $types->{$key} = {
      schema_name => $row->{schema_name},
      type_name   => $row->{type_name},
      type_kind   => 'range',
      subtype     => $row->{subtype},
      map { defined $row->{$_} ? ($_ => $row->{$_}) : () }
        qw( collation subtype_opclass canonical subtype_diff ),
    };
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Types - Introspect PostgreSQL types (enums, composites, ranges)

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches user-defined type metadata from C<pg_catalog>: enum types (with
ordered values), composite types (with attributes), and range types (with
subtype). System types are excluded, and so are the types an installed
extension owns (a C<pg_depend> row of deptype C<e>): C<CREATE EXTENSION> /
C<DROP EXTENSION> own them, so they are not the schema's to create or drop.

=head1 METHODS

=head2 fetch

    my $types = DBIO::PostgreSQL::Introspect::Types->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.type_name>. Each value is a hashref with
C<schema_name>, C<type_name>, C<type_kind> (C<enum>, C<composite>, or
C<range>), and kind-specific fields:

=over 4

=item enum: C<values> (ArrayRef, sorted by C<enumsortorder>; empty for an enum
without values)

=item composite: C<attributes> (ArrayRef of C<{ name, type, ordinal }>, and
C<collation> where the attribute has one other than its type's default; empty
for a composite type without attributes)

=item range: C<subtype> (subtype name string), and, only where the type sets
it, C<collation>, C<subtype_opclass> (an operator class that is not the
subtype's default), C<canonical> and C<subtype_diff> (functions)

=back

A collation, operator class or function is written with its schema, each part
quoted by the server's rule (C<pg_catalog.float8mi>, C<pg_catalog."C">), so
that the text can be put into a C<CREATE TYPE> as it is. A key the type does
not set is not in the entry; the diff takes a missing key and an undefined
one for the same
(L<DBIO::PostgreSQL::Diff::Type/diff>).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
