package DBIO::PostgreSQL::PostGIS::Geometry;
# ABSTRACT: Lightweight PostGIS geometry/geography value object

use strict;
use warnings;

use DBIO::Exception ();
use DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser  ();
use DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder ();
use DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder ();


sub new {
  my ($class, %args) = @_;
  my $self = {
    srid          => $args{srid},
    wkt           => $args{wkt},
    ewkb_hex      => $args{ewkb_hex},
    geometry_type => $args{geometry_type},
    coordinates   => $args{coordinates},
  };
  return bless $self, $class;
}


sub from_wkt {
  my ($class, $wkt, %args) = @_;
  DBIO::Exception->throw("from_wkt requires a WKT string") unless defined $wkt;
  my $parsed = DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser->parse($wkt);
  return $class->new(
    wkt           => $wkt,
    srid          => $args{srid},
    geometry_type => $parsed ? $parsed->{type} : undef,
    coordinates   => $parsed ? $parsed->{coords} : undef,
  );
}


sub from_ewkt {
  my ($class, $ewkt) = @_;
  DBIO::Exception->throw("from_ewkt requires an EWKT string") unless defined $ewkt;
  if ($ewkt =~ /\ASRID=(\d+);(.+)\z/s) {
    return $class->new(srid => $1, wkt => $2);
  }
  return $class->new(wkt => $ewkt);
}


sub from_ewkb_hex {
  my ($class, $hex) = @_;
  my $decoded = eval {
    DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder->decode_hex($hex);
  };
  return undef unless $decoded && $decoded->{type} ne 'unknown';
  return $class->new(
    ewkb_hex      => $hex,
    srid          => $decoded->{srid},
    geometry_type => $decoded->{type},
    coordinates   => $decoded->{coords},
  );
}


sub point {
  my $class = shift;
  my @coords;
  push @coords, shift while @_ && !ref $_[0] && $_[0] =~ /\A-?[0-9.eE+\-]+\z/;
  my %args = @_;
  my $wkt = 'POINT(' . join(' ', @coords) . ')';
  return $class->new(wkt => $wkt, srid => $args{srid}, geometry_type => 'POINT');
}


sub from_lat_lon {
  my ($class, $lat, $lon) = @_;
  return $class->point($lon, $lat, srid => 4326);
}


sub linestring {
  my ($class, $coords, %args) = @_;
  my $wkt = 'LINESTRING(' . join(',', map { join ' ', @$_ } @$coords) . ')';
  return $class->new(wkt => $wkt, srid => $args{srid}, geometry_type => 'LINESTRING');
}


sub polygon {
  my ($class, $rings, %args) = @_;
  my $wkt = 'POLYGON('
    . join(',', map {
        '(' . join(',', map { join ' ', @$_ } @$_) . ')'
      } @$rings)
    . ')';
  return $class->new(wkt => $wkt, srid => $args{srid}, geometry_type => 'POLYGON');
}


sub bbox_polygon {
  my ($class, $xmin, $ymin, $xmax, $ymax, %args) = @_;
  return $class->polygon(
    [[ [$xmin,$ymin], [$xmax,$ymin], [$xmax,$ymax], [$xmin,$ymax], [$xmin,$ymin] ]],
    %args,
  );
}


sub from_geojson {
  my ($class, $gj, %args) = @_;
  my $srid = exists $args{srid} ? $args{srid} : 4326;
  my $type = $gj->{type}
    or DBIO::Exception->throw("from_geojson: missing 'type'");
  my $coords = $gj->{coordinates};
  my $wkt;
  if ($type eq 'Point') {
    $wkt = 'POINT(' . join(' ', @$coords) . ')';
  }
  elsif ($type eq 'LineString' or $type eq 'MultiPoint') {
    $wkt = uc($type =~ s/(?<=[a-z])(?=[A-Z])/ /gr) =~ s/ //gr;
    $wkt = ($type eq 'LineString' ? 'LINESTRING' : 'MULTIPOINT')
      . '(' . join(',', map { join ' ', @$_ } @$coords) . ')';
  }
  elsif ($type eq 'Polygon' or $type eq 'MultiLineString') {
    $wkt = ($type eq 'Polygon' ? 'POLYGON' : 'MULTILINESTRING') . '('
      . join(',', map { '(' . join(',', map { join ' ', @$_ } @$_) . ')' } @$coords)
      . ')';
  }
  elsif ($type eq 'MultiPolygon') {
    $wkt = 'MULTIPOLYGON('
      . join(',',
          map { '('
            . join(',', map { '(' . join(',', map { join ' ', @$_ } @$_) . ')' } @$_)
            . ')'
          } @$coords)
      . ')';
  }
  else {
    DBIO::Exception->throw("from_geojson: unsupported type '$type'");
  }
  return $class->new(
    wkt           => $wkt,
    srid          => $srid,
    geometry_type => uc($wkt =~ /\A([A-Z]+)/ ? $1 : ''),
    coordinates   => $coords,
  );
}


