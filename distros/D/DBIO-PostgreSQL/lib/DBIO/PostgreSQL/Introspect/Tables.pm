package DBIO::PostgreSQL::Introspect::Tables;
# ABSTRACT: Introspect PostgreSQL tables

use strict;
use warnings;

our $VERSION = '0.900004';

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
      END AS view_definition,
      pn.nspname AS parent_schema,
      pc.relname AS parent_name
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_catalog.pg_inherits i ON c.relispartition AND i.inhrelid = c.oid
    LEFT JOIN pg_catalog.pg_class pc ON pc.oid = i.inhparent
    LEFT JOIN pg_catalog.pg_namespace pn ON pn.oid = pc.relnamespace
    WHERE c.relkind IN ('r', 'v', 'm', 'f', 'p')
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_class', 'c.oid');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' ORDER BY n.nspname, c.relname';

  # pg_get_viewdef writes a relation, a function or a type without its schema
  # whenever the search_path of the asking session finds it, so this is read
  # under an empty one -- inside a model read with qualified_names the whole
  # read is already, and the call runs where it stands.
  my $rows = DBIO::PostgreSQL::Introspect->under_empty_search_path($dbh, sub {
    $dbh->selectall_arrayref($sql, { Slice => {} }, @bind);
  });

  my %tables;
  for my $row (@$rows) {
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
      depends_on         => [],
      depends_on_columns => {},
      inherits           => [],
      partition_of => defined $row->{parent_name}
        ? DBIO::PostgreSQL::Introspect->qualified_key(@{$row}{qw( parent_schema parent_name )})
        : undef,
    };
  }

  my $depends_on = $class->_view_dependencies($dbh, $filter);
  for my $key (grep { $tables{$_} } keys %$depends_on) {
    my $reads = $depends_on->{$key};
    $tables{$key}{depends_on} = [ sort keys %$reads ];
    $tables{$key}{depends_on_columns} = {
      map { $_ => [ sort @{ $reads->{$_} } ] } grep { @{ $reads->{$_} } } keys %$reads
    };
  }

  my $inherits = $class->_inheritance_parents($dbh, $filter);
  for my $key (grep { $tables{$_} } keys %$inherits) {
    $tables{$key}{inherits} = $inherits->{$key};
  }

  return \%tables;
}

# What each view and materialized view reads, as { view key => { relation
# key => [ column names ] } }. A view is its rewrite rule: the rule's
# pg_depend rows name every relation the definition mentions -- one row per
# column used (refobjsubid is its attnum), one row without a column where the
# relation is read as a whole row, and the view itself among them, which is
# left out here. A relation read only as a whole row has no column names.
sub _view_dependencies {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT DISTINCT
      n.nspname AS schema_name,
      c.relname AS table_name,
      rn.nspname AS ref_schema,
      r.relname AS ref_name,
      a.attname AS ref_column
    FROM pg_catalog.pg_rewrite rw
    JOIN pg_catalog.pg_class c ON c.oid = rw.ev_class
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_catalog.pg_depend d
      ON d.classid = 'pg_catalog.pg_rewrite'::pg_catalog.regclass
     AND d.objid = rw.oid
     AND d.refclassid = 'pg_catalog.pg_class'::pg_catalog.regclass
    JOIN pg_catalog.pg_class r ON r.oid = d.refobjid AND r.oid <> c.oid
    JOIN pg_catalog.pg_namespace rn ON rn.oid = r.relnamespace
    LEFT JOIN pg_catalog.pg_attribute a
      ON a.attrelid = d.refobjid AND a.attnum = d.refobjsubid AND d.refobjsubid > 0
    WHERE c.relkind IN ('v', 'm')
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_class', 'c.oid');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %depends_on;
  while (my $row = $sth->fetchrow_hashref) {
    my $view = DBIO::PostgreSQL::Introspect->qualified_key($row);
    my $read = DBIO::PostgreSQL::Introspect->qualified_key(@{$row}{qw( ref_schema ref_name )});
    my $columns = $depends_on{$view}{$read} //= [];
    push @$columns, $row->{ref_column} if defined $row->{ref_column};
  }

  return \%depends_on;
}

