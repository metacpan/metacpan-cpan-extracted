package DBIO::DB2::Introspect::Indexes;
# ABSTRACT: Introspect DB2 indexes

use strict;
use warnings;



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  local $dbh->{FetchHashKeyName} = 'NAME_lc';   # DBD::DB2 upper-cases hashref keys
  my %indexes;

  my $sth = $dbh->prepare(q{
    SELECT indname, tabname, uniquerule, colcount
    FROM syscat.indexes
    WHERE indschema = ?
    ORDER BY tabname, indname
  });
  $sth->execute($schema);

  # SYSCAT.INDEXCOLUSE has no TABNAME, so map each index name back to its table
  # via the SYSCAT.INDEXES rows (index names are unique within a schema).
  my %index_table;
  while (my $row = $sth->fetchrow_hashref) {
    next unless exists $tables->{ $row->{tabname} };
    $index_table{ $row->{indname} } = $row->{tabname};
    # syscat.indexes.uniquerule: P = primary key, U = unique, D = duplicates
    my $rule = uc($row->{uniquerule} // 'D');
    $indexes{ $row->{tabname} }{ $row->{indname} } = {
      index_name => $row->{indname},
      is_unique  => ($rule eq 'P' || $rule eq 'U') ? 1 : 0,
      origin     => ($rule eq 'P') ? 'pk' : undef,
      columns    => [],
    };
  }

  # Resolve column names for each index via SYSCAT.INDEXCOLUSE. The catalog view
  # identifies an index column by INDSCHEMA + INDNAME only (no TABNAME), so the
  # owning table is recovered from the index->table map built above. COLSEQ
  # preserves the column order within the index.
  my $col_sth = $dbh->prepare(q{
    SELECT indname, colname, colseq
    FROM syscat.indexcoluse
    WHERE indschema = ?
    ORDER BY indname, colseq
  });
  $col_sth->execute($schema);

  while (my $row = $col_sth->fetchrow_hashref) {
    my $tabname = $index_table{ $row->{indname} } or next;
    next unless exists $indexes{$tabname}{ $row->{indname} };
    push @{ $indexes{$tabname}{ $row->{indname} }{columns} }, $row->{colname};
  }

  return \%indexes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Introspect::Indexes - Introspect DB2 indexes

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches index metadata via C<SYSCAT.INDEXES> and C<SYSCAT.INDEXCOLUSE>.
Primary-key and unique constraint-backed indexes are included.

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::DB2::Introspect::Indexes->fetch($dbh, $schema, $tables);

Returns a hashref keyed by table name, each value a hashref keyed by
index name with: C<index_name>, C<is_unique>, C<columns> (arrayref), and
C<origin> (C<'pk'> for the primary-key-backing index, else C<undef>). The
C<origin> marker lets L<DBIO::Introspect::Base/table_uniq_info> drop the PK
index from the unique-constraint list.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
