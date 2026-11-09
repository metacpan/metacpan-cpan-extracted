package DBIO::MSSQL::Introspect::Indexes;
# ABSTRACT: Introspect MSSQL indexes

use strict;
use warnings;

our $VERSION = '0.900004';



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $schema //= 'dbo';
  my %indexes;

  # Every column is aliased explicitly and in lower case: an alias is echoed
  # into the result metadata verbatim, which is the one way to be sure of the
  # hash keys below without depending on the handle's FetchHashKeyName.
  #
  # Every index but the one of the primary key. The one of a unique
  # constraint is kept and flagged: it is a constraint to ADD and DROP.
  my $sth = $dbh->prepare(q{
    SELECT i.name AS index_name, t.name AS table_name,
           i.is_unique AS is_unique,
           i.is_unique_constraint AS is_unique_constraint, i.type AS index_type,
           i.type_desc AS index_kind,
           i.has_filter AS has_filter, i.filter_definition AS filter_definition,
           c.name AS column_name, ic.key_ordinal AS key_ordinal
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
        is_unique_constraint => $row->{is_unique_constraint} ? 1 : 0,
        kind       => lc($row->{index_kind} // 'nonclustered'),
        filter     => $row->{has_filter} ? $row->{filter_definition} : undef,
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

version 0.900004

=head1 DESCRIPTION

Fetches index metadata via C<sys.indexes> and C<sys.index_columns>. The
index of a primary key is left out (it is the table's key, read with the
columns). The index behind a B<unique constraint> is kept and flagged
C<is_unique_constraint>: the diff has to add and drop it as a constraint
(C<ALTER TABLE ... ADD/DROP CONSTRAINT>), which C<DROP INDEX> cannot (Msg 3723),
and tell it from a unique index.

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::MSSQL::Introspect::Indexes->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::MSSQL::Introspect::Tables>,
returns a hashref keyed by table name. Each value is a hashref of
index hashrefs keyed by index name with keys: C<index_name>,
C<columns> (arrayref), C<is_unique>, C<is_unique_constraint>, C<kind> (C<clustered>, C<nonclustered>, etc)
and C<filter>: the predicate of a filtered index (C<sys.indexes.filter_definition>,
read where C<has_filter> is set), C<undef> for an index without one. The
server returns the predicate in a form of its own (C<WHERE a = 1> comes back as
C<([a]=(1))>); it is kept as it is, and
L<DBIO::MSSQL::Diff::Index/normalize_filter> makes two forms comparable.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
