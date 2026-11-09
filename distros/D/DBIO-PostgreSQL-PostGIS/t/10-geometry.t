use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Geometry;
my $G = 'DBIO::PostgreSQL::PostGIS::Geometry';

subtest point => sub {
  my $p = $G->point(13.4, 52.5, srid => 4326);
  is $p->wkt,           'POINT(13.4 52.5)';
  is $p->ewkt,          'SRID=4326;POINT(13.4 52.5)';
  is $p->geometry_type, 'POINT';
  is $p->srid,          4326;
  is_deeply $p->coordinates, [13.4, 52.5];
  is $p->x, 13.4;
  is $p->y, 52.5;
  ok !$p->is_empty;
};

subtest from_lat_lon => sub {
  my $p = $G->from_lat_lon(52.5, 13.4);
  # lat/lon → POINT(lon lat)
  is_deeply $p->coordinates, [13.4, 52.5];
  is $p->srid, 4326;
};

subtest from_ewkt => sub {
  my $p = $G->from_ewkt('SRID=3857;POINT(1 2)');
  is $p->srid, 3857;
  is $p->wkt,  'POINT(1 2)';
};

subtest linestring => sub {
  my $l = $G->linestring([[0,0],[1,1],[2,0]], srid => 4326);
  is $l->wkt, 'LINESTRING(0 0,1 1,2 0)';
  is_deeply $l->coordinates, [[0,0],[1,1],[2,0]];
  is_deeply $l->bbox, [0, 0, 2, 1];
};

subtest polygon => sub {
  my $poly = $G->polygon(
    [[ [0,0],[10,0],[10,10],[0,10],[0,0] ]],
    srid => 4326,
  );
  is $poly->wkt, 'POLYGON((0 0,10 0,10 10,0 10,0 0))';
  is_deeply $poly->coordinates,
    [[ [0,0],[10,0],[10,10],[0,10],[0,0] ]];
  is_deeply $poly->bbox, [0, 0, 10, 10];
};

subtest bbox_polygon => sub {
  my $b = $G->bbox_polygon(0, 0, 5, 5, srid => 4326);
  is_deeply $b->bbox, [0, 0, 5, 5];
  is $b->geometry_type, 'POLYGON';
};

subtest empty => sub {
  my $e = $G->from_wkt('POINT EMPTY');
  ok $e->is_empty;
};

subtest geojson_roundtrip => sub {
  my $gj = { type => 'Point', coordinates => [10, 20] };
  my $g = $G->from_geojson($gj);
  is $g->wkt, 'POINT(10 20)';
  is $g->srid, 4326;
  is_deeply $g->to_geojson, $gj;
};

subtest geojson_polygon => sub {
  my $gj = {
    type => 'Polygon',
    coordinates => [[ [0,0],[1,0],[1,1],[0,1],[0,0] ]],
  };
  my $g = $G->from_geojson($gj);
  is $g->wkt, 'POLYGON((0 0,1 0,1 1,0 1,0 0))';
  is_deeply $g->to_geojson, $gj;
};

# to_geojson answers for an object whatever built it (karr k13). The
# codec-backed constructors -- from_wkt and from_ewkb_hex, which is what
# every value read from the database goes through -- used to carry a
# lower-case geometry_type, the others an upper-case one (all are
# upper-case since karr k17). A GeoJSON type picked by an exact-case
# lookup left the codec-backed half answering undef.

# EWKB hex of a little-endian geometry: header, then the body.
my $ewkb = sub {
  my ($type_id, $srid, $body) = @_;
  return unpack 'H*', pack('C V V', 1, 0x20000000 | $type_id, $srid) . $body;
};
# A member geometry inside a MULTI*: its own header, no SRID.
my $member = sub { pack('C V', 1, $_[0]) . $_[1] };
my $points = sub { join '', map { pack 'd< d<', @$_ } @_ };
my $ring   = sub { pack('V', scalar @_) . $points->(@_) };

my @tri_a = ([0,0],[4,0],[4,4],[0,0]);
my @tri_b = ([10,10],[14,10],[14,14],[10,10]);

