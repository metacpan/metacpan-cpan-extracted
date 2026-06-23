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
  # Valid 48-char hex: little-endian POINT with SRID=4326 (X=13.4, Y=52.5)
  my $hex = '0101000020E6100000333333333333D33F9A9999999992240';
  my $g = $inflate->($hex, undef);
  isa_ok $g, 'DBIO::PostgreSQL::PostGIS::Geometry';
  is $g->ewkb_hex, $hex;
  is $g->srid, 4326;
};

subtest 'inflate from plain WKT (uses default srid from column_info)' => sub {
  my $g = $inflate->('POINT(1 2)', undef);
  isa_ok $g, 'DBIO::PostgreSQL::PostGIS::Geometry';
  is $g->srid, 4326, 'defaults to column srid';
};

subtest 'deflate Geometry → EWKT' => sub {
  my $g = DBIO::PostgreSQL::PostGIS::Geometry->point(10, 20, srid => 4326);
  is $deflate->($g, undef), 'SRID=4326;POINT(10 20)';
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
