package DBIO::MSSQL::Introspect::ForeignKeys;
# ABSTRACT: Introspect MSSQL foreign keys

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $schema //= 'dbo';
  my %fks;

  my $sth = $dbh->prepare(q{
    SELECT rc.constraint_name,
           fk_kcu.table_name AS from_table,
           uk_tc.table_name AS to_table,
           fk_kcu.column_name AS from_column,
           uk_kcu.column_name AS to_column,
           rc.delete_rule,
           rc.update_rule
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
    JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS fk_tc
      ON rc.constraint_name = fk_tc.constraint_name
     AND rc.constraint_schema = fk_tc.table_schema
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE fk_kcu
      ON fk_kcu.constraint_name = rc.constraint_name
     AND fk_kcu.table_schema = rc.constraint_schema
    JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS uk_tc
      ON rc.unique_constraint_name = uk_tc.constraint_name
     AND rc.unique_constraint_schema = uk_tc.table_schema
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE uk_kcu
      ON uk_kcu.constraint_name = rc.unique_constraint_name
     AND uk_kcu.ordinal_position = fk_kcu.ordinal_position
    WHERE fk_tc.table_schema = ?
    ORDER BY rc.constraint_name, fk_kcu.ordinal_position
  });
  $sth->execute($schema);

  while (my $row = $sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{from_table} };
    my $fk_key = "$row->{from_table}:$row->{constraint_name}";
    if (!exists $fks{$fk_key}) {
      $fks{$fk_key} = {
        constraint_name => $row->{constraint_name},
        from_table      => $row->{from_table},
        from_columns    => [],
        to_table        => $row->{to_table},
        to_columns      => [],
        on_delete       => uc($row->{delete_rule} // 'NO ACTION'),
        on_update       => uc($row->{update_rule} // 'NO ACTION'),
        is_deferrable   => 1,
      };
    }
    push @{ $fks{$fk_key}{from_columns} }, $row->{from_column};
    push @{ $fks{$fk_key}{to_columns} }, $row->{to_column};
  }

  # Re-index by table name.
  my %by_table;
  for my $fk (values %fks) {
    push @{ $by_table{ $fk->{from_table} } }, $fk;
  }

  return \%by_table;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Introspect::ForeignKeys - Introspect MSSQL foreign keys

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches foreign key metadata via C<INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS>
and related views.

=head1 METHODS

=head2 fetch

    my $fks = DBIO::MSSQL::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::MSSQL::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
foreign key hashrefs with keys: C<constraint_name>, C<from_columns>,
C<to_columns>, C<to_table>, C<to_schema>, C<on_delete>, C<on_update>,
C<is_deferrable>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
