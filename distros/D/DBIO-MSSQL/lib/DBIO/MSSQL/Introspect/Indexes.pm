package DBIO::MSSQL::Introspect::Indexes;
# ABSTRACT: Introspect MSSQL indexes

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $schema //= 'dbo';
  my %indexes;

  # Get indexes that are not primary keys or unique constraints (those are table-level)
  my $sth = $dbh->prepare(q{
    SELECT i.name AS index_name, t.name AS table_name,
           i.is_unique, i.type AS index_type,
           i.type_desc AS index_kind,
           c.name AS column_name, ic.key_ordinal
    FROM sys.indexes i
    JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    JOIN sys.tables t ON i.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = ?
      AND i.is_primary_key = 0
      AND i.type > 0  -- exclude heaps
    ORDER BY t.name, i.name, ic.key_ordinal
  });
  $sth->execute($schema);

  my %seen;
  while (my $row = $sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{table_name} };
    my $idx_key = "$row->{table_name}:$row->{index_name}";
    if (!$seen{$idx_key}++) {
      $indexes{ $row->{table_name} }{ $row->{index_name} } = {
        index_name => $row->{index_name},
        columns    => [],
        is_unique  => $row->{is_unique} ? 1 : 0,
        kind       => lc($row->{index_kind} // 'nonclustered'),
      };
    }
    push @{ $indexes{ $row->{table_name} }{ $row->{index_name} }{columns} }, $row->{column_name};
  }

  return \%indexes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Introspect::Indexes - Introspect MSSQL indexes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches index metadata via C<INFORMATION_SCHEMA.STATISTICS> and
C<sys.indexes> (filtered to exclude PK and unique constraint indexes
that are managed at table level).

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::MSSQL::Introspect::Indexes->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::MSSQL::Introspect::Tables>,
returns a hashref keyed by table name. Each value is a hashref of
index hashrefs keyed by index name with keys: C<index_name>,
C<columns> (arrayref), C<is_unique>, C<kind> (C<clustered>, C<nonclustered>, etc).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
