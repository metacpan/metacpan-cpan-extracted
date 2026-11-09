use strict;
use warnings;
use Test::More;

# Define a tiny in-memory schema that loads the PostGIS component and
# verify the inflate/deflate hooks fire without needing a live database.

{
  package My::Schema::Result::Place;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw( PostgreSQL::PostGIS ));
  __PACKAGE__->table('place');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    geom => { data_type => 'geometry', srid => 4326 },
    area => { data_type => 'geography' },
    plain => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');

  package My::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Place => 'My::Schema::Result::Place');
}

my $source = My::Schema->source('Place');
ok $source, 'source registered';

my $info = $source->columns_info;

# resultset_class promoted automatically
is $source->resultset_class, 'DBIO::PostgreSQL::PostGIS::ResultSet',
  'resultset_class auto-promoted to PostGIS::ResultSet';

# Inflate column registered for geometry columns
ok $info->{geom}{_inflate_info},  'inflate_info set on geometry column';
ok $info->{area}{_inflate_info},  'inflate_info set on geography column';
ok !$info->{plain}{_inflate_info}, 'no inflate_info on plain text column';
ok !$info->{id}{_inflate_info},    'no inflate_info on integer column';

# Run the inflate/deflate closures directly to prove they roundtrip
my $inflate = $info->{geom}{_inflate_info}{inflate};
my $deflate = $info->{geom}{_inflate_info}{deflate};

subtest 'inflate from EWKT' => sub {
  my $g = $inflate->('SRID=4326;POINT(13.4 52.5)', undef);
  isa_ok $g, 'DBIO::PostgreSQL::PostGIS::Geometry';
  is $g->srid, 4326;
  is $g->wkt, 'POINT(13.4 52.5)';
};

subtest 'inflate from EWKB hex' => sub {
  # Little-endian POINT with SRID=4326 (X=13.4, Y=52.5): 25 bytes, 50 hex
  # characters. The hex is computed; a hand-typed one here once had 49
  # characters, which the decoder read as shifted ordinates (karr k18).
  my $hex = unpack('H*', pack('C V V d< d<', 1, 0x20000001, 4326, 13.4, 52.5));
  is length $hex, 50, 'the fixture is 25 bytes';
  my $g = $inflate->($hex, undef);
  isa_ok $g, 'DBIO::PostgreSQL::PostGIS::Geometry';
  is $g->ewkb_hex, $hex;
  is $g->srid, 4326;
  is_deeply $g->coordinates, [13.4, 52.5], 'the coordinates are the ones encoded';
};

subtest 'inflate from plain WKT (uses default srid from column_info)' => sub {
  my $g = $inflate->('POINT(1 2)', undef);
  isa_ok $g, 'DBIO::PostgreSQL::PostGIS::Geometry';
  is $g->srid, 4326, 'defaults to column srid';
};

# A Geometry with nothing to write is an error, not a NULL (karr k23). NULL
# is what undef stands for; an object that has no hex, no WKT and no
# usable coordinates must not be taken for it.
subtest 'deflate of a geometry without a writable form throws' => sub {
  require DBIO::PostgreSQL::PostGIS::Geometry;
  my $G = 'DBIO::PostgreSQL::PostGIS::Geometry';

  is $deflate->(undef, undef), undef, 'undef still deflates to undef (NULL)';

  my $none = eval { $deflate->($G->new(srid => 4326), undef); 1 };
  my $err  = $@;
  ok !$none, 'srid only: throws, no silent NULL';
  isa_ok $err, 'DBIO::Exception';
  like "$err", qr/no ewkb_hex, wkt or coordinates/i,
    'srid only: the message says what is missing';

  for my $srid (undef, 4326) {
    my %srid = defined $srid ? (srid => $srid) : ();
    my $typeless = $G->new(coordinates => [1, 2], %srid);
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    my $ok = eval { $deflate->($typeless, undef); 1 };
    $err = $@;
    ok !$ok, 'coordinates without geometry_type'
      . (defined $srid ? ' and srid' : '') . ': throws';
    isa_ok $err, 'DBIO::Exception';
    like "$err", qr/geometry_type/, '... and names geometry_type';
    is_deeply \@warn, [], '... without an uninitialized warning';
  }

  # An empty hex is no hex: it is the empty string, and the empty string is
  # not a geometry. Alone it is nothing to write; next to a WKT the WKT is
  # what is written, not ''.
  my $emptyhex = eval { $deflate->($G->new(ewkb_hex => ''), undef); 1 };
  $err = $@;
  ok !$emptyhex, 'empty ewkb_hex only: throws, no written empty string';
  isa_ok $err, 'DBIO::Exception';
  like "$err", qr/no ewkb_hex, wkt or coordinates/i,
    'empty ewkb_hex only: the message says what is missing';
  is $deflate->($G->new(ewkb_hex => '', wkt => 'POINT(1 2)', srid => 4326), undef),
    'SRID=4326;POINT(1 2)', 'empty ewkb_hex next to a wkt: the EWKT is written, not an empty string';

  is $deflate->($G->new(ewkb_hex => 'ABCD'), undef), 'ABCD', 'hex only still deflates';
  is $deflate->($G->new(wkt => 'POINT(1 2)', srid => 4326), undef),
    'SRID=4326;POINT(1 2)', 'wkt still deflates to EWKT';
  is $deflate->($G->new(geometry_type => 'POINT', coordinates => [1, 2]), undef),
    'POINT(1 2)', 'coordinates with a type still deflate';
};

