package DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder;
# ABSTRACT: WKT builder for PostGIS geometry structures

use strict;
use warnings;

our $VERSION = '0.900004';


sub build {
  my ($class, $parsed) = @_;
  my $type = uc($parsed->{type} // '');
  my $dim  = ($parsed->{has_z} ? 'Z' : '') . ($parsed->{has_m} ? 'M' : '');
  $dim = " $dim" if length $dim;

  my $coords    = $parsed->{coords};
  my $has_parts = ref $coords eq 'ARRAY' && @$coords;
  return "${type}${dim} EMPTY"
    if !$has_parts && ($parsed->{is_empty} || ref $coords eq 'ARRAY');

  my $body = $class->_build_coords($parsed->{type}, $coords, $parsed);
  return "${type}${dim}($body)";
}

sub _build_coords {
  my ($class, $type, $coords, $dim) = @_;
  $type = lc($type);

  if ($type eq 'point') {
    return join(' ', @$coords);
  }
  if ($type eq 'linestring') {
    return join(',', map { join(' ', @$_) } @$coords);
  }
  # An empty part is EMPTY, not a list of nothing between parentheses.
  if ($type eq 'multipoint') {
    return join(',', map { @$_ ? join(' ', @$_) : 'EMPTY' } @$coords);
  }
  if ($type eq 'polygon') {
    return join(',', map { '(' . join(',', map { join(' ', @$_) } @$_) . ')' } @$coords);
  }
  if ($type eq 'multilinestring') {
    return join(',', map {
      @$_ ? '(' . join(',', map { join(' ', @$_) } @$_) . ')' : 'EMPTY'
    } @$coords);
  }
  if ($type eq 'multipolygon') {
    return join(',',
      map {
        @$_
          ? '(' . join(',', map { '(' . join(',', map { join(' ', @$_) } @$_) . ')' } @$_) . ')'
          : 'EMPTY'
      } @$coords
    );
  }
  if ($type eq 'geometrycollection') {
    return join(',', map {
      $class->build({
        type => $_->{type}, coords => $_->{coords}, is_empty => $_->{is_empty},
        has_z => $dim->{has_z}, has_m => $dim->{has_m},
      })
    } @$coords);
  }
  return '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder - WKT builder for PostGIS geometry structures

=head1 VERSION

version 0.900004

=head1 METHODS

=head2 build

    my $wkt = DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder->build($parsed);

Accepts the hashref returned by L<DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser/parse>
(or by L<DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder/decode_hex>) and
returns a WKT string.

C<has_z> and C<has_m> become the dimension marker, a word of its own
after the type: C<POINT Z(1 2 3)>, C<POINT M(1 2 9)>, C<POINT ZM(1 2 3 4)>.
A C<MULTIPOINT> is written without parentheses around each point,
C<MULTIPOINT(1 2,3 4)>. The parser reads back what is built here.

A geometry without parts is written C<TYPE EMPTY>, with the marker in
front of C<EMPTY>: C<LINESTRING EMPTY>, C<POINT Z EMPTY>. It is one if
C<is_empty> is true and C<coords> has no parts, or if C<coords> is an
empty list, which C<is_empty> need not say. A C<MULTI*> or a collection
that is C<is_empty> because its parts all are is written with its parts.

An empty part of a C<MULTI*> -- an empty list in C<coords> -- is written
C<EMPTY>, as PostGIS prints it: C<MULTIPOINT(EMPTY,1 2)>,
C<MULTIPOLYGON(EMPTY,((0 0,1 0,1 1,0 0)))>.

For a C<geometrycollection>, C<coords> is a list of the members, each a
hashref C<< { type, coords, is_empty } >> as the decoder returns it. Each
is written with its type and, like the collection, with the marker:
C<GEOMETRYCOLLECTION Z(POINT Z(1 2 3),LINESTRING Z(0 0 1,1 1 2))>, which
is how C<ST_AsText> prints it and PostGIS reads it. The members take the
dimension of the collection.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
