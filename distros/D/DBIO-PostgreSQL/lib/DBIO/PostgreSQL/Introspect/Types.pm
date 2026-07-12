package DBIO::PostgreSQL::Introspect::Types;
# ABSTRACT: Introspect PostgreSQL types (enums, composites, ranges)

use strict;
use warnings;

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
      array_agg(e.enumlabel ORDER BY e.enumsortorder) AS enum_values
    FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    JOIN pg_catalog.pg_enum e ON e.enumtypid = t.oid
    WHERE t.typtype = 'e'
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');

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
    my $values = $row->{enum_values};
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
      pg_catalog.format_type(a.atttypid, a.atttypmod) AS attr_type
    FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    JOIN pg_catalog.pg_class c ON c.oid = t.typrelid
    JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
    WHERE t.typtype = 'c'
      AND c.relkind = 'c'
      AND a.attnum > 0
      AND NOT a.attisdropped
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');

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
    push @{ $types->{$key}{attributes} }, {
      name    => $row->{attr_name},
      type    => $row->{attr_type},
      ordinal => $row->{ordinal},
    };
  }
}

sub _fetch_ranges {
  my ($class, $dbh, $filter, $types) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      t.typname AS type_name,
      pg_catalog.format_type(r.rngsubtype, NULL) AS subtype
    FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    JOIN pg_catalog.pg_range r ON r.rngtypid = t.oid
    WHERE 1=1
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');

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

version 0.900001

=head1 DESCRIPTION

Fetches user-defined type metadata from C<pg_catalog>: enum types (with
ordered values), composite types (with attributes), and range types (with
subtype). System types are excluded.

=head1 METHODS

=head2 fetch

    my $types = DBIO::PostgreSQL::Introspect::Types->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.type_name>. Each value is a hashref with
C<schema_name>, C<type_name>, C<type_kind> (C<enum>, C<composite>, or
C<range>), and kind-specific fields:

=over 4

=item enum: C<values> (ArrayRef, sorted by C<enumsortorder>)

=item composite: C<attributes> (ArrayRef of C<{ name, type, ordinal }>)

=item range: C<subtype> (subtype name string)

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
