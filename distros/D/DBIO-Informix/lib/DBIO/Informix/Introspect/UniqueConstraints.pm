package DBIO::Informix::Introspect::UniqueConstraints;
# ABSTRACT: Introspect Informix unique constraints

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Informix::Introspect::Util ();



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  my %out;

  local $dbh->{FetchHashKeyName} = 'NAME_lc';

  my $q     = DBIO::Informix::Introspect::Util::qualifier($schema);
  my $parts = DBIO::Informix::Introspect::Util::_parts_sql();

  for my $table_name (sort grep { $tables->{$_}{kind} eq 'table' } keys %$tables) {
    my $sth = $dbh->prepare(qq{
      SELECT c.constrname, t.tabid, $parts
      FROM $q.sysconstraints c
      JOIN $q.systables t ON c.tabid = t.tabid
      JOIN $q.sysindexes i ON i.tabid = c.tabid AND i.idxname = c.idxname
      WHERE c.constrtype = 'U'
        AND t.tabname = ?
      ORDER BY c.constrname
    });
    $sth->execute($table_name);
    my @rows = @{ $sth->fetchall_arrayref({}) };
    $sth->finish;
    next unless @rows;

    my $names = DBIO::Informix::Introspect::Util::column_names($dbh, $q, $rows[0]{tabid});
    for my $row (@rows) {
      push @{ $out{$table_name} }, {
        constraint_name => $row->{constrname},
        columns         => [ DBIO::Informix::Introspect::Util::names_for(
          $names, DBIO::Informix::Introspect::Util::part_columns($row, 'part')) ],
      };
    }
  }

  return \%out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Introspect::UniqueConstraints - Introspect Informix unique constraints

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches the unique constraints of the tables via C<sysconstraints>
(C<constrtype = 'U'>). The columns are the key of the index the server holds
for the constraint (C<sysconstraints.idxname> to C<sysindexes.part1> ..
C<part16> to C<syscolumns.colno>). The index itself is not an entry of
L<DBIO::Informix::Introspect::Indexes>, which leaves out every index a
constraint owns.

Measured against Informix 15.0.1.

=head1 METHODS

=head2 fetch

    my $uniques = DBIO::Informix::Introspect::UniqueConstraints->fetch($dbh, $schema, $tables);

Returns a hashref keyed by table name (tables without a unique constraint
have no key). Each value is an arrayref of hashrefs with the keys
C<constraint_name> and C<columns>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
