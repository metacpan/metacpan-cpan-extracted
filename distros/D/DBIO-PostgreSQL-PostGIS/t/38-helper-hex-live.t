use strict;
use warnings;
use Test::More;

# Live: a geometry read from the database, handed to a spatial resultset
# helper, is the same geometry the server stores (karr k22).
#
# A read object builds its WKT from decoded doubles, 15 significant digits
# per ordinate; 1/3 prints as 0.333333333333333 and is no longer the stored
# double. A helper that binds that WKT compares a rounded copy, so a
# predicate that is true only for the exact value -- a distance of 0 -- is
# false. The helpers bind the EWKB hex the object carries.
#
# Rows are written with plain SQL, so they owe nothing to the code under test.
# Gated on DBIO_TEST_PG_DSN; skips quietly without a PostGIS-capable DB.

my ($dsn, $user, $pass) =
  @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};
$dsn  //= $ENV{DBIO_TEST_PG_EXT_DSN};
$user //= $ENV{DBIO_TEST_PG_EXT_USER};
$pass //= $ENV{DBIO_TEST_PG_EXT_PASS};

plan skip_all => 'DBIO_TEST_PG_DSN not set' unless $dsn;

eval { require DBI; require DBD::Pg; 1 }
  or plan skip_all => 'DBI / DBD::Pg not available';

my $dbh = eval {
  DBI->connect($dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
};
plan skip_all => "Cannot connect: $@" unless $dbh;

eval { $dbh->do('CREATE EXTENSION IF NOT EXISTS postgis') };
plan skip_all => "PostGIS extension not available: $@" if $@;

{
  package My::K22::Schema::Result::Pt;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw( PostgreSQL::PostGIS ));
  __PACKAGE__->table('dbio_postgis_k22_pt');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    geom => { data_type => 'geometry',  srid => 4326 },
    geog => { data_type => 'geography', srid => 4326 },
    raw  => { data_type => 'geometry' },
  );
  __PACKAGE__->set_primary_key('id');

  package My::K22::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Pt => 'My::K22::Schema::Result::Pt');
}

$dbh->do('DROP TABLE IF EXISTS dbio_postgis_k22_pt');
$dbh->do(<<'SQL');
CREATE TABLE dbio_postgis_k22_pt (
  id   serial primary key,
  geom geometry(Point, 4326),
  geog geography(Point, 4326),
  raw  geometry(Point)
)
SQL
# 1/3 and 2/3 are not exact in 15 digits; the second row is far away.
$dbh->do(<<'SQL');
INSERT INTO dbio_postgis_k22_pt (geom, geog, raw) VALUES
  (ST_SetSRID(ST_MakePoint(1.0/3, 2.0/3), 4326),
   ST_SetSRID(ST_MakePoint(1.0/3, 2.0/3), 4326)::geography,
   ST_MakePoint(1.0/3, 2.0/3)),
  (ST_SetSRID(ST_MakePoint(50, 50), 4326),
   ST_SetSRID(ST_MakePoint(50, 50), 4326)::geography,
   ST_MakePoint(50, 50))
SQL

my $schema = My::K22::Schema->connect(sub { $dbh });
my $rs     = $schema->resultset('Pt');
my $row    = $rs->search({}, { order_by => 'id' })->first;
my $self_id = $row->id;

my $g = $row->geom;
ok defined $g->ewkb_hex, 'the read object carries its hex';
my ($exact) = $dbh->selectrow_array(
  'SELECT ST_Equals(geom, ST_GeomFromText(?, 4326)) FROM dbio_postgis_k22_pt WHERE id = ?',
  undef, $g->wkt, $self_id);
ok !$exact, 'precondition: the 15-digit WKT of the object is not the stored geometry';

sub ids { join ',', map { $_->id } sort { $a->id <=> $b->id } $_[0]->all }

is ids(scalar $rs->within_distance(geom => $g, 0)), $self_id,
  'within_distance 0 finds the row the geometry was read from';
is ids(scalar $rs->intersects(geom => $g)), $self_id,
  'intersects finds the row the geometry was read from';
is ids(scalar $rs->contains(geom => $g)), $self_id, 'contains: the point is in itself';
is ids(scalar $rs->within(geom => $g)),   $self_id, 'within: the point is in itself';
is ids(scalar $rs->bbox_intersects(geom => $g)), $self_id, 'bbox_intersects';

my @near = $rs->nearest_to(geom => $g)->all;
is $near[0]->id, $self_id, 'nearest_to puts its own row first';

my @ord = $rs->order_by_distance(geom => $g)->all;
is $ord[0]->id, $self_id, 'order_by_distance puts its own row first';

my @wd = $rs->with_distance(geom => $g)->search({}, { order_by => 'me.id' })->all;
is $wd[0]->get_column('distance') + 0, 0,
  'with_distance of a row to its own geometry is exactly 0';

# geography column with a read geography
{
  my $geog = $row->geog;
  is ids(scalar $rs->within_distance(geog => $geog, 0)), $self_id,
    'within_distance on a geography column with a read geography';
  is ids(scalar $rs->intersects(geog => $geog)), $self_id,
    'intersects on a geography column with a read geography';
  my @gn = $rs->nearest_to(geog => $geog)->all;
  is $gn[0]->id, $self_id, 'nearest_to on a geography column';
}

# hex without SRID flag, column without SRID
{
  my $r = $row->raw;
  is $r->srid, undef, 'no SRID flag, no srid';
  is ids(scalar $rs->within_distance(raw => $r, 0)), $self_id,
    'a hex without SRID works against a column without SRID';
}

$dbh->do('DROP TABLE dbio_postgis_k22_pt');
done_testing;