my @shapes = (
  {
    name => 'Point',
    wkt  => 'POINT(13.4 52.5)',
    hex  => $ewkb->(1, 4326, $points->([13.4, 52.5])),
    gj   => { type => 'Point', coordinates => [13.4, 52.5] },
  },
  {
    name => 'LineString',
    wkt  => 'LINESTRING(0 0,1 1,2 0)',
    hex  => $ewkb->(2, 4326, $ring->([0,0],[1,1],[2,0])),
    gj   => { type => 'LineString', coordinates => [[0,0],[1,1],[2,0]] },
  },
  {
    name => 'Polygon',
    wkt  => 'POLYGON((0 0,4 0,4 4,0 0))',
    hex  => $ewkb->(3, 4326, pack('V', 1) . $ring->(@tri_a)),
    gj   => { type => 'Polygon', coordinates => [[@tri_a]] },
  },
  {
    name => 'MultiPoint',
    wkt  => 'MULTIPOINT((1 2),(3 4))',
    hex  => $ewkb->(4, 4326, pack('V', 2)
      . $member->(1, $points->([1,2]))
      . $member->(1, $points->([3,4]))),
    gj   => { type => 'MultiPoint', coordinates => [[1,2],[3,4]] },
  },
  {
    name => 'MultiLineString',
    wkt  => 'MULTILINESTRING((0 0,1 1),(2 2,3 3))',
    hex  => $ewkb->(5, 4326, pack('V', 2)
      . $member->(2, $ring->([0,0],[1,1]))
      . $member->(2, $ring->([2,2],[3,3]))),
    gj   => {
      type        => 'MultiLineString',
      coordinates => [[[0,0],[1,1]],[[2,2],[3,3]]],
    },
  },
  {
    name => 'MultiPolygon',
    wkt  => 'MULTIPOLYGON(((0 0,4 0,4 4,0 0)),((10 10,14 10,14 14,10 10)))',
    hex  => $ewkb->(6, 4326, pack('V', 2)
      . $member->(3, pack('V', 1) . $ring->(@tri_a))
      . $member->(3, pack('V', 1) . $ring->(@tri_b))),
    gj   => {
      type        => 'MultiPolygon',
      coordinates => [[[@tri_a]],[[@tri_b]]],
    },
  },
);

subtest 'to_geojson from_wkt' => sub {
  for my $shape (@shapes) {
    is_deeply $G->from_wkt($shape->{wkt})->to_geojson, $shape->{gj},
      "$shape->{name} parsed from WKT";
  }
};

subtest 'to_geojson from_ewkb_hex' => sub {
  for my $shape (@shapes) {
    my $g = $G->from_ewkb_hex($shape->{hex});
    ok $g, "$shape->{name} decodes" or next;
    is_deeply $g->to_geojson, $shape->{gj},
      "$shape->{name} decoded from EWKB hex";
  }
};

subtest 'to_geojson is the same for every origin' => sub {
  my $point = $shapes[0];
  my %origin = (
    point         => $G->point(13.4, 52.5, srid => 4326),
    from_lat_lon  => $G->from_lat_lon(52.5, 13.4),
    from_wkt      => $G->from_wkt($point->{wkt}, srid => 4326),
    from_ewkt     => $G->from_ewkt("SRID=4326;$point->{wkt}"),
    from_ewkb_hex => $G->from_ewkb_hex($point->{hex}),
    from_geojson  => $G->from_geojson($point->{gj}),
  );
  is_deeply $origin{$_}->to_geojson, $point->{gj}, $_
    for sort keys %origin;

  my @line = ([0,0],[1,1],[2,0]);
  is_deeply $G->linestring(\@line)->to_geojson, $shapes[1]{gj}, 'linestring';
  is_deeply $G->polygon([\@tri_a])->to_geojson, $shapes[2]{gj}, 'polygon';
};

subtest multipolygon_parse => sub {
  my $mp = $G->from_wkt('MULTIPOLYGON(((0 0,1 0,1 1,0 1,0 0)),((2 2,3 2,3 3,2 3,2 2)))');
  my $coords = $mp->coordinates;
  is scalar @$coords, 2, 'two polygons';
  is_deeply $coords->[0], [[ [0,0],[1,0],[1,1],[0,1],[0,0] ]];
  is_deeply $mp->bbox, [0, 0, 3, 3];
};

