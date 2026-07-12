package DBIO::DuckDB::Introspect::ForeignKeys;
# ABSTRACT: Introspect DuckDB foreign keys

use strict;
use warnings;

use DBIO::Introspect::Base ();



sub fetch {
  my ($class, $dbh, $schema, $tables, $catalog) = @_;
  $schema //= 'main';
  my %fks;

  my $fk_sql = q{
    SELECT
      rc.constraint_name,
      kcu.table_name        AS from_table,
      kcu.column_name       AS from_column,
      kcu.ordinal_position  AS from_pos,
      ccu.table_name        AS to_table,
      ccu.column_name       AS to_column,
      rc.update_rule,
      rc.delete_rule,
      rc.match_option
    FROM information_schema.referential_constraints rc
    JOIN information_schema.table_constraints tc
      ON rc.constraint_name   = tc.constraint_name
     AND rc.constraint_schema = tc.constraint_schema
    JOIN information_schema.key_column_usage kcu
      ON rc.constraint_name  = kcu.constraint_name
     AND rc.constraint_schema = kcu.constraint_schema
    JOIN information_schema.constraint_column_usage ccu
      ON rc.unique_constraint_name   = ccu.constraint_name
     AND rc.unique_constraint_schema = ccu.constraint_schema
    WHERE kcu.table_schema = ?
  };
  my @fk_bind = ($schema);

  if (defined $catalog) {
    $fk_sql .= q{ AND tc.table_catalog = ? AND rc.constraint_catalog = ?};
    push @fk_bind, $catalog, $catalog;
  }

  $fk_sql .= q{ ORDER BY kcu.table_name, rc.constraint_name, kcu.ordinal_position};

  my $sth = $dbh->prepare($fk_sql);

  my $ok = eval { $sth->execute(@fk_bind); 1 };
  return \%fks unless $ok;

  my @rows;
  while (my $row = $sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{from_table} };
    push @rows, $row;
  }

  # Group the (already table/constraint/ordinal-ordered) key-column rows by
  # constraint name, preserving column order within each constraint. The
  # query's ORDER BY keeps groups for distinct constraints contiguous and in
  # first-seen order, so the aggregated output is deterministic.
  my $groups = DBIO::Introspect::Base->_aggregate_by_ordered(\@rows, 'constraint_name');

  for my $pair (@$groups) {
    my ($name, $group_rows) = @$pair;
    my $first = $group_rows->[0];
    my $fk = {
      fk_id        => $name,
      from_table   => $first->{from_table},
      from_columns => [ map { $_->{from_column} } @$group_rows ],
      to_table     => $first->{to_table},
      to_columns   => [ map { $_->{to_column} } @$group_rows ],
      on_update    => $first->{update_rule},
      on_delete    => $first->{delete_rule},
      match        => $first->{match_option},
    };
    push @{ $fks{ $fk->{from_table} } }, $fk;
  }

  return \%fks;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Introspect::ForeignKeys - Introspect DuckDB foreign keys

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches foreign-key metadata via C<information_schema.referential_constraints>
joined against C<key_column_usage>. Composite FKs are grouped by
constraint name.

DuckDB accepts FK declarations but does not enforce them as of 1.x. They
are still round-tripped here for schema correctness.

=head1 METHODS

=head2 fetch

    my $fks = DBIO::DuckDB::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);
    my $fks = DBIO::DuckDB::Introspect::ForeignKeys->fetch($dbh, $schema, $tables, $catalog);

Returns a hashref keyed by table name, each value an arrayref of FK
hashrefs with: C<fk_id>, C<from_columns>, C<to_table>, C<to_columns>,
C<on_update>, C<on_delete>, C<match>.

When C<$catalog> is defined, C<AND tc.table_catalog = ?> and
C<AND rc.constraint_catalog = ?> clauses are added.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
