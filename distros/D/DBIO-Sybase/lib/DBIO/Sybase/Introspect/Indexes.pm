package DBIO::Sybase::Introspect::Indexes;
# ABSTRACT: Introspect Sybase ASE indexes

use strict;
use warnings;

our $VERSION = '0.900004';



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  $schema //= 'dbo';
  my %indexes;

  my $keys = join ', ',
    map { "index_col(o.name, i.indid, $_, o.uid) AS k$_" } 1 .. 31;

  my $rows = $dbh->selectall_arrayref(qq{
    SELECT o.name AS table_name, i.name AS index_name, i.indid, i.status,
           $keys
    FROM sysindexes i
    JOIN sysobjects o ON o.id = i.id
    JOIN sysusers   u ON u.uid = o.uid
    WHERE o.type = 'U'
      AND u.name = ?
      AND i.indid BETWEEN 1 AND 250
    ORDER BY o.name, i.indid
  }, { Slice => {} }, $schema);

  for my $row (@$rows) {
    next unless exists $tables->{ $row->{table_name} };
    my @cols;
    for my $n (1 .. 31) {
      my $col = $row->{"k$n"};
      last unless defined $col;
      push @cols, $col;
    }
    my $status = $row->{status} // 0;
    my $idx = {
      index_name => $row->{index_name},
      is_unique  => ($status & 2) ? 1 : 0,
      columns    => \@cols,
    };
    $idx->{origin} = 'pk' if $status & 2048;
    $indexes{ $row->{table_name} }{ $row->{index_name} } = $idx;
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

version 0.900004

=head1 DESCRIPTION

Fetches index metadata from the ASE system catalog: C<sysindexes> (joined to
C<sysobjects> / C<sysusers> for the owner), with the key columns read through
C<index_col()>. SAP ASE has no C<INFORMATION_SCHEMA> views.

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::Sybase::Introspect::Indexes->fetch($dbh, $schema, $tables);

Given the tables hashref from L<DBIO::Sybase::Introspect::Tables>,
returns a hashref keyed by table name. Each value is a hashref of
index hashrefs keyed by index name: C<index_name>, C<is_unique>
(C<status & 2>), C<columns> (key order), and C<< origin => 'pk' >> for the
index backing a C<PRIMARY KEY> constraint (C<status & 2048>).

That PK index carries a server-generated name (C<artist_5760020521>) that
differs between two deployments of the same DDL; the C<origin> marker is what
lets L<DBIO::Sybase::Diff::Index> leave it out of the name-keyed comparison.

Only real indexes are read (C<indid> 1..250): C<0> is the heap and C<255> the
text/image chain. C<index_col()> returns C<NULL> past the last key column --
C<keycnt> is not the column count, it includes the row id on nonclustered
indexes -- so the keys are read up to the first C<NULL>, for the 31 columns
an ASE index can have at most.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
