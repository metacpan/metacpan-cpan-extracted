package DBIO::Oracle::Introspect::ForeignKeys;
# ABSTRACT: Introspect Oracle foreign keys

use strict;
use warnings;

use base 'DBIO::Introspect::Base';



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;

  my $fk_sth = $dbh->prepare_cached(q{
    SELECT
      cc.constraint_name   AS fk_name,
      cc.table_name        AS from_table,
      kcu.column_name      AS from_column,
      kcu.position         AS from_pos,
      rcc.table_name       AS to_table,
      rcc.column_name      AS to_column,
      rc.position          AS to_pos,
      cc.delete_rule       AS on_delete,
      CASE WHEN cc.deferrable = 'DEFERRABLE' THEN 1 ELSE 0 END AS is_deferrable
    FROM all_constraints cc
    JOIN all_cons_columns kcu
      ON cc.constraint_name = kcu.constraint_name
     AND cc.owner = kcu.owner
    JOIN all_indexes ix
      ON ix.index_name = cc.index_name
     AND ix.owner = cc.owner
    JOIN all_cons_columns rc
      ON cc.r_constraint_name = rc.constraint_name
     AND cc.r_owner = rc.owner
    WHERE cc.constraint_type = 'R'
      AND cc.owner = ?
    ORDER BY cc.table_name, cc.constraint_name, kcu.position
  });
  $fk_sth->execute($schema);

  # Collect every row first; _aggregate_by_ordered needs the full list, and
  # we want a single pass for the row filter against $tables.
  my @rows;
  while (my $row = $fk_sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{from_table} };
    push @rows, $row;
  }
  $fk_sth->finish;

  # Two-level grouping: by from_table, then by fk_name. Two FKs in different
  # tables may share a name, so the outer group is essential; _aggregate_by
  # alone (single key) would merge them.
  my $by_table = $class->_aggregate_by_ordered(\@rows, 'from_table');

  my %fks;
  for my $t_pair (@$by_table) {
    my ($table, $table_rows) = @$t_pair;

    my $by_constraint = $class->_aggregate_by_ordered($table_rows, 'fk_name');
    for my $c_pair (@$by_constraint) {
      my ($fk_name, $c_rows) = @$c_pair;
      my $first = $c_rows->[0];

      push @{ $fks{$table} }, {
        fk_name      => $fk_name,
        from_table   => $table,
        from_columns => [ map { $_->{from_column} } @$c_rows ],
        to_table     => $first->{to_table},
        to_columns   => [ map { $_->{to_column}   } @$c_rows ],
        on_update    => 'NO ACTION',
        on_delete    => $first->{on_delete} // 'NO ACTION',
        is_deferrable => $first->{is_deferrable} ? 1 : 0,
      };
    }
  }

  # Ensure all tables have an entry even if no FKs
  $fks{$_} //= [] for keys %$tables;

  return \%fks;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Introspect::ForeignKeys - Introspect Oracle foreign keys

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches Oracle foreign key metadata via C<all_constraints>,
C<all_cons_columns>, and C<all_indexes>. Includes deferrability
information from C<all_constraints> directly.

=head1 METHODS

=head2 fetch

    my $fks = DBIO::Oracle::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);

Returns a hashref keyed by table name, each value an arrayref of FK
hashrefs with: C<fk_name>, C<from_columns>, C<to_table>, C<to_columns>,
C<on_update>, C<on_delete>, C<is_deferrable>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
