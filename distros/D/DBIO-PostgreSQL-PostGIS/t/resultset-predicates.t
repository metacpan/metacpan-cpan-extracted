use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::ResultSet;

# All 6 simple predicates must exist as methods
for my $name (qw(intersects contains within touches crosses overlaps)) {
  ok(DBIO::PostgreSQL::PostGIS::ResultSet->can($name),
    "$name method exists");
}

# within_distance also exists (separate, takes $dist)
ok(DBIO::PostgreSQL::PostGIS::ResultSet->can('within_distance'),
  'within_distance method exists');

# Custom methods exist
for my $name (qw(bbox_intersects nearest_to order_by_distance with_distance)) {
  ok(DBIO::PostgreSQL::PostGIS::ResultSet->can($name),
    "$name method exists");
}

# What _geom_arg binds for a Geometry object (karr k22): the EWKB hex when
# the object has one, its WKT when it has none.
use DBIO::PostgreSQL::PostGIS::Geometry;
my $G  = 'DBIO::PostgreSQL::PostGIS::Geometry';
my $RS = 'DBIO::PostgreSQL::PostGIS::ResultSet';
my $hex = '0101000020E6100000555555555555D53F555555555555E53F';  # 1/3 2/3, 4326

my $read = $G->from_ewkb_hex($hex);
is_deeply [ $RS->_geom_arg($read) ],
  [ 'ST_SetSRID(?::geometry, ?)', $hex, 4326 ],
  'a read geometry binds its hex, not the WKT built from rounded doubles';

my $nosrid = $G->from_ewkb_hex('0101000000555555555555D53F555555555555E53F');
is_deeply [ $RS->_geom_arg($nosrid) ],
  [ '?::geometry', '0101000000555555555555D53F555555555555E53F' ],
  'a hex without SRID flag binds as it is, no SRID set over it';

is_deeply [ $RS->_geom_arg($G->point(1, 2, srid => 4326)) ],
  [ 'ST_GeomFromText(?, ?)', 'POINT(1 2)', 4326 ],
  'an object without hex binds its WKT and SRID, as before';
is_deeply [ $RS->_geom_arg($G->from_wkt('POINT(1 2)')) ],
  [ 'ST_GeomFromText(?)', 'POINT(1 2)' ],
  'an object without hex and SRID binds its WKT, as before';
is_deeply [ $RS->_geom_arg('SRID=4326;POINT(1 2)') ],
  [ 'ST_GeomFromEWKT(?)', 'SRID=4326;POINT(1 2)' ], 'a string is EWKT';

# A Geometry without a writable form is no argument (karr k23): bound, it
# was NULL and the search found nothing, without a word.
for my $case (
  [ 'srid only'                  => $G->new(srid => 4326),                        qr/no ewkb_hex, wkt or coordinates/i ],
  [ 'coordinates without a type' => $G->new(coordinates => [1, 2], srid => 4326), qr/geometry_type/ ],
) {
  my ($name, $g, $like) = @$case;
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  my @got = eval { $RS->_geom_arg($g) };
  my $err = $@;
  isa_ok $err, 'DBIO::Exception', "$name: _geom_arg throws";
  like "$err", $like, "$name: the message says what is missing";
  is_deeply \@warn, [], "$name: no warning";
  eval { $RS->_spatial_search('ST_Intersects', 'geom', $g) };
  isa_ok $@, 'DBIO::Exception', "$name: a helper built on it throws too";
}

# A column name is an identifier (karr k35): checked against the source's
# columns and written by quote_ident, alias and column each on their own
# (plain lower case stays bare, MixedCase is quoted).
{
  package My::Pred::Result::Place;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::PostGIS');
  __PACKAGE__->table('place');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    geom => { data_type => 'geometry' },
    Geom => { data_type => 'geometry' },
  );
  __PACKAGE__->set_primary_key('id');

  package My::Pred::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Place => 'My::Pred::Result::Place');
}

require DBIO::Test::Storage;
my $schema = My::Pred::Schema->clone;
$schema->storage_type('+DBIO::Test::Storage');
$schema = $schema->connect(sub { });
my $rs = $schema->resultset('Place');

my $pt = 'SRID=4326;POINT(1 2)';
my @helpers = (
  (map { my $n = $_; [ $n => sub { $_[0]->$n($_[1], $pt) } ] }
    qw(intersects contains within touches crosses overlaps)),
  [ within_distance   => sub { $_[0]->within_distance($_[1], $pt, 100) } ],
  [ bbox_intersects   => sub { $_[0]->bbox_intersects($_[1], $pt) } ],
  [ nearest_to        => sub { $_[0]->nearest_to($_[1], $pt, 5) } ],
  [ order_by_distance => sub { $_[0]->order_by_distance($_[1], $pt) } ],
  [ with_distance     => sub { $_[0]->with_distance($_[1], $pt) } ],
);

my %sql = (
  intersects        => [ 'WHERE ( ST_Intersects(me.geom, ST_GeomFromEWKT(?)) )' ],
  contains          => [ 'WHERE ( ST_Contains(me.geom, ST_GeomFromEWKT(?)) )' ],
  within            => [ 'WHERE ( ST_Within(me.geom, ST_GeomFromEWKT(?)) )' ],
  touches           => [ 'WHERE ( ST_Touches(me.geom, ST_GeomFromEWKT(?)) )' ],
  crosses           => [ 'WHERE ( ST_Crosses(me.geom, ST_GeomFromEWKT(?)) )' ],
  overlaps          => [ 'WHERE ( ST_Overlaps(me.geom, ST_GeomFromEWKT(?)) )' ],
  within_distance   => [ 'WHERE ( ST_DWithin(me.geom, ST_GeomFromEWKT(?), ?) )' ],
  bbox_intersects   => [ 'WHERE ( me.geom && ST_GeomFromEWKT(?) )' ],
  nearest_to        => [ 'ORDER BY me.geom <-> ST_GeomFromEWKT(?)' ],
  order_by_distance => [ 'ORDER BY ST_Distance(me.geom, ST_GeomFromEWKT(?))' ],
  with_distance     => [ 'ST_Distance(me.geom, ST_GeomFromEWKT(?))' ],
);

for my $h (@helpers) {
  my ($name, $call) = @$h;

  my $q = ${ $call->($rs, 'geom')->as_query };
  like $q->[0], qr/\Q$sql{$name}[0]\E/, "$name: the column is written as an identifier";

  my $q2 = ${ $call->($rs, 'Geom')->as_query };
  like $q2->[0], qr/\bme\."Geom"/, "$name: a MixedCase column keeps its case, quoted";

  my $bad = 'x) OR 1=1 --';
  my $rs2 = eval { $call->($rs, $bad) };
  my $err = $@;
  isa_ok $err, 'DBIO::Exception', "$name: a name that is no column throws";
  like "$err", qr/\Q$bad\E/, "$name: the message names it";
}

done_testing;
