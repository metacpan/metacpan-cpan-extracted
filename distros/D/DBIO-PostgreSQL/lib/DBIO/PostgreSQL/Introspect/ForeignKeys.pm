package DBIO::PostgreSQL::Introspect::ForeignKeys;
# ABSTRACT: Introspect PostgreSQL foreign keys

use strict;
use warnings;

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

  my $sql = q{
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
      constr.condeferrable AS is_deferrable
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
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('from_ns');

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

  return $class->_build_foreign_keys(\@rows, \%pg_rules);
}

# Two-level grouping: first by local schema, then by local table, then by
# constraint. We could call _aggregate_by on a composite key, but no such
# helper exists; the cheap alternative is one grouping by schema, then
# another by table within each schema (tables only ever have one schema,
# so this is straightforward).
sub _build_foreign_keys {
  my ($class, $rows, $pg_rules) = @_;

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

version 0.900000

=head1 DESCRIPTION

Fetches PostgreSQL foreign key metadata from C<pg_catalog.pg_constraint>,
including ordered local and remote columns plus referential actions and
deferrability.

=head1 METHODS

=head2 fetch

    my $foreign_keys = DBIO::PostgreSQL::Introspect::ForeignKeys->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.table>. Each value is an ArrayRef of
foreign key hashrefs with keys: C<constraint_name>, C<remote_schema>,
C<remote_table>, C<local_columns>, C<remote_columns>, C<on_delete>,
C<on_update>, and C<is_deferrable>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