# Whichever of the three text forms the database hands back, the inflated
# value answers to_geojson (karr k13). Two of the three forms go through
# the codecs, whose lower-case geometry_type to_geojson used to miss.
subtest 'inflated value answers to_geojson for every form' => sub {
  my $gj = { type => 'Point', coordinates => [13.4, 52.5] };
  my %form = (
    'EWKB hex' => unpack('H*', pack('C V V d< d<', 1, 0x20000001, 4326, 13.4, 52.5)),
    'EWKT'     => 'SRID=4326;POINT(13.4 52.5)',
    'WKT'      => 'POINT(13.4 52.5)',
  );
  for my $name (sort keys %form) {
    my $g = $inflate->($form{$name}, undef);
    isa_ok $g, 'DBIO::PostgreSQL::PostGIS::Geometry', "inflated from $name"
      or next;
    is_deeply $g->to_geojson, $gj, "to_geojson of a value inflated from $name";
  }
};

subtest 'deflate Geometry → EWKT' => sub {
  my $g = DBIO::PostgreSQL::PostGIS::Geometry->point(10, 20, srid => 4326);
  is $deflate->($g, undef), 'SRID=4326;POINT(10 20)';
};

# A value read from the database carries the EWKB hex PostGIS sent, and
# that is what goes back on write -- verbatim, not a WKT rebuilt from the
# decoded coordinates (karr k14). The hex holds every ordinate as the
# double it is; a WKT built in Perl holds its 15-digit stringification
# (0.1 + 0.2 becomes 0.3). Only an object that has no hex is written as
# EWKT.
subtest 'deflate Geometry carrying EWKB hex → that hex, verbatim' => sub {
  my %hex = (
    'point with full double precision' => uc unpack('H*',
      pack('C V V d< d<', 1, 0x20000001, 4326, 0.1 + 0.2, 52.5)),
    'line of three points' => uc unpack('H*',
      pack('C V V V d<6', 1, 0x20000002, 4326, 3, 0, 0, 1, 1, 2, 2)),
    'point M' => uc unpack('H*',
      pack('C V V d<3', 1, 0x60000001, 4326, 1, 2, 9)),
  );
  for my $name (sort keys %hex) {
    my $g = $inflate->($hex{$name}, undef);
    isa_ok $g, 'DBIO::PostgreSQL::PostGIS::Geometry', "inflated $name"
      or next;
    is $deflate->($g, undef), $hex{$name}, "$name deflates to its hex";
  }
};

# A geometry column takes more types than the EWKB decoder decodes: the
# curve types, POLYHEDRALSURFACE, TIN, TRIANGLE (karr k15). Such a value
# used to inflate to undef. To the caller that is SQL NULL -- the row
# looked as if it had no geometry -- and it could not be put right from
# Perl either: the hex was dropped, and $row->geom($other->geom) with it
# wrote NULL. Only NULL may inflate to undef. Every other value inflates
# to an object that carries the hex it came as, and that hex is what the
# deflater writes, so the value is read and written back whole even
# though Perl does not know its coordinates.
#
# coordinates is asked the way t/10-geometry.t asks an object that has
# none: a call that recurses dies at Perl's "Deep recursion" warning
# instead of growing until the memory is gone (karr k20).
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

