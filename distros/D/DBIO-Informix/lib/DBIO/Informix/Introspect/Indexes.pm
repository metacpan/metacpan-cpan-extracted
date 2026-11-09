package DBIO::Informix::Introspect::Indexes;
# ABSTRACT: Introspect Informix indexes

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Informix::Introspect::Util ();



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  my %indexes;

  local $dbh->{FetchHashKeyName} = 'NAME_lc';

  my $q = DBIO::Informix::Introspect::Util::qualifier($schema);
  my $parts = DBIO::Informix::Introspect::Util::_parts_sql();

  for my $table_name (sort keys %$tables) {
    my $sth = $dbh->prepare(qq{
      SELECT i.idxname, i.idxtype, i.tabid, $parts
      FROM $q.sysindexes i
      JOIN $q.systables t ON i.tabid = t.tabid
      WHERE t.tabname = ?
        AND NOT EXISTS (
          SELECT 1 FROM $q.sysconstraints c
          WHERE c.tabid = i.tabid AND c.idxname = i.idxname
        )
      ORDER BY i.idxname
    });
    $sth->execute($table_name);
    my @rows = @{ $sth->fetchall_arrayref({}) };
    $sth->finish;
    next unless @rows;

    my $names = DBIO::Informix::Introspect::Util::column_names($dbh, $q, $rows[0]{tabid});

    for my $row (@rows) {
      my $idx_name = $row->{idxname};
      $indexes{$table_name}{$idx_name} = {
        index_name => $idx_name,
        unique     => ($row->{idxtype} eq 'U') ? 1 : 0,
        columns    => [ DBIO::Informix::Introspect::Util::names_for(
          $names, DBIO::Informix::Introspect::Util::part_columns($row, 'part')
        ) ],
      };
    }
  }

  return \%indexes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Introspect::Indexes - Introspect Informix indexes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches index metadata via C<sysindexes>. The index-to-column link is
C<sysindexes.part1> .. C<part16>, each a C<syscolumns.colno> of the same
table; a negative part is a descending column (the absolute value is the
column number), 0 is unused. Columns come out in part order.

Measured against Informix 15.0.1. Not handled: functional /
opaque-type indexes (whose parts do not name plain columns). Indexes the
server created for a constraint (named like C<" 136_41">, listed as
C<sysconstraints.idxname>) are left out: the primary and foreign keys are
modelled as such, and the names differ from one database to the next, so
diffing them by name would drop and recreate them.

=head1 METHODS

=head2 fetch

    my $indexes = DBIO::Informix::Introspect::Indexes->fetch($dbh, $schema, $tables);

Returns a hashref keyed by table name. Each value is a hashref keyed by
index name, with keys: C<index_name>, C<unique>, C<columns>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
