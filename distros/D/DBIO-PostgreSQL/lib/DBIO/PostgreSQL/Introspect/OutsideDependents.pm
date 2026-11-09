package DBIO::PostgreSQL::Introspect::OutsideDependents;
# ABSTRACT: Introspect what stands on a table, a type or a schema of the model and is not in it

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::PostgreSQL::Introspect ();



# The kinds of relation whose columns can be of a type.
my $COLUMN_RELKINDS = q{'r', 'p', 'f', 'm', 'v', 'c'};

my %PROKIND = (
  f => 'function',
  p => 'procedure',
  a => 'aggregate',
  w => 'window function',
);

my %RELKIND = (
  v => 'view',
  m => 'materialized view',
);

my @SCHEMA_CATALOGS = qw(
  pg_operator pg_opclass pg_opfamily pg_collation pg_conversion
  pg_ts_config pg_ts_dict pg_ts_parser pg_ts_template pg_statistic_ext
);

sub _outside {
  my ($alias) = @_;
  return "AND NOT ($alias.nspname = ANY(\$1))\n      "
    . DBIO::PostgreSQL::Introspect->system_schema_filter($alias);
}

sub fetch {
  my ($class, $dbh, $filter) = @_;
  my %result = ( tables => {}, types => {}, schemas => {} );

  if ($filter && @$filter) {
    $class->_tables($dbh, $filter, $result{tables});
    $class->_types($dbh, $filter, $result{types});
  }
  $class->_schemas($dbh, $filter, $result{schemas});

  return \%result;
}

sub _add {
  my ($into, $key, %entry) = @_;
  push @{ $into->{$key} }, \%entry;
}

sub _rows {
  my ($dbh, $sql, @bind) = @_;
  return $dbh->selectall_arrayref($sql, { Slice => {} }, @bind);
}

sub _tables {
  my ($class, $dbh, $filter, $into) = @_;
  my $key = sub { DBIO::PostgreSQL::Introspect->qualified_key(@_) };

  my $views = q{
    SELECT DISTINCT rn.nspname AS schema_name, r.relname AS table_name,
           v.relkind AS dep_kind, vn.nspname AS dep_schema, v.relname AS dep_name
    FROM pg_catalog.pg_class r
    JOIN pg_catalog.pg_namespace rn ON rn.oid = r.relnamespace
    JOIN pg_catalog.pg_depend d
      ON d.refclassid = 'pg_catalog.pg_class'::pg_catalog.regclass
     AND d.refobjid = r.oid
     AND d.classid = 'pg_catalog.pg_rewrite'::pg_catalog.regclass
    JOIN pg_catalog.pg_rewrite rw ON rw.oid = d.objid
    JOIN pg_catalog.pg_class v ON v.oid = rw.ev_class AND v.oid <> r.oid
    JOIN pg_catalog.pg_namespace vn ON vn.oid = v.relnamespace
    WHERE r.relkind IN ('r', 'p', 'f')
      AND v.relkind IN ('v', 'm')
      AND rn.nspname = ANY($1)
      } . _outside('vn')
    . DBIO::PostgreSQL::Introspect->extension_member_filter('pg_class', 'v.oid')
    . q{ ORDER BY 1, 2, 4, 5};
  for my $row (@{ _rows($dbh, $views, $filter) }) {
    _add($into, $key->(@{$row}{qw( schema_name table_name )}),
      kind => $RELKIND{ $row->{dep_kind} }, name => $key->(@{$row}{qw( dep_schema dep_name )}));
  }

  my $foreign_keys = q{
    SELECT rn.nspname AS schema_name, r.relname AS table_name,
           c.conname AS constraint_name, hn.nspname AS on_schema, h.relname AS on_table
    FROM pg_catalog.pg_constraint c
    JOIN pg_catalog.pg_class r ON r.oid = c.confrelid
    JOIN pg_catalog.pg_namespace rn ON rn.oid = r.relnamespace
    JOIN pg_catalog.pg_class h ON h.oid = c.conrelid
    JOIN pg_catalog.pg_namespace hn ON hn.oid = h.relnamespace
    WHERE c.contype = 'f'
      AND rn.nspname = ANY($1)
      } . _outside('hn')
    . q{ ORDER BY 1, 2, 4, 5, 3};
  for my $row (@{ _rows($dbh, $foreign_keys, $filter) }) {
    _add($into, $key->(@{$row}{qw( schema_name table_name )}),
      kind => 'foreign key', name => $row->{constraint_name},
      on => $key->(@{$row}{qw( on_schema on_table )}));
  }

  my $children = q{
    SELECT rn.nspname AS schema_name, r.relname AS table_name,
           ch.relispartition AS is_partition, cn.nspname AS child_schema, ch.relname AS child_name
    FROM pg_catalog.pg_inherits i
    JOIN pg_catalog.pg_class r ON r.oid = i.inhparent
    JOIN pg_catalog.pg_namespace rn ON rn.oid = r.relnamespace
    JOIN pg_catalog.pg_class ch ON ch.oid = i.inhrelid
    JOIN pg_catalog.pg_namespace cn ON cn.oid = ch.relnamespace
    WHERE rn.nspname = ANY($1)
      } . _outside('cn')
    . q{ ORDER BY 1, 2, 4, 5};
  for my $row (@{ _rows($dbh, $children, $filter) }) {
    _add($into, $key->(@{$row}{qw( schema_name table_name )}),
      kind => ($row->{is_partition} ? 'partition' : 'inheriting table'),
      name => $key->(@{$row}{qw( child_schema child_name )}));
  }
}