subtest 'a value that is not decoded inflates to an object carrying its hex' => sub {
  # The first two as a PostGIS server sends them for
  # ST_GeomFromText(<wkt>, 4326).
  my @undecoded = (
    [ 'CIRCULARSTRING(0 0,1 1,2 0)', 'circularstring', 4326,
      '0108000020E61000000300000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000' ],
    [ 'GEOMETRYCOLLECTION(POINT(1 2),CIRCULARSTRING(0 0,1 1,2 0))', 'geometrycollection', 4326,
      '0107000020E6100000020000000101000000000000000000F03F000000000000004001080000000300000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000' ],
    # Not from a database: a point with its second ordinate cut off.
    [ 'a cut-off POINT', 'point', 4326,
      '0101000020E6100000000000000000F03F' ],
  );
  for my $case (@undecoded) {
    my ($name, $type, $srid, $hex) = @$case;
    my $g = $inflate->($hex, undef);
    isa_ok $g, 'DBIO::PostgreSQL::PostGIS::Geometry', "$name inflates, and it"
      or next;
    is $g->ewkb_hex,      $hex,  "$name: carries the hex it came as";
    is $g->srid,          $srid, "$name: srid from the EWKB header";
    is $g->geometry_type, (defined $type ? uc $type : undef), "$name: geometry_type from the EWKB header";
    my $coordinates = $answer->($g, 'coordinates');
    is_deeply $coordinates, { returned => undef },
      "$name: no coordinates -- none were decoded, none are made up"
      or diag explain $coordinates;
    is $deflate->($g, undef), $hex, "$name: deflates to that hex again";
  }
};

subtest 'deflate Geometry without EWKB hex → EWKT, whatever built it' => sub {
  my $G = 'DBIO::PostgreSQL::PostGIS::Geometry';
  my %ewkt = (
    'SRID=4326;LINESTRING(0 0,1 1,2 2)'
      => $G->linestring([[0,0],[1,1],[2,2]], srid => 4326),
    'SRID=4326;POINT(1 2)' => $G->from_wkt('POINT(1 2)', srid => 4326),
    'SRID=3857;POINT(1 2)' => $G->from_ewkt('SRID=3857;POINT(1 2)'),
    'POINT(1 2)'           => $G->from_wkt('POINT(1 2)'),
    'SRID=4326;MULTIPOINT(1 2,3 4)' => $G->from_geojson(
      { type => 'MultiPoint', coordinates => [[1,2],[3,4]] },
    ),
  );
  is $deflate->($ewkt{$_}, undef), $_, $_ for sort keys %ewkt;
};

subtest 'deflate string → passthrough' => sub {
  is $deflate->('SRID=4326;POINT(0 0)', undef), 'SRID=4326;POINT(0 0)';
};

subtest 'undef → undef' => sub {
  is $inflate->(undef, undef), undef;
  is $deflate->(undef, undef), undef;
};

# Opt-out via inflate_geometry => 0
{
  package My::Schema::Result::Opaque;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw( PostgreSQL::PostGIS ));
  __PACKAGE__->table('opaque');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    blob => { data_type => 'geometry', inflate_geometry => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  My::Schema->register_class(Opaque => __PACKAGE__);
}
ok !My::Schema->source('Opaque')->columns_info->{blob}{_inflate_info},
  'inflate_geometry => 0 disables the hook';

# Guard must promote even when user has a custom subclass of DBIO::ResultSet
{
  package My::App::ResultSet;
  use base 'DBIO::ResultSet';

  package My::Schema::Result::Location;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw( PostgreSQL::PostGIS ));
  __PACKAGE__->table('location');
  __PACKAGE__->resultset_class('My::App::ResultSet');   # set BEFORE add_columns
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    geom => { data_type => 'geometry', srid => 4326 },
  );
  __PACKAGE__->set_primary_key('id');
  My::Schema->register_class(Location => __PACKAGE__);
}

my $loc_src = My::Schema->source('Location');
isa_ok $loc_src->resultset_class, 'DBIO::PostgreSQL::PostGIS::ResultSet',
  'custom resultset_class subclass also gets promoted if not already PostGIS';

done_testing;
