package DBIO::PostgreSQL::Introspect::Indexes;
# ABSTRACT: Introspect PostgreSQL indexes

use strict;
use warnings;

our $VERSION = '0.900004';

use JSON::MaybeXS ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Introspect::Parse ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  # One entry per position of indkey, in a JSON array: the arrays of a handle
  # come back as ArrayRefs or as strings by pg_expand_array, a JSON text does
  # not. The key positions are the first indnkeyatts of them; the rest are
  # INCLUDE columns. indclass and indoption have an entry for key positions
  # only.
  my $sql = q{
    SELECT
      sn.nspname AS schema_name,
      ct.relname AS table_name,
      ci.relname AS index_name,
      am.amname AS access_method,
      i.indisunique AS is_unique,
      i.indisprimary AS is_primary,
      i.indisvalid AS is_valid,
      i.indnkeyatts AS key_count,
      pg_catalog.pg_get_indexdef(i.indexrelid) AS definition,
      pg_catalog.pg_get_expr(i.indpred, i.indrelid) AS predicate,
      pg_catalog.pg_get_expr(i.indexprs, i.indrelid) AS expressions,
      (
        SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
          'column',  a.attname,
          'opclass', CASE
            WHEN oc.oid IS NULL OR (oc.opcdefault AND ia.attoptions IS NULL) THEN NULL
            WHEN pg_catalog.pg_opclass_is_visible(oc.oid)
              THEN pg_catalog.quote_ident(oc.opcname)
            ELSE pg_catalog.quote_ident(ocn.nspname) || '.' || pg_catalog.quote_ident(oc.opcname)
          END,
          'options', (
            SELECT pg_catalog.string_agg(
              pg_catalog.quote_ident(pg_catalog.split_part(o.opt, '=', 1)) || '='
                || pg_catalog.quote_literal(pg_catalog.substr(o.opt, pg_catalog.strpos(o.opt, '=') + 1)),
              ', ' ORDER BY o.n)
            FROM pg_catalog.unnest(ia.attoptions) WITH ORDINALITY AS o(opt, n)
          ),
          'indoption', i.indoption[k.n - 1]
        ) ORDER BY k.n)
        FROM pg_catalog.unnest(i.indkey) WITH ORDINALITY AS k(attnum, n)
        LEFT JOIN pg_catalog.pg_attribute a
          ON a.attrelid = i.indrelid AND a.attnum = k.attnum
        LEFT JOIN pg_catalog.pg_attribute ia
          ON ia.attrelid = i.indexrelid AND ia.attnum = k.n
        LEFT JOIN pg_catalog.pg_opclass oc
          ON oc.oid = i.indclass[k.n - 1] AND k.n <= i.indnkeyatts
        LEFT JOIN pg_catalog.pg_namespace ocn ON ocn.oid = oc.opcnamespace
      ) AS positions,
      con.conname AS constraint_name,
      con.contype AS constraint_type,
      con.condeferrable AS is_deferrable,
      con.condeferred AS is_deferred,
      (
        SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
          'schema_name', fn.nspname,
          'table_name', fc.relname,
          'constraint_name', fk.conname
        ) ORDER BY fn.nspname, fc.relname, fk.conname)
        FROM pg_catalog.pg_constraint fk
        JOIN pg_catalog.pg_class fc ON fc.oid = fk.conrelid
        JOIN pg_catalog.pg_namespace fn ON fn.oid = fc.relnamespace
        WHERE fk.contype = 'f' AND fk.conindid = i.indexrelid
          AND fk.conparentid = 0
      ) AS referenced_by,
      ci.reloptions AS storage_params
    FROM pg_catalog.pg_index i
    JOIN pg_catalog.pg_class ci ON ci.oid = i.indexrelid
    JOIN pg_catalog.pg_class ct ON ct.oid = i.indrelid
    JOIN pg_catalog.pg_namespace sn ON sn.oid = ct.relnamespace
    JOIN pg_catalog.pg_am am ON am.oid = ci.relam
    LEFT JOIN pg_catalog.pg_constraint con
      ON con.conindid = i.indexrelid
     AND con.conrelid = i.indrelid
     AND con.contype IN ('p', 'u', 'x')
    WHERE ct.relkind IN ('r', 'm', 'p')
      AND NOT ci.relispartition
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('sn');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_class', 'ct.oid');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND sn.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= q{
    ORDER BY sn.nspname, ct.relname, ci.relname
  };

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my $json = JSON::MaybeXS->new;

  my %indexes;
  while (my $row = $sth->fetchrow_hashref) {
    my $table_key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    my @positions = @{ $json->decode($row->{positions} // '[]') };
    my @key       = splice @positions, 0, $row->{key_count};

    my (%opclasses, %sort_options);
    for my $position (@key) {
      my $column = $position->{column};
      next unless defined $column;

      if (defined $position->{opclass}) {
        $opclasses{$column} = $position->{opclass}
          . (defined $position->{options} ? "($position->{options})" : '');
      }

      my $sort = _sort_options($position->{indoption});
      $sort_options{$column} = $sort if length $sort;
    }

    $indexes{$table_key}{ $row->{index_name} } = {
      schema_name   => $row->{schema_name},
      table_name    => $row->{table_name},
      index_name    => $row->{index_name},
      access_method => $row->{access_method},
      is_unique     => $row->{is_unique} ? 1 : 0,
      is_primary    => $row->{is_primary} ? 1 : 0,
      is_valid      => $row->{is_valid} ? 1 : 0,
      definition    => $row->{definition},
      predicate     => $row->{predicate},
      expressions   => $row->{expressions},
      columns         => [ map { $_->{column} } @key ],
      include_columns => [ map { $_->{column} } @positions ],
      storage_params  => DBIO::PostgreSQL::Introspect::Parse->storage_params($row->{storage_params}),
      opclasses       => \%opclasses,
      sort_options    => \%sort_options,
      constraint_name => $row->{constraint_name},
      constraint_type => $row->{constraint_type},
      deferrable      => $row->{is_deferrable} ? 1 : 0,
      initially_deferred => $row->{is_deferred} ? 1 : 0,
      referenced_by   => $json->decode($row->{referenced_by} // '[]'),
    };
  }

  return \%indexes;
}

# The sort of a key column as the definition writes it, from its indoption
# bits (1 DESC, 2 NULLS FIRST): nothing where it is the default -- ascending
# with the nulls last, descending with them first.
sub _sort_options {
  my ($option) = @_;
  $option //= 0;
  my ($desc, $nulls_first) = ($option & 1, $option & 2);
  return $desc
    ? ($nulls_first ? 'DESC' : 'DESC NULLS LAST')
    : ($nulls_first ? 'NULLS FIRST' : '');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Indexes - Introspect PostgreSQL indexes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches index metadata from C<pg_catalog.pg_index>, including access method,
uniqueness, primary key flag, validity, the full index definition string from
C<pg_get_indexdef>, partial index predicates, and expression index expressions.
Relations an installed extension owns are left out by
L<DBIO::PostgreSQL::Introspect::Tables>, and their indexes with them: an index
is no extension member in its own right, so it would otherwise stay behind as
an index of a table the model does not have, for the diff to drop.

An index on a partitioned table is carried down to every partition by the
server: the partition has a copy of its own (C<pg_class.relispartition>, tied
to the parent's by C<pg_inherits>). The copy is part of the parent's index,
created and dropped with it and by no statement at the partition, so it is left
out of the model. An index a partition has by its own declaration is no copy
and is in it.

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::PostgreSQL::Introspect::Indexes->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.table>. Each value is a hashref keyed by
index name. Each index entry has: C<schema_name> and C<table_name> (the table
it is on, each name for itself -- the key cannot be taken apart again; the
schema is the index's own as well, an index lives in its table's schema),
C<index_name>, C<access_method>, C<is_unique>,
C<is_primary>, C<is_valid>, C<definition> (full C<pg_get_indexdef> output),
C<predicate>, C<expressions>, C<columns> (see below), C<include_columns>,
C<storage_params>, C<opclasses>, C<sort_options>, C<constraint_name>,
C<constraint_type> and C<referenced_by>. All of it is read from the catalog,
none of it out of the text of the definition.

C<columns> is an ArrayRef with one entry for each B<key> position of the index
(the first C<pg_index.indnkeyatts> positions of C<indkey>), in that order: the
name of the column, or C<undef> where the position is an expression and no
column. An index on an expression alone therefore has C<< columns => [undef] >>,
not an empty list, and one on a column and an expression C<< ['name', undef] >>;
the expression itself is in C<expressions> and in C<definition>. The columns
of an C<INCLUDE> clause are not key positions: they are in C<include_columns>
and in no other entry. The shape is the same on a handle that returns arrays as
strings (C<pg_expand_array> off) as on one that returns ArrayRefs, as
L<DBD::Pg> does by default.

C<opclasses> is a HashRef of column name to a non-default operator class, as
SQL: the class is named with its schema, quoted as the server quotes it, where
the session's C<search_path> does not find it (C<"Ex Schema".my_ops>), and the
parameters of a class (PostgreSQL 13 and later) follow its name
(C<tsvector_ops(siglen='32')>). A class that is the default for its access
method is left out unless it has parameters: C<pg_get_indexdef> does not print it
either. An expression position has no column to key it by and is left out.

C<sort_options> is a HashRef of column name to the sort of that key column
where it is not the default, from C<pg_index.indoption>: C<DESC>,
C<DESC NULLS LAST> or C<NULLS FIRST>. Ascending with the nulls last, and
descending with the nulls first, are the defaults and are not listed. Only an
access method that orders (btree) has any. There is no key of C<pg_index> to
declare a sort with; it is in the model so that nothing reads it out of the
definition string again.

C<constraint_name> and C<constraint_type> say whether a constraint stands
behind the index: the name of the PRIMARY KEY, UNIQUE or EXCLUDE constraint
and its kind, C<p>, C<u> or C<x>; both C<undef> for an index without one (a
unique index created by C<CREATE UNIQUE INDEX> is such an index). The server
drops such an index only with its constraint. C<deferrable> and
C<initially_deferred> are C<pg_constraint.condeferrable> and C<condeferred> of
that constraint (1 or 0; 0 without a constraint). C<referenced_by> is an
ArrayRef of C<{ schema_name, table_name, constraint_name }>, one for each
foreign key of a table that points at that constraint, empty when none does;
the copies the server makes of the key of a partitioned table for its
partitions are not named, as in L<DBIO::PostgreSQL::Introspect::ForeignKeys>.
Only the constraint's own index is named by a foreign key.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
