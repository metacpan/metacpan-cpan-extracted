use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Extension;
use DBIO::PostgreSQL::PostGIS::Storage;

# karr k31: the geometry metadata of a column is the annotate phase of the
# extension class (ADR 0066), which replaces the PostGIS introspector.

# The layer no longer names a deploy class: dbio_deploy_class has one owner,
# the driver storage.
ok !DBIO::PostgreSQL::PostGIS::Storage->can('dbio_deploy_class'),
  'the storage layer defines no dbio_deploy_class';

# annotate -- pure data transform, no DB required. The helper hands the
# columns-by-table to the extension as a model and writes the triples back onto
# the column hashes, the way a driver applies annotations.
sub aug {
  my ($columns_by_table, $postgis_schema) = @_;
  return unless $columns_by_table;
  my $n = 0;
  my @named;
  for my $cols (values %$columns_by_table) {
    for my $col (@$cols) {
      next if defined $col->{column_name};
      $col->{column_name} = 'c' . ++$n;
      push @named, $col;
    }
  }
  my $model = {
    columns => $columns_by_table,
    ($postgis_schema ? (extensions => { postgis => { schema_name => $postgis_schema } }) : ()),
  };
  my $triples = DBIO::PostgreSQL::PostGIS::Extension->annotate($model, {});
  for my $triple (@$triples) {
    my ($address, $attribute, $value) = @$triple;
    my (undef, $table, $column) = @$address;
    my ($col) = grep { $_->{column_name} eq $column } @{ $columns_by_table->{$table} };
    $col->{$attribute} = $value;
  }
  delete $_->{column_name} for @named;
  return;
}
my $aug = \&aug;

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

# karr k12: schema prefix, type_schema and the schema of the extension
subtest 'schema-qualified type is read (postgis schema given)' => sub {
  my @cases = (
    [ 'public.geometry(Point,4326)',     undef,   'geometry',  'point',   4326 ],
    [ 'public.geography(Polygon,3857)',  'public','geography', 'polygon', 3857 ],
    [ 'public.geometry',                 undef,   'geometry',  undef,     undef ],
    [ '"My Schema".geometry(Point,4326)', undef,  'geometry',  'point',   4326 ],
    [ 'geometry(Point,4326)',            'public','geometry',  'point',   4326 ],
    [ 'geometry(Point,4326)',            undef,   'geometry',  'point',   4326 ],
  );
  for my $c (@cases) {
    my ($dt, $ts, $base, $gt, $srid) = @$c;
    my $schema = $dt =~ /My Schema/ ? 'My Schema' : 'public';
    my $col = { data_type => $dt, (defined $ts ? (type_schema => $ts) : ()) };
    $aug->({ t => [$col] }, $schema);
    is $col->{base_type}, $base, "$dt: base_type";
    is $col->{geometry_type}, $gt, "$dt: geometry_type";
    is $col->{srid}, $srid, "$dt: srid";
  }
};

subtest 'a quoted schema is compared case-sensitively' => sub {
  my $col = { data_type => '"My Schema".geometry(Point,4326)' };
  $aug->({ t => [$col] }, 'my schema');
  ok !exists $col->{base_type}, '"My Schema" is not my schema';

  $col = { data_type => '"My ""Q"" Schema".geometry' };
  $aug->({ t => [$col] }, 'My "Q" Schema');
  is $col->{base_type}, 'geometry', 'doubled quotes unescaped';
};

subtest 'a foreign type named geometry is left alone' => sub {
  for my $col (
    { data_type => 'other.geometry(Point,4326)' },
    { data_type => 'geometry(Point,4326)', type_schema => 'other' },
    { data_type => 'other.geometry', type_schema => 'other' },
  ) {
    $aug->({ t => [$col] }, 'public');
    ok !exists $col->{base_type} && !exists $col->{srid},
      "$col->{data_type} (type_schema " . ($col->{type_schema} // 'none') . ')';
  }
};

subtest 'without the postgis schema, the string decides' => sub {
  my $col = { data_type => 'other.geometry(Point,4326)', type_schema => 'other' };
  $aug->({ t => [$col] });
  is $col->{base_type}, 'geometry', 'qualified type annotated';
  is $col->{srid}, 4326, 'srid';
};

subtest 'text named like geometry is not matched' => sub {
  for my $dt ('public.geometry_columns', 'xgeometry', 'public.text') {
    my $col = { data_type => $dt };
    $aug->({ t => [$col] }, 'public');
    ok !exists $col->{base_type}, $dt;
  }
};

subtest 'undef data_type does not crash' => sub {
  my $col = { data_type => undef };
  ok eval { $aug->({ t => [$col] }); 1 }, 'no die on undef data_type';
};

subtest 'empty columns hashref does not crash' => sub {
  ok eval { $aug->({}); 1 }, 'empty hashref OK';
  ok eval { $aug->(undef); 1 }, 'undef OK';
};

subtest 'the triples: addresses, attributes, and the model is only read' => sub {
  my $model = {
    columns => {
      'public.place' => [
        { column_name => 'id',   data_type => 'integer' },
        { column_name => 'geom', data_type => 'public.geometry(Point,4326)', type_schema => 'public' },
        { column_name => 'any',  data_type => 'public.geography' },
      ],
    },
    extensions => { postgis => { schema_name => 'public' } },
  };
  my $before = do { require Storable; Storable::dclone($model) };
  my $triples = DBIO::PostgreSQL::PostGIS::Extension->annotate($model, {});
  is_deeply $triples, [
    [ [ column => 'public.place', 'geom' ], base_type     => 'geometry' ],
    [ [ column => 'public.place', 'geom' ], geometry_type => 'point'    ],
    [ [ column => 'public.place', 'geom' ], srid          => 4326       ],
    [ [ column => 'public.place', 'any'  ], base_type     => 'geography' ],
  ], 'triples at [column => table_key, column], only for the spatial columns';
  is_deeply $model, $before, 'the model came back unchanged';
};

subtest 'the schema of the PostGIS types: the model first, the entry second' => sub {
  my $columns = sub {
    { 'ns.t' => [ { column_name => 'g', data_type => 'gis.geometry(Point,4326)', type_schema => 'gis' } ] }
  };
  my $E = 'DBIO::PostgreSQL::PostGIS::Extension';

  is scalar @{ $E->annotate({ columns => $columns->() }, { self => { schema => 'gis' } }) }, 3,
    'the schema of the extension entry decides when the model has none';
  is scalar @{ $E->annotate({ columns => $columns->() }, { self => { schema => 'other' } }) }, 0,
    'a type in another schema than the entry\'s is left alone';
  is scalar @{ $E->annotate({ columns => $columns->(),
        extensions => { postgis => { schema_name => 'gis' } } }, { self => { schema => 'other' } }) }, 3,
    'the model\'s own word wins: a temp database may hold the extension elsewhere';
};

done_testing;
