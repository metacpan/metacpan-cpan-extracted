package DBIO::Sybase::Introspect::ForeignKeys;
# ABSTRACT: Introspect Sybase ASE foreign keys

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $schema //= 'dbo';
  my %foreign_keys;

  my $sth = $dbh->prepare(q{
    SELECT
      tc.table_name,
      tc.constraint_name,
      kcu.column_name,
      rc2.table_name  AS ref_table_name,
      kcu2.column_name AS ref_column_name,
      rc.update_rule,
      rc.delete_rule
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
      ON tc.constraint_name = kcu.constraint_name
     AND tc.table_schema    = kcu.table_schema
     AND tc.table_name      = kcu.table_name
    JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
      ON tc.constraint_name = rc.constraint_name
     AND tc.table_schema    = rc.constraint_schema
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu2
      ON rc.unique_constraint_name = kcu2.constraint_name
     AND rc.unique_constraint_schema = kcu2.table_schema
    JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc2
      ON rc.unique_constraint_name = tc2.constraint_name
     AND rc.unique_constraint_schema = tc2.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = ?
    ORDER BY tc.table_name, tc.constraint_name, kcu.ordinal_position
  });
  $sth->execute($schema);

  while (my $row = $sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{table_name} };
    push @{ $foreign_keys{ $row->{table_name} } }, {
      constraint_name    => $row->{constraint_name},
      column_name        => $row->{column_name},
      ref_table_name    => $row->{ref_table_name},
      ref_column_name   => $row->{ref_column_name},
      update_rule       => $row->{update_rule},
      delete_rule       => $row->{delete_rule},
    };
  }

  return \%foreign_keys;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Introspect::ForeignKeys - Introspect Sybase ASE foreign keys

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches foreign key metadata via C<INFORMATION_SCHEMA.TABLE_CONSTRAINTS>
and C<INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE>.

=head1 METHODS

=head2 fetch

    my $fks = DBIO::Sybase::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::Sybase::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
foreign key hashrefs.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