# An object that was given neither WKT nor coordinates has nothing to
# answer from (karr k20). wkt built its WKT from the coordinates and
# coordinates parsed its coordinates from the WKT, so such an object
# asked the one for the other without end. Perl does not stop a
# recursion, it only warns at depth 100 and then grows until the memory
# is gone.
#
# So no call below runs unguarded: the warning is turned into a die,
# which unwinds the stack, and each call has its own eval, so a
# recursion shows as one failed assertion naming the method. The alarm
# is for a call that hangs without recursing; it does not bound memory.
my $answer = sub {
  my ($geometry, $method) = @_;
  my $value;
  my $returned = eval {
    local $SIG{__WARN__} = sub {
      die $_[0] if $_[0] =~ /Deep recursion/;
      warn $_[0];
    };
    local $SIG{ALRM} = sub { die "$method did not return within 5 seconds\n" };
    alarm 5;
    $value = $geometry->$method;
    alarm 0;
    1;
  };
  my $error = $@;
  alarm 0;
  return $returned ? { returned => $value } : { died => $error };
};

subtest 'neither WKT nor coordinates' => sub {
  my $hex = $shapes[0]{hex};
  my @bare = (
    [ 'new(srid)'          => $G->new(srid => 4326) ],
    [ 'new(ewkb_hex)'      => $G->new(ewkb_hex => $hex) ],
    # With a type, to_geojson gets as far as asking for the coordinates,
    # and a WKT builder handed no coordinates dies on them.
    [ 'new(geometry_type)' => $G->new(geometry_type => 'POINT', srid => 4326) ],
  );

  for my $bare (@bare) {
    my ($name, $g) = @$bare;
    for my $method (qw( wkt to_wkt ewkt coordinates bbox x y z to_geojson )) {
      my $got = $answer->($g, $method);
      is_deeply $got, { returned => undef }, "$name: $method is undef"
        or diag explain $got;
    }

    my $is_empty = $answer->($g, 'is_empty');
    ok exists $is_empty->{returned} && !$is_empty->{returned},
      "$name: is_empty is false"
      or diag explain $is_empty;
  }

  # new stores the hex and decodes nothing; the hex is still what the
  # object has to give.
  is $bare[1][1]->ewkb_hex, $hex, 'new(ewkb_hex): ewkb_hex is the hex given';
};

# A value from_ewkb_hex cannot decode is still a value (karr k15). It
# used to answer undef for it, and the inflater of a geometry column
# passes that on: $row->geom was undef for a row that holds a
# CIRCULARSTRING, which no caller can tell from SQL NULL, the hex was
# gone, and writing the "value" back stored NULL over the geometry.
#
# So such a value comes back as an object that carries the hex -- the
# one thing that is certain, and what the deflater writes -- together
# with what the header says, and no coordinates. Nothing is derived from
# coordinates it does not have: the answers below are those of the
# object without WKT and coordinates above, and they are asked the same
# guarded way.
subtest 'from_ewkb_hex of a value it does not decode' => sub {
  my $point = $shapes[0]{hex};
  my @undecoded = (
    {
      name => 'a type that is not decoded',
      hex  => $ewkb->(8, 4326, $ring->([0,0],[1,1],[2,0])),
      type => 'circularstring',
      srid => 4326,
    },
    {
      name => 'a collection that holds such a type',
      hex  => $ewkb->(7, 4326, pack('V', 2)
        . $member->(1, $points->([1,2]))
        . $member->(8, $ring->([0,0],[1,1],[2,0]))),
      type => 'geometrycollection',
      srid => 4326,
    },
    {
      name => 'a MULTIPOINT that holds a line',
      hex  => $ewkb->(4, 4326, pack('V', 1)
        . $member->(2, $ring->([0,0],[1,1]))),
      type => 'multipoint',
      srid => 4326,
    },
    {
      name => 'a type id without a name',
      hex  => $ewkb->(99, 4326, $points->([1,2])),
      type => undef,
      srid => 4326,
    },
    {
      name => 'a point cut off in its body',
      hex  => substr($point, 0, 34),
      type => 'point',
      srid => 4326,
    },
    # Not even a header to go by: the hex is all there is.
    {
      name => 'a header cut off inside its SRID',
      hex  => substr($point, 0, 12),
    },
    {
      name => 'a byte order that is none',
      hex  => '02' . substr($point, 2),
    },
    {
      name => 'hex that is no EWKB',
      hex  => 'deadbeef',
    },
  );

  # The first fixture is built with the helpers above; this is the hex a
  # PostGIS server sends for ST_GeomFromText('CIRCULARSTRING(0 0,1 1,2 0)',
  # 4326), so the type id in it is the server's and not this file's.
  is $undecoded[0]{hex}, lc '0108000020E61000000300000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000',
    'the CIRCULARSTRING fixture is what the server sends';

  for my $case (@undecoded) {
    my ($name, $hex) = @$case{qw( name hex )};
    my $g = $G->from_ewkb_hex($hex);
    isa_ok $g, $G, "$name: from_ewkb_hex answers with an object, and it"
      or next;

    is $g->ewkb_hex,      $hex,          "$name: ewkb_hex is the hex given";
    is $g->srid,          $case->{srid}, "$name: srid as far as the header says";
    is $g->geometry_type, (defined $case->{type} ? uc $case->{type} : undef),
      "$name: geometry_type likewise";

    for my $method (qw( wkt to_wkt ewkt coordinates bbox x y z to_geojson )) {
      my $got = $answer->($g, $method);
      is_deeply $got, { returned => undef }, "$name: $method is undef"
        or diag explain $got;
    }
    my $is_empty = $answer->($g, 'is_empty');
    ok exists $is_empty->{returned} && !$is_empty->{returned},
      "$name: is_empty is false"
      or diag explain $is_empty;
  }
};

