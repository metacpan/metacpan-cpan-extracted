package DBIO::Sybase::Introspect::Indexes;
# ABSTRACT: Introspect Sybase ASE indexes

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $schema //= 'dbo';
  my %indexes;

  my $sth = $dbh->prepare(q{
    SELECT i.table_name, i.index_name, i.non_unique,
           STUFF(
             (SELECT ', ' + c.column_name
              FROM INFORMATION_SCHEMA.STATISTICS s2
              JOIN INFORMATION_SCHEMA.COLUMNS c
                ON c.table_schema = s2.table_schema
               AND c.table_name = s2.table_name
               AND c.column_name = s2.column_name
              WHERE s2.table_schema = i.table_schema
                AND s2.table_name = i.table_name
                AND s2.index_name = i.index_name
              ORDER BY s2.ordinal_position
              FOR XML PATH('')), 1, 2, ''
           ) as index_columns
    FROM INFORMATION_SCHEMA.STATISTICS i
    WHERE i.table_schema = ?
    ORDER BY i.table_name, i.index_name
  });
  $sth->execute($schema);

  while (my $row = $sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{table_name} };
    $indexes{ $row->{table_name} }{ $row->{index_name} } = {
      index_name  => $row->{index_name},
      is_unique   => ($row->{non_unique} == 0) ? 1 : 0,
      columns     => [ split /, /, $row->{index_columns} ],
    };
  }

  return \%indexes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Introspect::Indexes - Introspect Sybase ASE indexes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches index metadata via C<INFORMATION_SCHEMA.STATISTICS> and
C<INFORMATION_SCHEMA.TABLE_CONSTRAINTS>.

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::Sybase::Introspect::Indexes->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::Sybase::Introspect::Tables>,
returns a hashref keyed by table name. Each value is a hashref of
index hashrefs keyed by index name.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
