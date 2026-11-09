package DBIO::Informix::Introspect::Util;
# ABSTRACT: Shared helpers of the Informix catalog readers

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp ();



sub qualifier {
  my ($schema) = @_;
  Carp::croak('Informix introspection: invalid schema name '
    . (defined $schema ? "'$schema'" : '(undef)') . ' (expected \w+)')
    unless defined $schema && $schema =~ /\A\w+\z/;
  return qq{"$schema":informix};
}


sub part_columns {
  my ($row, $prefix) = @_;
  my @colnos;
  for my $n (1 .. 16) {
    my $part = $row->{"$prefix$n"};
    next unless $part;
    push @colnos, abs($part);
  }
  return @colnos;
}


sub column_names {
  my ($dbh, $q, $tabid) = @_;
  my $sth = $dbh->prepare(
    "SELECT colno, colname FROM $q.syscolumns WHERE tabid = ?"
  );
  $sth->execute($tabid);
  my %names;
  while (my $row = $sth->fetchrow_hashref) {
    $names{ $row->{colno} } = $row->{colname};
  }
  $sth->finish;
  return \%names;
}


sub names_for {
  my ($names, @colnos) = @_;
  return map {
    $names->{$_} // Carp::croak("Informix introspection: no column number $_ in syscolumns")
  } @colnos;
}

my $parts = join ', ', map { "i.part$_" } 1 .. 16;
my $rparts = join ', ', map { "ri.part$_ AS rpart$_" } 1 .. 16;
sub _parts_sql   { $parts }
sub _rparts_sql  { $rparts }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Introspect::Util - Shared helpers of the Informix catalog readers

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Helpers shared by the readers under C<DBIO::Informix::Introspect::>.

The statements built from these helpers are written against the catalog
(C<systables>, C<syscolumns>, C<sysconstraints>, C<sysindexes>,
C<sysreferences>, C<sysdefaults>) and measured against Informix 15.0.1
(C<t/60-introspect-live.t>).

=head1 METHODS

=head2 qualifier

    my $q = DBIO::Informix::Introspect::Util::qualifier($schema);
    # "mydb":informix

Returns the C<"database":informix> prefix for catalog tables. C<$schema> is
interpolated into SQL text, so it must be a plain identifier (C<\w+>);
anything else dies.

=head2 part_columns

    my @colnos = part_columns($row, 'part');

Collects C<part1> .. C<part16> of an C<sysindexes> row (key prefix
C<$prefix>, e.g. C<part> or C<rpart>) in key order. A part of 0 (or
undef) is unused; a negative part is a descending key column, its
column number is the absolute value.

=head2 column_names

    my %name_by_colno = %{ column_names($dbh, $q, $tabid) };

Column number to column name of one table (C<syscolumns>).

=head2 names_for

    my @names = names_for(\%name_by_colno, @colnos);

Resolves column numbers to names; an unknown number dies rather than
yielding a silently shorter key.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
