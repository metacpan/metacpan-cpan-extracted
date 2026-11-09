package DBIO::Informix::Introspect::Columns;
# ABSTRACT: Introspect Informix columns

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Informix::Types;
use DBIO::Informix::Introspect::Util ();



sub fetch {
  my ($class, $dbh, $schema, $tables) = @_;
  my %columns;
  my %colnos;
  my $q = DBIO::Informix::Introspect::Util::qualifier($schema);

  for my $table_name (sort keys %$tables) {
    my $sth = $dbh->prepare(qq{
      SELECT c.colname, c.colno, c.coltype, c.collength, c.extended_id,
             d.type as deflt_type, d.default as deflt
      FROM $q.syscolumns c
      JOIN $q.systables t
        ON c.tabid = t.tabid
      LEFT JOIN $q.sysdefaults d
        ON t.tabid = d.tabid AND c.colno = d.colno
      WHERE t.tabname = ?
      ORDER BY c.colno
    });
    $sth->execute($table_name);

    my @cols;
    while (my $row = $sth->fetchrow_hashref) {
      my $type = $row->{coltype} % 256;
      $colnos{$table_name}{ $row->{colno} } = $row->{colname};
      my $data_type = _map_type($type, $row->{collength}, $row->{extended_id});

      my %col = (
        column_name     => $row->{colname},
        data_type       => $data_type,
        not_null        => ($row->{coltype} & 256) ? 1 : 0,
        default_value   => _map_default($type, $row->{deflt_type}, $row->{deflt}, $row->{collength}),
        is_pk           => 0,
        pk_position     => 0,
        is_auto_increment => ($type == 6 || $type == 18 || $type == 53) ? 1 : 0,
      );

      my $size = DBIO::Informix::Types::size_for_coltype($type, $row->{collength});
      $col{size} = $size if defined $size;

      push @cols, \%col;
    }
    $columns{$table_name} = \@cols;
  }

  # Fetch primary key info
  $class->_fetch_pk_info($dbh, $q, \%columns, \%colnos);

  return \%columns;
}

sub _map_type {
  my ($type, $collength, $extended_id) = @_;
  return DBIO::Informix::Types::logical_for_coltype($type, $collength, $extended_id);
}

# sysdefaults.type: L literal, U USER, S DBSERVERNAME, N NULL, T TODAY,
# C CURRENT. A literal of a type other than a character one is stored as
# "<encoded value> <text>" ('AAM 3' for SMALLINT 3); the text is the part
# after the first blank. Character literals and BOOLEAN are stored as is.
my %LITERAL_AS_IS = map { $_ => 1 } (0, 13, 15, 16, 40, 41);

# A DATETIME or INTERVAL literal is written with the qualifier of its column
# (DATETIME(2026-01-01) YEAR TO DAY), as the server takes it back; so is CURRENT
# (the qualifier of the column, it is not stored in sysdefaults). Without
# a collength the qualifier is the one the server gives a bare CURRENT.
sub _map_default {
  my ($type, $deflt_type, $deflt, $collength) = @_;
  return undef unless $deflt_type;
  my $q = DBIO::Informix::Types::qualifier_for_coltype($type, $collength);
  if ($deflt_type eq 'C') {
    my $cq = $q // 'YEAR TO FRACTION(5)';
    return \"CURRENT $cq";
  }
  if ($deflt_type eq 'T') { return \'today' }
  if ($deflt_type eq 'U') { return \'user' }
  if ($deflt_type eq 'S') { return \'dbservername' }
  return undef if $deflt_type eq 'N';
  return $deflt unless defined $deflt;
  $deflt =~ s/\s+\z//;
  $deflt =~ s/\A\S+\s+// unless $LITERAL_AS_IS{$type};
  if (defined $q && ($type == 10 || $type == 14)) {
    return \sprintf '%s(%s) %s', ($type == 10 ? 'DATETIME' : 'INTERVAL'), $deflt, $q;
  }
  return $deflt;
}

sub _fetch_pk_info {
  my ($class, $dbh, $q, $columns, $colnos) = @_;

  local $dbh->{FetchHashKeyName} = 'NAME_lc';

  my $parts = DBIO::Informix::Introspect::Util::_parts_sql();

  for my $table (sort keys %$columns) {
    my $sth = $dbh->prepare(qq{
      SELECT $parts
      FROM $q.sysconstraints c
      JOIN $q.systables t ON t.tabid = c.tabid
      JOIN $q.sysindexes i ON i.tabid = c.tabid AND i.idxname = c.idxname
      WHERE c.constrtype = 'P'
        AND t.tabname = ?
    });
    $sth->execute($table);
    my $row = $sth->fetchrow_hashref;
    $sth->finish;
    next unless $row;

    my %pos;
    my $pos = 0;
    for my $colno (DBIO::Informix::Introspect::Util::part_columns($row, 'part')) {
      my $name = $colnos->{$table}{$colno};
      $pos{$name} = ++$pos if defined $name;
    }

    for my $col (@{ $columns->{$table} }) {
      if (my $p = $pos{ $col->{column_name} }) {
        $col->{is_pk}       = 1;
        $col->{pk_position} = $p;
      }
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Introspect::Columns - Introspect Informix columns

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches column metadata via C<syscolumns> joined with C<systables>,
plus C<sysdefaults> for default values.

C<not_null> is bit 256 of C<syscolumns.coltype> (the type is
C<coltype % 256>). Primary keys are read through
C<sysconstraints> (C<constrtype = 'P'>) -> C<idxname> -> the C<sysindexes>
row of that name on the same table -> C<part1> .. C<part16> ->
C<syscolumns.colno>; C<pk_position> is the position within the key.

Measured against Informix 15.0.1: C<$schema> is validated
(C<\w+>) and used as the database qualifier; the C<sysdefaults.default>
column needs no quoting.

=head1 METHODS

=head2 fetch

    my $columns = DBIO::Informix::Introspect::Columns->fetch($dbh, $schema, $tables);

Given the tables hashref produced by L<DBIO::Informix::Introspect::Tables>,
returns a hashref keyed by table name. Each value is an arrayref of
column hashrefs (in declaration order) with keys: C<column_name>,
C<data_type>, C<not_null>, C<default_value>, C<is_pk>, C<pk_position>,
C<size>, C<is_auto_increment>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