# The other side of that line: without a value there is no object. An
# empty string is no hex, not hex that failed to decode, and from_ewkb_hex
# answers undef for it. undef is not a value either, but unlike '' it is a
# call that cannot be meant: it throws, as from_wkt and from_ewkt do (karr
# k25), and does not warn from inside the decoder's pack.
subtest 'from_ewkb_hex without a value' => sub {
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  is $G->from_ewkb_hex(''), undef, 'an empty string: undef';
  my $ok = eval { $G->from_ewkb_hex(undef); 1 };
  my $err = $@;
  ok !$ok, 'undef: throws';
  isa_ok $err, 'DBIO::Exception';
  like "$err", qr/from_ewkb_hex requires/, '... and says what it wants';
  is_deeply \@warn, [], 'no uninitialized warning';
};

# Coordinates without a geometry_type have no WKT (karr k23). The builder
# used to answer '()' for them, with an "uninitialized" warning.
subtest 'to_wkt of coordinates without a geometry_type' => sub {
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  for my $srid (undef, 4326) {
    my $g = $G->new(coordinates => [1, 2], defined $srid ? (srid => $srid) : ());
    my $tag = defined $srid ? 'with srid' : 'without srid';
    is $g->to_wkt, undef, "to_wkt $tag: undef, not '()'";
    is $g->wkt,    undef, "wkt $tag: undef";
    is $g->ewkt,   undef, "ewkt $tag: undef";
  }
  is_deeply \@warn, [], 'no uninitialized warning';
};

# from_ewkt reads the SRID prefix the way PostGIS does (karr k16): any case,
# blanks around the number and before the semicolon. Measured against the
# server: 'srid=4326;', 'Srid=4326;', ' SRID=4326;', 'SRID=4326 ;' and
# 'SRID=4326; POINT' are accepted; 'SRID = 4326;' is a parse error there and
# is not read as a prefix here either.
subtest 'from_ewkt prefix as PostGIS accepts it' => sub {
  for my $ewkt ('srid=4326;POINT(1 2)', 'Srid=4326;POINT(1 2)',
                ' SRID=4326;POINT(1 2)', 'SRID=4326 ;POINT(1 2)',
                'SRID=4326; POINT(1 2)') {
    my $g = $G->from_ewkt($ewkt);
    is $g->srid, 4326,          "'$ewkt': srid";
    is $g->wkt,  'POINT(1 2)',  "'$ewkt': wkt without the prefix";
    is $g->ewkt, 'SRID=4326;POINT(1 2)', "'$ewkt': ewkt normalised";
  }
  my $bare = $G->from_ewkt('POINT(1 2)');
  is $bare->srid, undef, 'no prefix: no srid';
  is $bare->wkt, 'POINT(1 2)', 'no prefix: wkt as given';
  is $G->from_ewkt('SRID = 4326;POINT(1 2)')->srid, undef,
    'blanks inside the prefix: not a prefix (the server refuses it)';
};

