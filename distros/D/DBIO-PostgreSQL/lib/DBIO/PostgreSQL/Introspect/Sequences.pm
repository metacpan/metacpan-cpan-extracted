package DBIO::PostgreSQL::Introspect::Sequences;
# ABSTRACT: Introspect PostgreSQL sequences

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      sn.nspname AS schema_name,
      s.relname AS sequence_name,
      d.refobjid::regclass::text AS owned_by_table,
      t.relname AS owned_by_table_name,
      a.attname AS owned_by_column,
      d.deptype = 'i' AS is_identity,
      seq.seqstart AS start_value,
      seq.seqincrement AS increment,
      seq.seqmin AS min_value,
      seq.seqmax AS max_value,
      seq.seqcache AS cache_size,
      seq.seqcycle AS is_cycle,
      pg_catalog.format_type(seq.seqtypid, NULL) AS data_type
    FROM pg_catalog.pg_class s
    JOIN pg_catalog.pg_namespace sn ON sn.oid = s.relnamespace
    JOIN pg_catalog.pg_sequence seq ON seq.seqrelid = s.oid
    LEFT JOIN pg_catalog.pg_depend d
      ON d.classid = 'pg_catalog.pg_class'::pg_catalog.regclass
     AND d.objid = s.oid
     AND d.objsubid = 0
     AND d.refclassid = 'pg_catalog.pg_class'::pg_catalog.regclass
     AND d.refobjsubid > 0
     AND d.deptype IN ('a', 'i')
    LEFT JOIN pg_catalog.pg_class t ON t.oid = d.refobjid
    LEFT JOIN pg_catalog.pg_attribute a
      ON a.attrelid = d.refobjid AND a.attnum = d.refobjsubid
    WHERE s.relkind = 'S'
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('sn');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_class', 's.oid');
  # A sequence that belongs to a column goes where its table goes. For a
  # sequence of its own d.refobjid is NULL and the condition lets it pass.
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_class', 'd.refobjid');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND sn.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' ORDER BY sn.nspname, s.relname';

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %sequences;
  while (my $row = $sth->fetchrow_hashref) {
    my $key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    $sequences{$key} = {
      schema_name         => $row->{schema_name},
      sequence_name       => $row->{sequence_name},
      owned_by_table      => $row->{owned_by_table},
      owned_by_table_name => $row->{owned_by_table_name},
      owned_by_column     => $row->{owned_by_column},
      is_identity         => $row->{is_identity} ? 1 : 0,
      start_value         => $row->{start_value},
      increment           => $row->{increment},
      min_value           => $row->{min_value},
      max_value           => $row->{max_value},
      cache_size          => $row->{cache_size},
      is_cycle            => $row->{is_cycle} ? 1 : 0,
      data_type           => $row->{data_type},
    };
  }

  return \%sequences;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Sequences - Introspect PostgreSQL sequences

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches sequence metadata from C<pg_catalog.pg_sequence>, including ownership
information (the table and column the sequence is attached to via C<pg_depend>),
start value, increment, min/max bounds, cache size, cycle flag, and data type.
The sequences an installed extension owns (a C<pg_depend> row of deptype C<e>)
are left out: C<CREATE EXTENSION> / C<DROP EXTENSION> own them.

A sequence belongs to a column when C<pg_depend> ties it to one: deptype C<a>
for a C<serial> column and for C<ALTER SEQUENCE ... OWNED BY>, deptype C<i>
for an identity column. Both are reported as owned, and C<is_identity> tells
the second from the first. Such a sequence goes where its table goes -- it
is dropped with the column -- so the one behind a column of an extension's
member table is left out along with that table, although no member row of
its own says so.

The two are not the same kind of thing. A sequence a column owns is an object
of its own: C<CREATE SEQUENCE> makes it, a default calls it by name, C<ALTER
SEQUENCE ... OWNED BY> ties it to the column, and it can be given to another
column or to none. The sequence of an identity column is a part of that
column: C<GENERATED ... AS IDENTITY> makes it and C<DROP IDENTITY> takes it,
and PostgreSQL has no other statement for either.
L<DBIO::PostgreSQL::Diff::Sequence> creates the first kind and leaves the
second to the column.

=head1 METHODS

=head2 fetch

    my $sequences = DBIO::PostgreSQL::Introspect::Sequences->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.sequence_name>. Each entry has:
C<schema_name>, C<sequence_name>, C<owned_by_table>, C<owned_by_table_name>,
C<owned_by_column>, C<is_identity>, C<start_value>, C<increment>,
C<min_value>, C<max_value>, C<cache_size>, C<is_cycle>, C<data_type>.

The table a sequence belongs to is there twice. C<owned_by_table_name> is its
name as the catalog has it; its schema is the sequence's, PostgreSQL ties a
sequence to no table of another schema. C<owned_by_table> is that table as the
session reads it (C<regclass>): quoted where the name needs it, and with its
schema only where the session's C<search_path> does not find the table. It is
for a reader, and is neither a key of the model nor a name to quote. All
three C<owned_by_*> are C<undef> for a sequence no column owns.

C<is_identity> is true for the sequence of an identity column and false for
every other.

C<data_type> is what the sequence counts in (C<smallint>, C<integer>,
C<bigint>), C<start_value> where it started, not where it stands.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
