use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Introspect;
use DBIO::PostgreSQL::PostGIS::Storage;
use DBIO::PostgreSQL::PostGIS::Deploy;

# Storage::dbio_deploy_class
is(
  DBIO::PostgreSQL::PostGIS::Storage->dbio_deploy_class,
  'DBIO::PostgreSQL::PostGIS::Deploy',
  'Storage returns correct deploy class',
);

# _augment_geometry_columns — pure data transform, no DB required
my $aug = \&DBIO::PostgreSQL::PostGIS::Introspect::_augment_geometry_columns;

subtest 'geometry(Point,4326)' => sub {
  my $col = { data_type => 'geometry(Point,4326)' };
  $aug->({ 'public.place' => [$col] });
  is $col->{base_type},     'geometry';
  is $col->{geometry_type}, 'point';
  is $col->{srid},          4326;
};

subtest 'geography(Polygon,3857)' => sub {
  my $col = { data_type => 'geography(Polygon,3857)' };
  $aug->({ t => [$col] });
  is $col->{base_type},     'geography';
  is $col->{geometry_type}, 'polygon';
  is $col->{srid},          3857;
};

subtest 'geometry with no subtype or srid' => sub {
  my $col = { data_type => 'geometry' };
  $aug->({ t => [$col] });
  is $col->{base_type}, 'geometry';
  ok !exists $col->{geometry_type}, 'no geometry_type';
  ok !exists $col->{srid},          'no srid';
};

subtest 'geometry(Point) without srid' => sub {
  my $col = { data_type => 'geometry(Point)' };
  $aug->({ t => [$col] });
  is $col->{geometry_type}, 'point';
  ok !exists $col->{srid}, 'no srid when absent';
};

subtest 'non-geometry column untouched' => sub {
  my $col = { data_type => 'text' };
  $aug->({ t => [$col] });
  ok !exists $col->{base_type}, 'text col not touched';
};

subtest 'undef data_type does not crash' => sub {
  my $col = { data_type => undef };
  ok eval { $aug->({ t => [$col] }); 1 }, 'no die on undef data_type';
};

subtest 'empty columns hashref does not crash' => sub {
  ok eval { $aug->({}); 1 }, 'empty hashref OK';
  ok eval { $aug->(undef); 1 }, 'undef OK';
};

done_testing;