sub srid          { $_[0]{srid} }
sub wkt {
  my $self = shift;
  return $self->{wkt} if defined $self->{wkt};
  return $self->to_wkt;
}
sub ewkb_hex      { $_[0]{ewkb_hex} }

sub geometry_type {
  my $self = shift;
  return $self->{geometry_type} if defined $self->{geometry_type};
  if (defined $self->{wkt} && $self->{wkt} =~ /\A\s*([A-Z]+)/i) {
    return $self->{geometry_type} = uc $1;
  }
  return undef;
}


sub ewkt {
  my $self = shift;
  my $wkt = $self->wkt;
  return undef unless defined $wkt;
  return defined $self->{srid} ? "SRID=$self->{srid};$wkt" : $wkt;
}


sub to_wkt {
  my ($self) = @_;
  return $self->{wkt} if defined $self->{wkt};
  return DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder->build({
    type   => $self->geometry_type,
    coords => $self->coordinates,
    has_z  => (defined $self->z ? 1 : 0),
  });
}


sub coordinates {
  my $self = shift;
  return $self->{coordinates} if defined $self->{coordinates};
  my $wkt = $self->wkt;
  return undef unless defined $wkt;
  my $parsed = DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser->parse($wkt);
  return $self->{coordinates} = $parsed ? $parsed->{coords} : undef;
}


sub x { my $c = $_[0]->coordinates; ref $c eq 'ARRAY' ? $c->[0] : undef }
sub y { my $c = $_[0]->coordinates; ref $c eq 'ARRAY' ? $c->[1] : undef }
sub z { my $c = $_[0]->coordinates; ref $c eq 'ARRAY' ? $c->[2] : undef }


sub is_empty {
  my $self = shift;
  my $wkt = $self->wkt;
  return defined $wkt && $wkt =~ /EMPTY\b/i ? 1 : 0;
}


sub bbox {
  my $self = shift;
  my $coords = $self->coordinates;
  return undef unless defined $coords;
  my (@xs, @ys);
  _walk_xy($coords, \@xs, \@ys);
  return undef unless @xs;
  my @sx = sort { $a <=> $b } @xs;
  my @sy = sort { $a <=> $b } @ys;
  return [ $sx[0], $sy[0], $sx[-1], $sy[-1] ];
}

sub _walk_xy {
  my ($node, $xs, $ys) = @_;
  return unless ref $node eq 'ARRAY';
  if (@$node && !ref $node->[0]) {
    push @$xs, $node->[0];
    push @$ys, $node->[1];
    return;
  }
  _walk_xy($_, $xs, $ys) for @$node;
}


sub to_geojson {
  my $self = shift;
  my $type = $self->geometry_type or return undef;
  my $coords = $self->coordinates;
  return undef unless defined $coords;
  my %map = (
    POINT => 'Point', LINESTRING => 'LineString', POLYGON => 'Polygon',
    MULTIPOINT => 'MultiPoint', MULTILINESTRING => 'MultiLineString',
    MULTIPOLYGON => 'MultiPolygon',
  );
  my $gj_type = $map{$type} or return undef;
  return { type => $gj_type, coordinates => $coords };
}