# x, y and z are the ordinates of a point (karr k16). For anything else they
# are undef -- they used to be the first, second and third point as an
# arrayref. The type is judged case-independent, as it is upper-case from
# some constructors and lower-case from others.
subtest 'x y z are the ordinates of a point' => sub {
  my $xyz = sub { ($_[0]->x, $_[0]->y, $_[0]->z) };

  is_deeply [ $xyz->($G->point(1, 2)) ], [1, 2, undef], 'point(1,2): z undef';
  is_deeply [ $xyz->($G->from_wkt('POINT Z (1 2 3)')) ], [1, 2, 3],
    'POINT Z: z is the Z ordinate';
  is_deeply [ $xyz->($G->from_wkt('POINT(1 2)')) ], [1, 2, undef],
    'POINT without Z: z undef';
  is_deeply [ $xyz->($G->from_ewkt('SRID=4326;POINT Z (1 2 3)')) ], [1, 2, 3],
    'EWKT POINT Z';
  is_deeply [ $xyz->($G->from_wkt('POINT M (1 2 9)')) ], [1, 2, undef],
    'POINT M: the third ordinate is the measure, not z';
  is_deeply [ $xyz->($G->from_wkt('POINT EMPTY')) ], [undef, undef, undef],
    'POINT EMPTY: no ordinates';

  my $hex = unpack 'H*', pack('C V d< d<', 1, 1, 5, 6);
  is_deeply [ $xyz->($G->from_ewkb_hex($hex)) ], [5, 6, undef],
    'a point from EWKB (lower-case type)';
  is_deeply [ $xyz->($G->from_geojson({ type => 'Point', coordinates => [7, 8, 9] })) ],
    [7, 8, 9], 'a GeoJSON point (upper-case type)';

  for my $case (
    [ linestring      => $G->from_wkt('LINESTRING(0 0,1 1,2 0)') ],
    [ polygon         => $G->from_wkt('POLYGON((0 0,1 0,1 1,0 0))') ],
    [ multipoint      => $G->from_wkt('MULTIPOINT((0 0),(1 1))') ],
    [ multipolygon    => $G->from_wkt('MULTIPOLYGON(((0 0,1 0,1 1,0 0)))') ],
    [ collection      => $G->from_wkt('GEOMETRYCOLLECTION(POINT(1 2))') ],
    [ 'linestring (constructor)' => $G->linestring([[0,0],[1,1]]) ],
    [ 'geojson linestring' => $G->from_geojson({ type => 'LineString', coordinates => [[0,0],[1,1]] }) ],
  ) {
    is_deeply [ $xyz->($case->[1]) ], [undef, undef, undef],
      "$case->[0]: x, y, z are undef";
  }
};

# geometry_type is upper-case whatever built the object (karr k17): the
# codec-backed constructors used to answer lower-case, the others upper.
subtest 'geometry_type is upper-case for every constructor and origin' => sub {
  my $pt_hex = $shapes[0]{hex};
  my @origin = (
    [ 'point'                 => $G->point(1, 2),                              'POINT' ],
    [ 'from_lat_lon'          => $G->from_lat_lon(2, 1),                       'POINT' ],
    [ 'linestring'            => $G->linestring([[0,0],[1,1]]),                'LINESTRING' ],
    [ 'polygon'               => $G->polygon([[[0,0],[1,0],[1,1],[0,0]]]),     'POLYGON' ],
    [ 'bbox_polygon'          => $G->bbox_polygon(0, 0, 5, 5),                 'POLYGON' ],
    [ 'from_geojson'          => $G->from_geojson({ type => 'Point', coordinates => [1,2] }), 'POINT' ],
    [ 'from_wkt'              => $G->from_wkt('POINT(1 2)'),                   'POINT' ],
    [ 'from_wkt lower-case'   => $G->from_wkt('point(1 2)'),                   'POINT' ],
    [ 'from_ewkt'             => $G->from_ewkt('SRID=4326;LINESTRING(0 0,1 1)'), 'LINESTRING' ],
    [ 'from_ewkt POINTM'      => $G->from_ewkt('SRID=4326;POINTM(1 2 9)'),     'POINT' ],
    [ 'new(wkt)'              => $G->new(wkt => 'POLYGON((0 0,1 0,1 1,0 0))'), 'POLYGON' ],
    [ 'new(geometry_type)'    => $G->new(geometry_type => 'point'),            'POINT' ],
    [ 'from_ewkb_hex'         => $G->from_ewkb_hex($pt_hex),                   'POINT' ],
  );
  push @origin, map { [ "from_ewkb_hex $_->{name}" => $G->from_ewkb_hex($_->{hex}), uc $_->{name} ] } @shapes;
  push @origin, [ 'from_ewkb_hex undecoded type',
    $G->from_ewkb_hex($ewkb->(8, 4326, $ring->([0,0],[1,1],[2,0]))), 'CIRCULARSTRING' ];

  for my $o (@origin) {
    my ($name, $g, $want) = @$o;
    is $g->geometry_type, $want, "$name: geometry_type is upper-case";
  }
};

done_testing;