# The tables each table inherits from, as { table key => [ parent keys ] } in
# the order of pg_inherits.inhseqno. Partitions are left out: what a partition
# belongs to is partition_of. So are the rows pg_inherits has for the indexes
# of a partitioned table.
sub _inheritance_parents {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      c.relname AS table_name,
      pn.nspname AS parent_schema,
      pc.relname AS parent_name
    FROM pg_catalog.pg_inherits i
    JOIN pg_catalog.pg_class c ON c.oid = i.inhrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_catalog.pg_class pc ON pc.oid = i.inhparent
    JOIN pg_catalog.pg_namespace pn ON pn.oid = pc.relnamespace
    WHERE c.relkind IN ('r', 'f')
      AND NOT c.relispartition
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_class', 'c.oid');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' ORDER BY n.nspname, c.relname, i.inhseqno';

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %inherits;
  while (my $row = $sth->fetchrow_hashref) {
    push @{ $inherits{ DBIO::PostgreSQL::Introspect->qualified_key($row) } },
      DBIO::PostgreSQL::Introspect->qualified_key(@{$row}{qw( parent_schema parent_name )});
  }

  return \%inherits;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Tables - Introspect PostgreSQL tables

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches PostgreSQL table (and view, materialized view, foreign table, and
partitioned table) metadata from C<pg_catalog.pg_class>. System schemas are
excluded, and so are the relations an installed extension owns (a C<pg_depend>
row of deptype C<e>) -- PostGIS's C<spatial_ref_sys> and C<geometry_columns>,
for instance: C<CREATE EXTENSION> / C<DROP EXTENSION> own them, so they are
not the schema's to create or drop. What hangs on such a relation -- columns,
indexes, constraints, triggers, policies -- is left out by the other
introspect helpers along with it.

=head1 METHODS

=head2 fetch

    my $tables = DBIO::PostgreSQL::Introspect::Tables->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.table>. Each value is a hashref with
keys: C<schema_name>, C<table_name>, C<oid>, C<kind> (pg relkind char),
C<kind_label> (human-readable), C<persistence>, C<comment>, C<rls_enabled>,
C<rls_forced>, C<view_definition>, C<depends_on>, C<depends_on_columns>,
C<partition_of>, C<inherits>.

C<view_definition> is what C<pg_get_viewdef> gives for a view or a
materialized view, and C<undef> for everything else. It is read under an
empty C<search_path>, so every relation, function and type in it that is not
in C<pg_catalog> is written with its schema (C<FROM auth.users>, never
C<FROM users>): the definition is the same text whatever C<search_path> the
session has, and means the same in every session it is run in. That holds in
every model, with L<DBIO::PostgreSQL::Introspect/qualified_names> or without.
The session is afterwards what it was
(L<DBIO::PostgreSQL::Introspect/under_empty_search_path>).

C<depends_on> is, for a view or a materialized view, the relations its
definition reads: an ArrayRef of their keys, sorted, as PostgreSQL records
them (the C<pg_depend> rows of the view's rewrite rule in C<pg_rewrite>). A
relation is named there whether or not it is in this hashref -- one in a
schema outside C<$filter>, or one an extension owns, is not. For every other
kind of relation it is an empty ArrayRef. L<DBIO::PostgreSQL::Diff::View>
orders views by it.

C<depends_on_columns> is, for the same two kinds, the columns the definition
reads of each of those relations: a HashRef from the key of the relation to
an ArrayRef of column names, sorted -- the same C<pg_depend> rows, which name
the column (C<refobjsubid>). A column in the C<WHERE> or in a join is read as
much as one in the select list. A relation the view reads as a whole row
(C<SELECT t FROM t>) is in C<depends_on> and has no entry here: PostgreSQL
records the relation then and none of its columns. For every other kind of
relation it is an empty HashRef. L<DBIO::PostgreSQL::Diff::Column> asks it
before it changes the type of a column, which PostgreSQL refuses while a view
reads it.

C<partition_of> is the key of the partitioned table a partition belongs to,
and C<undef> for a relation that is no partition.

C<inherits> is, for a table that inherits from others and is no partition
(C<CREATE TABLE ... INHERITS (...)>, C<ALTER TABLE ... INHERIT>), the keys of
the tables it inherits from, an ArrayRef in the order PostgreSQL keeps them
(C<pg_inherits.inhseqno>). For every other relation, a partition among them,
it is an empty ArrayRef. Which of its columns such a table defines itself is
C<is_local> in L<DBIO::PostgreSQL::Introspect::Columns>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