sub to_ogr {
  my $self = shift;
  require Geo::OGR;
  return Geo::OGR::Geometry->new(WKT => $self->wkt);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Geometry - Lightweight PostGIS geometry/geography value object

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  use DBIO::PostgreSQL::PostGIS::Geometry;

  # From WKT
  my $point = DBIO::PostgreSQL::PostGIS::Geometry->from_wkt(
    'POINT(13.4 52.5)', srid => 4326,
  );

  # From WKB hex (what PostGIS returns by default)
  my $g = DBIO::PostgreSQL::PostGIS::Geometry->from_ewkb_hex($hex);

  $point->srid;            # 4326
  $point->geometry_type;   # 'POINT'
  $point->wkt;             # 'POINT(13.4 52.5)'
  $point->ewkt;            # 'SRID=4326;POINT(13.4 52.5)'
  $point->coordinates;     # [13.4, 52.5]
  $point->x; $point->y;
  $point->is_empty;

  # Helpers
  $point->to_geojson;      # { type => 'Point', coordinates => [...] }
  $point->bbox;            # [xmin, ymin, xmax, ymax]

=head1 DESCRIPTION

A lightweight Perl-side representation of a PostGIS geometry or geography
value. Stores SRID + WKT (lazily parsed). Optional inflate path through
L<Geo::OGR> when installed for heavy spatial operations.

This object is what L<DBIO::PostgreSQL::PostGIS> inflates C<geometry>
and C<geography> column values to. On the way out (deflate) it serializes
back to EWKT for the database.

=head1 METHODS

=head2 from_wkt

  my $g = DBIO::PostgreSQL::PostGIS::Geometry->from_wkt($wkt, srid => 4326);

Constructs from a Well-Known Text representation.

=head2 from_ewkt

  my $g = DBIO::PostgreSQL::PostGIS::Geometry->from_ewkt('SRID=4326;POINT(0 0)');

Parses an Extended WKT string (PostGIS's C<SRID=N;WKT> form).

=head2 from_ewkb_hex

  my $g = DBIO::PostgreSQL::PostGIS::Geometry->from_ewkb_hex($hex);

Constructs from PostGIS's default hex-encoded EWKB output. Stores the
hex unparsed; geometry_type/coordinates are decoded lazily on demand.

=head2 point

  my $p = DBIO::PostgreSQL::PostGIS::Geometry->point($x, $y, srid => 4326);
  my $p = DBIO::PostgreSQL::PostGIS::Geometry->point($x, $y, $z, srid => 4326);

Constructs a POINT geometry. Accepts 2 or 3 numeric coords followed by
named options (currently just C<srid>).

=head2 from_lat_lon

  my $p = DBIO::PostgreSQL::PostGIS::Geometry->from_lat_lon($lat, $lon);

Convenience for building a 4326 POINT from latitude/longitude. Note the
order: lat first (the human convention), but the WKT/PostGIS axis order
is C<POINT(lon lat)> — this method swaps for you.

=head2 linestring

  my $l = DBIO::PostgreSQL::PostGIS::Geometry->linestring(
    [[0,0],[1,1],[2,0]], srid => 4326,
  );

=head2 polygon

  my $p = DBIO::PostgreSQL::PostGIS::Geometry->polygon(
    [ [[0,0],[10,0],[10,10],[0,10],[0,0]] ],   # outer ring + optional holes
    srid => 4326,
  );

=head2 bbox_polygon

  my $b = DBIO::PostgreSQL::PostGIS::Geometry->bbox_polygon(
    $xmin, $ymin, $xmax, $ymax, srid => 4326,
  );

Convenience for an axis-aligned rectangle as a closed POLYGON ring.

=head2 from_geojson

  my $g = DBIO::PostgreSQL::PostGIS::Geometry->from_geojson(\%geojson);
  my $g = DBIO::PostgreSQL::PostGIS::Geometry->from_geojson(\%geojson, srid => 4326);

Builds from a GeoJSON-shaped hashref. SRID defaults to 4326 (per the
GeoJSON spec) unless overridden.

=head2 srid

=head2 wkt

=head2 ewkb_hex

=head2 geometry_type

The geometry type as an upper-case string: C<POINT>, C<LINESTRING>,
C<POLYGON>, C<MULTIPOINT>, C<MULTILINESTRING>, C<MULTIPOLYGON>,
C<GEOMETRYCOLLECTION>. Lazily derived from WKT or EWKB.

=head2 ewkt

Returns C<SRID=N;WKT> if SRID is set, otherwise the bare WKT.

=head2 to_wkt

Returns the WKT string. Uses stored wkt if available; otherwise builds
from coordinates using L<DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder>.

=head2 coordinates

Returns the parsed coordinate structure for simple geometry types
(POINT → [x,y], LINESTRING → [[x,y],...], POLYGON → [[[x,y],...],...]).
Returns undef when the geometry is too complex to parse from WKT alone
(use L</to_geojson> via L<Geo::OGR> for those).

=head2 x

=head2 y

=head2 z

Convenience accessors for POINT geometries.

=head2 is_empty

True if this represents an empty geometry (e.g. C<POINT EMPTY>).

=head2 bbox

Returns the bounding box as C<[xmin, ymin, xmax, ymax]>. Requires
coordinate parsing or a Geo::OGR fallback.

=head2 to_geojson

Returns a GeoJSON-shaped hashref for the simple geometry types.

=head2 to_ogr

Returns a L<Geo::OGR::Geometry> object if Geo::OGR is installed; dies
otherwise.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
