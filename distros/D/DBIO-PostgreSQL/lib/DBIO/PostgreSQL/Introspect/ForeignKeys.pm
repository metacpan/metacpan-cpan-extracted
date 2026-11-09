package DBIO::PostgreSQL::Introspect::ForeignKeys;
# ABSTRACT: Introspect PostgreSQL foreign keys

use strict;
use warnings;

our $VERSION = '0.900004';

use JSON::MaybeXS ();
use DBIO::PostgreSQL::Introspect ();

use base 'DBIO::Introspect::Base';



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my %pg_rules = (
    a => 'NO ACTION',
    r => 'RESTRICT',
    c => 'CASCADE',
    n => 'SET NULL',
    d => 'SET DEFAULT',
  );

  my %pg_match = (s => 'SIMPLE', f => 'FULL', p => 'PARTIAL');

  # confdelsetcols exists from PostgreSQL 15 on
  my $delcols = ($dbh->{pg_server_version} // 0) >= 150000
    ? q{(
        SELECT pg_catalog.jsonb_agg(da.attname ORDER BY dk.n)
        FROM pg_catalog.unnest(constr.confdelsetcols) WITH ORDINALITY AS dk(attnum, n)
        JOIN pg_catalog.pg_attribute da
          ON da.attrelid = constr.conrelid AND da.attnum = dk.attnum
      )}
    : q{NULL};

  my $sql = qq{
    SELECT
      from_ns.nspname AS local_schema,
      from_class.relname AS local_table,
      constr.conname AS constraint_name,
      to_ns.nspname AS remote_schema,
      to_class.relname AS remote_table,
      ord.n AS key_seq,
      from_col.attname AS local_column,
      to_col.attname AS remote_column,
      constr.confdeltype AS on_delete,
      constr.confupdtype AS on_update,
      constr.condeferrable AS is_deferrable,
      constr.condeferred AS is_deferred,
      constr.convalidated AS is_valid,
      constr.confmatchtype AS match_type,
      $delcols AS on_delete_columns
    FROM pg_catalog.pg_constraint constr
    JOIN pg_catalog.pg_class from_class ON from_class.oid = constr.conrelid
    JOIN pg_catalog.pg_namespace from_ns ON from_ns.oid = from_class.relnamespace
    JOIN pg_catalog.pg_class to_class ON to_class.oid = constr.confrelid
    JOIN pg_catalog.pg_namespace to_ns ON to_ns.oid = to_class.relnamespace
    JOIN pg_catalog.generate_subscripts(constr.conkey, 1) AS ord(n) ON true
    JOIN pg_catalog.pg_attribute from_col
      ON from_col.attrelid = constr.conrelid
     AND from_col.attnum = constr.conkey[ord.n]
    JOIN pg_catalog.pg_attribute to_col
      ON to_col.attrelid = constr.confrelid
     AND to_col.attnum = constr.confkey[ord.n]
    WHERE constr.contype = 'f'
      AND constr.conparentid = 0
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('from_ns');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_class', 'from_class.oid');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND from_ns.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= q{
    ORDER BY from_ns.nspname, from_class.relname, constr.conname, ord.n
  };

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my @rows;
  while (my $row = $sth->fetchrow_hashref) {
    push @rows, $row;
  }

  return $class->_build_foreign_keys(\@rows, \%pg_rules, \%pg_match);
}

# Two-level grouping: first by local schema, then by local table, then by
# constraint. We could call _aggregate_by on a composite key, but no such
# helper exists; the cheap alternative is one grouping by schema, then
# another by table within each schema (tables only ever have one schema,
# so this is straightforward).
sub _build_foreign_keys {
  my ($class, $rows, $pg_rules, $pg_match) = @_;
  $pg_match //= { s => 'SIMPLE', f => 'FULL', p => 'PARTIAL' };
  my $json = JSON::MaybeXS->new;

  my $by_schema = $class->_aggregate_by_ordered($rows, 'local_schema');
  my %foreign_keys;
  for my $s_pair (@$by_schema) {
    my ($schema, $schema_rows) = @$s_pair;

    my $by_table = $class->_aggregate_by_ordered($schema_rows, 'local_table');
    for my $t_pair (@$by_table) {
      my ($table, $table_rows) = @$t_pair;
      my $table_key = DBIO::PostgreSQL::Introspect->qualified_key($schema, $table);

      my $by_constraint = $class->_aggregate_by_ordered($table_rows, 'constraint_name');
      for my $c_pair (@$by_constraint) {
        my ($constraint_name, $c_rows) = @$c_pair;
        my $first = $c_rows->[0];

        my $entry = {
          constraint_name => $constraint_name,
          remote_schema   => $first->{remote_schema},
          remote_table    => $first->{remote_table},
          local_columns   => [map { $_->{local_column} } @$c_rows],
          remote_columns  => [map { $_->{remote_column} } @$c_rows],
          on_delete       => $pg_rules->{ $first->{on_delete} },
          on_update       => $pg_rules->{ $first->{on_update} },
          is_deferrable   => $first->{is_deferrable} ? 1 : 0,
          deferrable      => $first->{is_deferrable} ? 1 : 0,
          initially_deferred => $first->{is_deferred} ? 1 : 0,
          is_valid        => ($first->{is_valid} // 1) ? 1 : 0,
          match           => $pg_match->{ $first->{match_type} // 's' } // 'SIMPLE',
          on_delete_columns => defined $first->{on_delete_columns}
            ? $json->decode($first->{on_delete_columns}) : [],
        };
        push @{ $foreign_keys{$table_key} }, $entry;
      }
    }
  }

  return \%foreign_keys;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::ForeignKeys - Introspect PostgreSQL foreign keys

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches PostgreSQL foreign key metadata from C<pg_catalog.pg_constraint>,
including ordered local and remote columns plus referential actions and
deferrability.
Tables an installed extension owns are left out by
L<DBIO::PostgreSQL::Introspect::Tables>, and the foreign keys on them with
them. A foreign key of a partitioned table, or onto one, is carried down by
the server as copies with C<pg_constraint.conparentid> set (one at each
partition, one per partition a key onto a partitioned table points at); the
copies go with the declared key and are left out of the model. A
foreign key from one of the schema's own tables to such a table is
the schema's and is reported.

=head1 METHODS

=head2 fetch

    my $foreign_keys = DBIO::PostgreSQL::Introspect::ForeignKeys->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.table>. Each value is an ArrayRef of
foreign key hashrefs with keys: C<constraint_name>, C<remote_schema>,
C<remote_table>, C<local_columns>, C<remote_columns>, C<on_delete>,
C<on_update>, C<deferrable> and C<initially_deferred>
(C<pg_constraint.condeferrable>, C<condeferred>), C<is_deferrable>
(the same value as C<deferrable>, kept for readers of the older key), and three
that say what else the server holds of the key:

=over 4

=item C<is_valid>

C<pg_constraint.convalidated>: 1, or 0 for a key added C<NOT VALID> and not
yet validated.

=item C<match>

C<pg_constraint.confmatchtype> as the word: C<SIMPLE> (the default), C<FULL>.

=item C<on_delete_columns>

The columns named by C<ON DELETE SET NULL (columns)> or C<ON DELETE SET
DEFAULT (columns)>, in the order written (PostgreSQL 15 and later;
C<pg_constraint.confdelsetcols>). An empty ArrayRef for a key that names none,
and on a server that has no such column.

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