sub _types {
  my ($class, $dbh, $filter, $into) = @_;
  my $key = sub { DBIO::PostgreSQL::Introspect->qualified_key(@_) };
  my $ext_type = DBIO::PostgreSQL::Introspect->extension_member_filter('pg_type', 't.oid');

  my $columns = qq{
    SELECT DISTINCT tn.nspname AS schema_name, t.typname AS type_name,
           cn.nspname AS rel_schema, c.relname AS rel_name, a.attname AS column_name
    FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace tn ON tn.oid = t.typnamespace
    JOIN pg_catalog.pg_attribute a
      ON a.atttypid = ANY(ARRAY[t.oid, t.typarray]) AND a.attnum > 0 AND NOT a.attisdropped
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid AND c.oid <> t.typrelid
    JOIN pg_catalog.pg_namespace cn ON cn.oid = c.relnamespace
    WHERE tn.nspname = ANY(\$1)
      AND (t.typtype IN ('e', 'r')
           OR (t.typtype = 'c' AND EXISTS (
                 SELECT 1 FROM pg_catalog.pg_class tc WHERE tc.oid = t.typrelid AND tc.relkind = 'c')))
      AND c.relkind IN ($COLUMN_RELKINDS)
      } . _outside('cn') . $ext_type
    . DBIO::PostgreSQL::Introspect->extension_member_filter('pg_class', 'c.oid')
    . q{ ORDER BY 1, 2, 3, 4, 5};
  for my $row (@{ _rows($dbh, $columns, $filter) }) {
    _add($into, $key->(@{$row}{qw( schema_name type_name )}),
      kind => 'column',
      name => join '.', @{$row}{qw( rel_schema rel_name column_name )});
  }

  my $routines = q{
    SELECT DISTINCT tn.nspname AS schema_name, t.typname AS type_name,
           p.prokind AS prokind, p.oid::pg_catalog.regprocedure::pg_catalog.text AS routine
    FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace tn ON tn.oid = t.typnamespace
    JOIN pg_catalog.pg_proc p
      ON p.prorettype = ANY(ARRAY[t.oid, t.typarray])
      OR p.proargtypes::pg_catalog.oid[] && ARRAY[t.oid, t.typarray]
      OR p.proallargtypes && ARRAY[t.oid, t.typarray]
    JOIN pg_catalog.pg_namespace pn ON pn.oid = p.pronamespace
    WHERE tn.nspname = ANY($1)
      AND (t.typtype IN ('e', 'r')
           OR (t.typtype = 'c' AND EXISTS (
                 SELECT 1 FROM pg_catalog.pg_class tc WHERE tc.oid = t.typrelid AND tc.relkind = 'c')))
      } . _outside('pn') . $ext_type
    . DBIO::PostgreSQL::Introspect->extension_member_filter('pg_proc', 'p.oid')
    . q{ ORDER BY 1, 2, 4};
  for my $row (@{ _rows($dbh, $routines, $filter) }) {
    _add($into, $key->(@{$row}{qw( schema_name type_name )}),
      kind => $PROKIND{ $row->{prokind} } // 'function', name => $row->{routine});
  }

  my $domains = q{
    SELECT DISTINCT tn.nspname AS schema_name, t.typname AS type_name,
           dn.nspname AS dom_schema, d.typname AS dom_name
    FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace tn ON tn.oid = t.typnamespace
    JOIN pg_catalog.pg_type d ON d.typtype = 'd' AND d.typbasetype = ANY(ARRAY[t.oid, t.typarray])
    JOIN pg_catalog.pg_namespace dn ON dn.oid = d.typnamespace
    WHERE tn.nspname = ANY($1)
      AND (t.typtype IN ('e', 'r')
           OR (t.typtype = 'c' AND EXISTS (
                 SELECT 1 FROM pg_catalog.pg_class tc WHERE tc.oid = t.typrelid AND tc.relkind = 'c')))
      } . _outside('dn') . $ext_type
    . DBIO::PostgreSQL::Introspect->extension_member_filter('pg_type', 'd.oid')
    . q{ ORDER BY 1, 2, 3, 4};
  for my $row (@{ _rows($dbh, $domains, $filter) }) {
    _add($into, $key->(@{$row}{qw( schema_name type_name )}),
      kind => 'domain', name => $key->(@{$row}{qw( dom_schema dom_name )}));
  }
}

sub _schemas {
  my ($class, $dbh, $filter, $into) = @_;
  my @bind = $filter && @$filter ? ($filter) : ();
  my $scope = @bind ? 'AND n.nspname = ANY($1)' : '';
  my $system = DBIO::PostgreSQL::Introspect->system_schema_filter('n');

  my $domains = qq{
    SELECT n.nspname AS schema_name, t.typname AS dom_name
    FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typtype = 'd'
      $scope
      $system
      } . DBIO::PostgreSQL::Introspect->extension_member_filter('pg_type', 't.oid')
    . q{ ORDER BY 1, 2};
  for my $row (@{ _rows($dbh, $domains, @bind) }) {
    _add($into, $row->{schema_name}, kind => 'domain',
      name => DBIO::PostgreSQL::Introspect->qualified_key(@{$row}{qw( schema_name dom_name )}));
  }

  my $classes = join ', ', map { "'pg_catalog.$_'::pg_catalog.regclass" } @SCHEMA_CATALOGS;
  my $others = qq{
    SELECT n.nspname AS schema_name,
           pg_catalog.pg_describe_object(d.classid, d.objid, d.objsubid) AS description
    FROM pg_catalog.pg_depend d
    JOIN pg_catalog.pg_namespace n
      ON n.oid = d.refobjid AND d.refclassid = 'pg_catalog.pg_namespace'::pg_catalog.regclass
    WHERE d.deptype = 'n'
      AND d.classid IN ($classes)
      $scope
      $system
      AND NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_depend ext_dep
        WHERE ext_dep.classid = d.classid AND ext_dep.objid = d.objid AND ext_dep.deptype = 'e')
    ORDER BY 1, 2
  };
  for my $row (@{ _rows($dbh, $others, @bind) }) {
    _add($into, $row->{schema_name}, name => $row->{description});
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::OutsideDependents - Introspect what stands on a table, a type or a schema of the model and is not in it

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The model is bounded by the schema filter (C<pg_schemas>). A drop the diff
writes (C<DROP TABLE>, C<DROP TYPE>, C<DROP SCHEMA>, all without C<CASCADE>)
meets whatever depends on the object, and the diff has taken out of the way
only what the model holds. This section names the rest, so that
L<DBIO::PostgreSQL::Diff::Dependents> can refuse the drop by name instead of
leaving it to the server.

Without a schema filter every schema is in the model, so there is no table and
no type with a dependent outside it: only the C<schemas> part is read there.

=head1 METHODS

=head2 fetch

    my $dependents = DBIO::PostgreSQL::Introspect::OutsideDependents->fetch($dbh, $filter);

Returns a hashref with three keys, each a hashref from the key of an object of
the model to an ArrayRef of its dependents:

=over 4

=item * C<tables>, keyed by C<schema.table> -- for a table, a partitioned table
or a foreign table in the filter: the views and materialized views in a schema
outside it that read the table (C<view>, C<materialized view>), the foreign keys
of tables outside it that point at it (C<foreign key>, named with the table that
holds it in C<on>), and the partitions and inheriting tables outside it
(C<partition>, C<inheriting table>)

=item * C<types>, keyed by C<schema.type> -- for an enum, a composite type or a
range type in the filter: the columns of relations outside the filter that are of
the type or an array of it (C<column>, C<schema.relation.column>), the functions,
procedures and aggregates outside it that take or return it (C<function>,
C<procedure>, C<aggregate>, C<window function>) and the domains over it
(C<domain>)

=item * C<schemas>, keyed by the name of the schema -- for every schema in the
filter, or in the database where there is none: what stands in it and is of a
kind the model does not hold (C<domain>, C<operator>, C<collation>, C<operator
class>, C<operator family>, C<conversion>, C<statistics object> and the
C<text search ...> kinds), as the server describes it

=back

An entry is a hashref with C<name>, C<kind> and, for a foreign key, C<on>. An object
of C<schemas> that is no domain has the description the server gives for it
(C<pg_describe_object>, kind included) as its C<name> and no C<kind>. An entry carries
names only. System schemas and what an extension owns are left out;
only the direct dependents are listed, not the objects that stand on them.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
