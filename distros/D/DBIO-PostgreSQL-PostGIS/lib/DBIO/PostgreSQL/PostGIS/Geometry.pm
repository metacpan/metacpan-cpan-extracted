package DBIO::PostgreSQL::PostGIS::Geometry;
# ABSTRACT: Lightweight PostGIS geometry/geography value object

use strict;
use warnings;

our $VERSION = '0.900004';

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
    geometry_type => defined $args{geometry_type} ? uc $args{geometry_type} : undef,
    coordinates   => $args{coordinates},
    has_z        => $args{has_z},
    has_m         => $args{has_m},
    is_empty      => $args{is_empty},
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
  if ($ewkt =~ /\A\s*srid=(\d+)\s*;\s*(.+)\z/is) {
    return $class->new(srid => $1, wkt => $2);
  }
  return $class->new(wkt => $ewkt);
}


sub from_ewkb_hex {
  my ($class, $hex) = @_;
  DBIO::Exception->throw("from_ewkb_hex requires an EWKB hex string") unless defined $hex;
  my $decoder = 'DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder';
  my $decoded = eval { $decoder->decode_hex($hex) };
  unless ($decoded) {
    # No value: no object.
    return undef unless length $hex;
    # Refused by the decoder. It is a value all the same and must not
    # read as none; its header, if it has one, says what it claims to be.
    $decoded = eval { $decoder->decode_header($hex) } // {};
  }
  return $class->new(
    ewkb_hex      => $hex,
    srid          => $decoded->{srid},
    geometry_type => $decoded->{type},
    coordinates   => $decoded->{coords},
    has_z         => $decoded->{has_z},
    has_m         => $decoded->{has_m},
    is_empty      => $decoded->{is_empty},
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
    # ST_AsEWKT glues the M of a measured geometry to the type: POINTM(...).
    # No geometry type ends in Z or M, so the marker is told by that.
    (my $type = uc $1) =~ s/(?:ZM|Z|M)\z//;
    return $self->{geometry_type} = $type;
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
  # The stored coordinates, not ->coordinates: without them that method
  # asks for the WKT, which is this one.
  my $coords = $self->{coordinates};
  return undef unless defined $coords;
  # Coordinates are not a WKT without the type they are coordinates of;
  # the builder would write '()'.
  return undef unless defined $self->geometry_type;
  my ($has_z, $has_m) = $self->_dimension_flags($coords);
  return DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder->build({
    type     => $self->geometry_type,
    coords   => $coords,
    has_z    => $has_z,
    has_m    => $has_m,
    is_empty => $self->{is_empty},
  });
}

# Why this object cannot be written to the database or bound as a helper
# argument, as the message of the exception for it (karr k23); undef when it
# can. A hex, a WKT or coordinates under a type are a writable form.
sub _unwritable_reason {
  my ($self) = @_;
  my $hex = $self->ewkb_hex;
  return undef if defined $hex && length $hex;
  return undef if defined $self->wkt;
  return 'Geometry has coordinates but no geometry_type, so no WKT can be built from them'
    if defined $self->{coordinates};
  return 'Geometry has no ewkb_hex, wkt or coordinates, so there is nothing to write';
}

# Z/M of a geometry that has no WKT to say it: the flags given to the
# constructor, else the number of ordinates of one point. Never the shape
# of the coordinate list -- its third element is a Z only for a POINT; for
# a line it is the third point, for a polygon the third ring.
sub _dimension_flags {
  my ($self, $coords) = @_;
  if (defined $self->{has_z} or defined $self->{has_m}) {
    return ($self->{has_z} ? 1 : 0, $self->{has_m} ? 1 : 0);
  }
  my $point = $coords;
  $point = $point->[0] while ref $point eq 'ARRAY' and ref $point->[0];
  my $ordinates = ref $point eq 'ARRAY' ? scalar @$point : 0;
  return ($ordinates >= 3 ? 1 : 0, $ordinates >= 4 ? 1 : 0);
}


sub coordinates {
  my $self = shift;
  return $self->{coordinates} if defined $self->{coordinates};
  my $wkt = $self->wkt;
  return undef unless defined $wkt;
  my $parsed = DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser->parse($wkt);
  return $self->{coordinates} = $parsed ? $parsed->{coords} : undef;
}


sub _point_ordinate {
  my ($self, $i) = @_;
  my $type = $self->geometry_type;
  return undef unless defined $type && $type eq 'POINT';
  my $c = $self->coordinates;
  return undef unless ref $c eq 'ARRAY' && !ref $c->[0];
  return $c->[$i] if $i < 2;
  return undef unless @$c > 2;
  # A third ordinate of a measured point is M, not Z.
  if (@$c == 3) {
    return undef if $self->{has_m} && !$self->{has_z};
    my $wkt = $self->{wkt};
    return undef if !defined $self->{has_z} && !defined $self->{has_m}
      && defined $wkt && $wkt =~ /\A\s*POINT\s*M\b/i;
  }
  return $c->[2];
}

sub x { $_[0]->_point_ordinate(0) }
sub y { $_[0]->_point_ordinate(1) }
sub z { $_[0]->_point_ordinate(2) }


sub is_empty {
  my $self = shift;
  return $self->{is_empty} ? 1 : 0 if defined $self->{is_empty};
  my $wkt = $self->wkt;
  # A number in the WKT is a real ordinate: EMPTY as one part of several
  # (MULTIPOINT(EMPTY,(1 2))) does not make the whole empty.
  return defined $wkt && $wkt =~ /EMPTY\b/i && $wkt !~ /[0-9]/ ? 1 : 0;
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
  # A member of a collection: its type does not matter for the extent.
  $node = $node->{coords} if ref $node eq 'HASH';
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
  if ($type eq 'GEOMETRYCOLLECTION') {
    # A collection from WKT has no coordinates (the parser does not read
    # it); it is known to be empty, and then it has no members to give.
    return { type => 'GeometryCollection', geometries => [] }
      if !defined $coords && $self->is_empty;
  }
  return undef unless defined $coords;
  return _geojson($type, $coords);
}

# GeoJSON of one geometry, or a member of a collection: undef for a type
# GeoJSON has no name for.
sub _geojson {
  my ($type, $coords) = @_;
  my %map = (
    POINT => 'Point', LINESTRING => 'LineString', POLYGON => 'Polygon',
    MULTIPOINT => 'MultiPoint', MULTILINESTRING => 'MultiLineString',
    MULTIPOLYGON => 'MultiPolygon',
  );
  # The type of a collection member comes from the codec, lower-case.
  if (uc $type eq 'GEOMETRYCOLLECTION') {
    my @geometries = map { _geojson($_->{type}, $_->{coords}) } @$coords;
    return { type => 'GeometryCollection', geometries => \@geometries };
  }
  my $gj_type = $map{uc $type} or return undef;
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

version 0.900004

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
value. Stores SRID + WKT or EWKB-hex. Optional inflate path through
L<Geo::OGR> when installed for heavy spatial operations.

This object is what L<DBIO::PostgreSQL::PostGIS> inflates C<geometry>
and C<geography> column values to. On the way out (deflate) an object
that carries EWKB hex -- every value read from the database does -- goes
back as that hex, unchanged, so a geometry that is read and written again
keeps its type, its dimension and its exact doubles. An object built in
Perl has no hex and is serialized to EWKT.

=head1 METHODS

=head2 new

  my $g = DBIO::PostgreSQL::PostGIS::Geometry->new(
    geometry_type => 'POINT',
    coordinates   => [1, 2, 9],
    has_m         => 1,
    srid          => 4326,
  );

The plain constructor behind all the others. Takes C<srid>, C<wkt>,
C<ewkb_hex>, C<geometry_type>, C<coordinates>, C<has_z>, C<has_m> and
C<is_empty> and stores them as given -- C<geometry_type> upper-cased, see
L</geometry_type>; nothing is parsed, and nothing is
checked against anything else. C<has_z> and C<has_m> say what the third
and fourth ordinate of every point are. They matter only where the WKT
has to be built from C<coordinates>, see L</to_wkt>. C<is_empty>, if
given, is what L</is_empty> answers and what the built WKT is told; left
out, L</is_empty> is judged from the WKT.

WKT and coordinates are derived from one another, so an object given
neither has neither: L</wkt>, L</ewkt>, L</coordinates> and L</bbox>
return C<undef>. That holds for C<< new(ewkb_hex => $hex) >> too -- the
hex is kept for L</ewkb_hex> and not decoded; L</from_ewkb_hex> decodes.

=head2 from_wkt

  my $g = DBIO::PostgreSQL::PostGIS::Geometry->from_wkt($wkt, srid => 4326);

Constructs from a Well-Known Text representation. Nesting of collections is
limited to 32 levels; deeper input throws.

=head2 from_ewkt

  my $g = DBIO::PostgreSQL::PostGIS::Geometry->from_ewkt('SRID=4326;POINT(0 0)');

Parses an Extended WKT string (PostGIS's C<SRID=N;WKT> form). The prefix
is read the way PostGIS accepts it: C<SRID> in any case, blanks before it,
before the semicolon and after it. C<SRID = 4326;...> is refused by PostGIS
and is not read as a prefix. The object's C<srid> is the number and its
C<wkt> the text behind the semicolon; a string without a prefix is the WKT
as given, without an C<srid>.

=head2 from_ewkb_hex

  my $g = DBIO::PostgreSQL::PostGIS::Geometry->from_ewkb_hex($hex);

Constructs from PostGIS's default hex-encoded EWKB output. The hex is
decoded eagerly: C<srid>, C<geometry_type> and C<coordinates> are
populated at construction, and the hex is kept for L</ewkb_hex>.

The Z and M flags of the EWKB are kept with the object, so the WKT it
builds (L</wkt>, L</ewkt>, L</to_wkt>) carries the dimension the geometry
has: C<POINT M(1 2 9)> stays M, a two-dimensional line stays
two-dimensional however many points it has. The hex itself is what a
column deflates to when the object is written back.

B<A value that is not decoded is still an object.> PostGIS has
geometry types the decoder names and does not decode --
C<CIRCULARSTRING>, C<COMPOUNDCURVE>, C<CURVEPOLYGON>, C<MULTICURVE>,
C<MULTISURFACE>, C<POLYHEDRALSURFACE>, C<TIN>, C<TRIANGLE>, and a
C<GEOMETRYCOLLECTION> that holds one of them (see
L<DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder>). For such a value the
object carries the hex as given, the C<srid>, the Z and M flags and the
C<geometry_type> of the EWKB header (C<circularstring>, ...), and no
coordinates. L</coordinates>, L</wkt>, L</ewkt>, L</to_wkt>, L</bbox>,
L</x>, L</y>, L</z> and L</to_geojson> return C<undef>, and L</is_empty>
is false, whatever the geometry holds.

An empty geometry is decoded like any other: L</is_empty> is true,
L</coordinates> is C<[]>, L</wkt> is C<TYPE EMPTY> (C<POINT EMPTY>,
C<POINT Z EMPTY>), L</bbox> is C<undef>, and L</to_geojson> gives the
type with empty C<coordinates>. The members of a C<GEOMETRYCOLLECTION>
come with their types, see L</coordinates>. L</ewkb_hex> is the value, and a
column deflates to it, so the geometry is read and written back
unchanged although Perl does not know its coordinates.

An object, and neither C<undef> nor an exception: C<undef> is what a
column gives for C<NULL>, so a row holding a curve would read like a row
holding nothing, and the "value" written to another row would store
C<NULL>; an exception would make such a row unreadable. The object
keeps it readable and writable. L</from_wkt> does the same for a WKT its
parser cannot read.

The same goes for any other defined, non-empty string, including one
that is no EWKB at all: the object carries the string as its
L</ewkb_hex>, the C<srid>, flags and C<geometry_type> of its header if
the whole header can be read (as with a body that is cut off), and none
of them otherwise. PostGIS does not send such a value; written back, it
goes to the server as it is, and the server refuses what it cannot read.

There is no object for an empty string: it is no hex, and
C<from_ewkb_hex> returns C<undef> for it. C<undef> is an error, as it is
for L</from_wkt> and L</from_ewkt>: C<from_ewkb_hex> throws a
L<DBIO::Exception>. (It returned C<undef> and warned "uninitialized" from
the decoder. Code that hands over a column value which may be C<NULL>
checks for C<undef> first.)

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

The WKT, stored or built; the same as L</to_wkt>.

=head2 ewkb_hex

=head2 geometry_type

The geometry type, always upper-case, whatever built the object:
C<POINT>, C<LINESTRING>, C<POLYGON>, C<MULTIPOINT>, C<MULTILINESTRING>,
C<MULTIPOLYGON>, C<GEOMETRYCOLLECTION>. An object from L</from_ewkb_hex>
may also be one of the types that are named and not decoded:
C<CIRCULARSTRING>, C<COMPOUNDCURVE>, C<CURVEPOLYGON>, C<MULTICURVE>,
C<MULTISURFACE>, C<POLYHEDRALSURFACE>, C<TIN>, C<TRIANGLE>; and it has no
type (C<undef>) when the hex names none. This holds for every constructor
and for inflated column values, the codecs' lower-case type being
upper-cased on the way in (the column metadata
annotated by L<DBIO::PostgreSQL::PostGIS::Extension> keeps its own, lower-case
spelling). Derived from the WKT when the constructor did not set it,
without the dimension marker ST_AsEWKT glues to it: C<POINTM(1 2 9)> is a
C<POINT>.

=head2 ewkt

Returns C<SRID=N;WKT> if SRID is set, otherwise the bare WKT; C<undef>
when there is no WKT (see L</to_wkt>).

=head2 to_wkt

Returns the WKT string. Uses stored wkt if available; otherwise builds
from coordinates using L<DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder>
-- the case for every object from L</from_ewkb_hex>, and so for every
value read from the database. Returns C<undef> when the object has
neither a stored WKT nor stored coordinates, and when it has coordinates
but no L</geometry_type> to build them under (C<< new(coordinates => [1,2]) >>):
the type is what the WKT is called, so there is nothing to write, and L</wkt>
and L</ewkt> are C<undef> with it. Written to a column or bound by a
spatial helper, such an object is an error, see
L<DBIO::PostgreSQL::PostGIS/register_column>.

An empty geometry builds C<TYPE EMPTY> (C<LINESTRING EMPTY>, with the
marker before C<EMPTY>: C<POINT Z EMPTY>, C<GEOMETRYCOLLECTION M EMPTY>).
A C<GEOMETRYCOLLECTION> builds from its members, each with its type, as
C<ST_AsText> prints it and PostGIS reads it:
C<GEOMETRYCOLLECTION Z(POINT Z(1 2 3),LINESTRING Z(0 0 1,1 1 2))>; the
dimension marker is on the collection and on each member.

The dimension marker of a built WKT (C<Z>, C<M>, C<ZM>) comes from the
C<has_z> / C<has_m> flags the object was constructed with;
L</from_ewkb_hex> takes them from the EWKB. An object constructed without
either flag is judged by the number of ordinates of one of its points:
three are C<Z>, four are C<ZM>. To have three ordinates written as C<M>,
pass C<< has_m => 1 >> to L</new>.

A built WKT holds each ordinate as Perl prints the double, which is 15
significant digits and not always the same number (C<0.1 + 0.2> prints as
C<0.3>). The exact value is in L</ewkb_hex>.

=head2 coordinates

Returns the parsed coordinate structure for simple geometry types
(POINT → [x,y], LINESTRING → [[x,y],...], POLYGON → [[[x,y],...],...]).
Returns undef when the geometry is too complex to parse from WKT alone
(use L</to_geojson> via L<Geo::OGR> for those), and when the object has
neither stored coordinates nor a WKT to parse them from.

An empty geometry has an empty list, C<[]>: C<POINT EMPTY> is C<[]>, not
C<[NaN, NaN]> as PostGIS writes it. An empty part of a C<MULTI*> keeps
its place as an empty list (C<MULTIPOINT(EMPTY,(1 2))> is C<[[], [1,2]]>).

For a C<GEOMETRYCOLLECTION> read from EWKB the structure is a list of its
members, each a hashref C<< { type, coords, is_empty } >> with the
lower-case type of the member and the C<coordinates> it would have on its
own (for a collection in a collection, again such a list). Not the bare
coordinates: those could not be told from each other. A collection made
from WKT has the same list, read by the WKT parser; it has none (C<undef>)
if one member is of a type the parser does not read.

=head2 x

=head2 y

=head2 z

The ordinates of a POINT: C<x> and C<y>, and C<z> if the point has a Z
ordinate. For every other geometry type, for an empty point, and for
C<z> of a point without Z (a C<POINT M> has a measure, not a Z) they
return C<undef>. The type is judged case-independent.

B<Behaviour change:> they used to return, for a geometry that is not a
point, the first, second and third part of its coordinates -- an arrayref.

=head2 is_empty

True if this represents an empty geometry (e.g. C<POINT EMPTY>), as
C<ST_IsEmpty> says: a geometry without parts, or a C<MULTI*> or
C<GEOMETRYCOLLECTION> with nothing but empty ones (C<MULTIPOINT(EMPTY)>).
For an object from L</from_ewkb_hex> this is what the decoder found in
the EWKB: a C<LINESTRING> or C<POLYGON> without points or rings, a
C<MULTI*> or C<GEOMETRYCOLLECTION> without members, a C<POINT> of NaN
ordinates (this is how PostGIS writes C<POINT EMPTY>). For any other
object it is judged from the WKT: C<EMPTY> in it and no number.

False for an object that has no WKT at all, and for a value the decoder
does not decode (see L</from_ewkb_hex>): nothing is known about what
such a value holds.

=head2 bbox

Returns the bounding box as C<[xmin, ymin, xmax, ymax]>. Requires
coordinate parsing or a Geo::OGR fallback; C<undef> when
L</coordinates> has none. For a C<GEOMETRYCOLLECTION> it is the box of
all its members, at any depth. It is C<undef> for an empty geometry, and
for one whose members are all empty, as C<ST_Extent> is C<NULL> for it. An
empty member does not count.

=head2 to_geojson

Returns a GeoJSON-shaped hashref, whatever constructor built the object
— the case L</geometry_type> reports plays no part. Returns C<undef> when
no coordinates can be derived, and for a type that has no GeoJSON form
(the curve types and the like).

An empty geometry gives its type with empty C<coordinates>: C<< { type =>
'Point', coordinates => [] } >> for C<POINT EMPTY>, the same for an
object read from EWKB and one made from WKT; this is what C<ST_AsGeoJSON>
answers, and RFC 7946 allows it. An empty point is C<[]>, not
C<["NaN","NaN"]>.

A C<GEOMETRYCOLLECTION> gives C<< { type => 'GeometryCollection',
geometries => [ ... ] } >>, a GeoJSON hashref for each member, nested for
a collection in a collection (RFC 7946 allows it; PostGIS refuses to
print one). C<GEOMETRYCOLLECTION EMPTY> has C<< geometries => [] >>. An
empty member is kept, as C<< { type => 'Polygon', coordinates => [] } >>;
C<ST_AsGeoJSON> drops some of them (all but an empty two-dimensional
point). Z and M are not told apart: a member's C<coordinates> hold every
ordinate the geometry has, an M one included, where C<ST_AsGeoJSON>
leaves M out.

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
