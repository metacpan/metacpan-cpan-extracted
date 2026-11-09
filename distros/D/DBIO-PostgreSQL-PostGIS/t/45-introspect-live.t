use strict;
use warnings;
use Test::More;

# Live introspection of PostGIS columns (karr k11, k26, k31).
#
# The annotate phase of DBIO::PostgreSQL::PostGIS::Extension (ADR 0066) gives
# base_type / geometry_type / srid to every geometry and geography column of
# the model, here the model of the driver's own introspector, annotated the way
# a driver applies the triples. It gets them by
# parsing the column's own data_type string -- "public.geometry(Point,4326)"
# with dbio-postgresql's qualified_names (the default there: the type name
# always carries its schema), "geometry(Point,4326)" without it, where
# format_type writes the schema only if it is off the search_path -- and
# from nowhere else: not from the
# geometry_columns / geography_columns views, not from spatial_ref_sys.
#
# That is why the model keeps describing a user's spatial columns when the
# driver leaves the relations an extension owns out of it (dbio-postgresql
# karr k84). Whether those relations are in the model is the driver's
# decision; this test does not look at them, in either direction. What it
# holds on to is the part that must not depend on that decision.
#
# Nothing else samples this against a real database. t/introspect-storage.t
# feeds the parser hand-written column hashes, and t/40-deploy-roundtrip.t
# compares two introspections with each other -- drop the augmentation and
# both sides lose it together, the diff stays empty.
#
# Gated on DBIO_TEST_PG_DSN; skips quietly without a PostGIS-capable DB.

my ($dsn, $user, $pass) =
  @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};
$dsn  //= $ENV{DBIO_TEST_PG_EXT_DSN};
$user //= $ENV{DBIO_TEST_PG_EXT_USER};
$pass //= $ENV{DBIO_TEST_PG_EXT_PASS};

plan skip_all => 'DBIO_TEST_PG_DSN not set' unless $dsn;

eval { require DBI; require DBD::Pg; 1 }
  or plan skip_all => 'DBI / DBD::Pg not available';

use DBIO::PostgreSQL::Introspect;
use DBIO::PostgreSQL::PostGIS::Extension;

# The model of the driver's introspector, with the annotations of the extension
# applied to it: phase 2 of the protocol, as the driver runs it.
sub model_of {
  my (%args) = @_;
  my $model = DBIO::PostgreSQL::Introspect->new(%args)->model;
  my $ctx   = { self => { name => 'postgis',
    schema => ($model->{extensions} // {})->{postgis}{schema_name} } };
  for my $triple (@{ DBIO::PostgreSQL::PostGIS::Extension->annotate($model, $ctx) }) {
    my ($address, $attribute, $value) = @$triple;
    my (undef, $table_key, $column) = @$address;
    my ($col) = grep { $_->{column_name} eq $column } @{ $model->{columns}{$table_key} };
    $col->{$attribute} = $value;
  }
  return $model;
}

my $dbh = eval {
  DBI->connect($dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
};
plan skip_all => "Cannot connect: $@" unless $dbh;

eval { $dbh->do('CREATE EXTENSION IF NOT EXISTS postgis') };
plan skip_all => "PostGIS extension not available: $@" if $@;

my $NS    = 'dbio_postgis_introspect_test';
my $TABLE = 'dbio_postgis_shape';

END {
  if ($dbh) {
    eval { $dbh->do("DROP SCHEMA IF EXISTS $NS CASCADE") };
    eval { $dbh->do("DROP SCHEMA IF EXISTS ${NS}_foreign CASCADE") };
  }
}

$dbh->do("DROP SCHEMA IF EXISTS $NS CASCADE");
$dbh->do("DROP SCHEMA IF EXISTS ${NS}_foreign CASCADE");
$dbh->do("CREATE SCHEMA $NS");
$dbh->do(<<"SQL");
CREATE TABLE $NS.$TABLE (
  id    serial primary key,
  label text,
  pt    public.geometry(Point, 4326),
  area  public.geography(Polygon, 4326),
  blob  public.geometry
)
SQL

# No schema_filter: the whole database, as a generate run sees it. That is
# the case in which the driver's handling of extension-owned relations
# differs, so it is the one the augmentation has to be indifferent to.
my $introspect = DBIO::PostgreSQL::Introspect->new(dbh => $dbh);
my $model      = model_of(dbh => $dbh);

my $columns = $model->{columns}{"$NS.$TABLE"};
is ref $columns, 'ARRAY', "the model carries the columns of $NS.$TABLE"
  or BAIL_OUT('no columns for the test table -- nothing below can be sampled');

my %col = map { $_->{column_name} => $_ } @$columns;

# What the driver in use does with the name of a type. Without the
# qualified_names attribute (dbio-postgresql before its k120) the
# introspecting connection's search_path decides, and the PostGIS schema is
# on it here; with it, the default is the qualified name, always.
my $can_qualify = DBIO::PostgreSQL::Introspect->can('qualified_names') ? 1 : 0;
my $qualified   = $can_qualify && $introspect->qualified_names;
my $pg_schema   = ($model->{extensions} // {})->{postgis}{schema_name};
ok defined $pg_schema, 'the model knows the schema of the postgis extension'
  or BAIL_OUT('no postgis schema in the model -- the qualified name cannot be derived');
my $prefix = $qualified ? "$pg_schema." : '';
note $qualified ? 'qualified_names on: data_type carries its schema'
                : 'no qualified_names: data_type as the search_path leaves it';
is_deeply [ sort keys %col ], [qw( area blob id label pt )],
  '... all five of them, by name';

subtest 'geometry(Point,4326)' => sub {
  my $c = $col{pt};
  is $c->{data_type}, "${prefix}geometry(Point,4326)",
    'data_type carries the modifier -- the string the augmentation parses';
  is $c->{base_type},     'geometry', 'base_type';
  is $c->{geometry_type}, 'point',    'geometry_type';
  is $c->{srid},          4326,       'srid';
};

subtest 'geography(Polygon,4326)' => sub {
  my $c = $col{area};
  is $c->{data_type}, "${prefix}geography(Polygon,4326)",
    'data_type carries the modifier';
  is $c->{base_type},     'geography', 'base_type';
  is $c->{geometry_type}, 'polygon',   'geometry_type';
  is $c->{srid},          4326,        'srid';
};

subtest 'geometry without a modifier' => sub {
  my $c = $col{blob};
  is $c->{data_type}, "${prefix}geometry", 'data_type is the bare type';
  is $c->{base_type}, 'geometry', 'base_type';
  ok !exists $c->{geometry_type}, 'no geometry_type invented';
  ok !exists $c->{srid},          'no srid invented';
};

subtest 'a non-spatial column is left alone' => sub {
  my $c = $col{label};
  is $c->{data_type}, 'text', 'data_type';
  ok !exists $c->{base_type},     'no base_type';
  ok !exists $c->{geometry_type}, 'no geometry_type';
  ok !exists $c->{srid},          'no srid';
};

# karr k12. With the schema that holds the PostGIS types off the
# search_path, format_type() qualifies the type name: the column arrives as
# "public.geometry(Point,4326)". The augmentation anchors its match on the
# bare type name, so it finds nothing and the column goes out unannotated.
#
# A connection of its own, so the search_path above is never touched. The
# data_type assertion stands outside the TODO: it pins the cause, so that
# the block below cannot fail -- or start passing -- for another reason.
subtest 'types off the search_path' => sub {
  my $narrow = DBI->connect($dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
  $narrow->do("SET search_path TO $NS");

  my $narrow_model =
    model_of(dbh => $narrow);
  $narrow->disconnect;

  my ($c) = grep { $_->{column_name} eq 'pt' }
    @{ $narrow_model->{columns}{"$NS.$TABLE"} // [] };
  ok $c, 'the pt column is in the model of the narrowed connection'
    or return;

  like $c->{data_type}, qr/\Apublic\.geometry\(Point,4326\)\z/i,
    'data_type arrives schema-qualified';

  is $c->{base_type},     'geometry', 'base_type';
  is $c->{geometry_type}, 'point',    'geometry_type';
  is $c->{srid},          4326,       'srid';
};

# qualified_names switched off: the name the model carries is the one
# format_type writes against the connection's search_path -- bare here, the
# PostGIS schema being on it. The parser keeps understanding that string for
# as long as the attribute can be switched off.
subtest 'qualified_names off keeps the unqualified name understood' => sub {
  plan skip_all => 'dbio-postgresql has no qualified_names attribute'
    unless $can_qualify;

  my $bare = model_of(
    dbh => $dbh, qualified_names => 0);
  my %b = map { $_->{column_name} => $_ }
    @{ $bare->{columns}{"$NS.$TABLE"} // [] };

  is $b{pt}{data_type}, 'geometry(Point,4326)', 'pt: data_type is unqualified';
  is $b{pt}{base_type},     'geometry', 'pt: base_type';
  is $b{pt}{geometry_type}, 'point',    'pt: geometry_type';
  is $b{pt}{srid},          4326,       'pt: srid';

  is $b{area}{data_type}, 'geography(Polygon,4326)', 'area: data_type is unqualified';
  is $b{area}{base_type},     'geography', 'area: base_type';
  is $b{area}{geometry_type}, 'polygon',   'area: geometry_type';
  is $b{area}{srid},          4326,        'area: srid';
};

# A type named geometry that is not PostGIS's stays unannotated -- qualified
# string (narrow search_path) and bare string (its schema first on the
# search_path) alike.
subtest 'a foreign type named geometry' => sub {
  $dbh->do("CREATE SCHEMA ${NS}_foreign");
  $dbh->do("CREATE DOMAIN ${NS}_foreign.geometry AS text");
  $dbh->do("CREATE TABLE $NS.dbio_postgis_foreign (id int, g ${NS}_foreign.geometry)");

  for my $path ("$NS", "${NS}_foreign, $NS", "$NS, ${NS}_foreign") {
    my $c = DBI->connect($dsn, $user, $pass,
      { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    $c->do("SET search_path TO $path");
    my $m = model_of(dbh => $c);
    $c->disconnect;

    my ($g) = grep { $_->{column_name} eq 'g' }
      @{ $m->{columns}{"$NS.dbio_postgis_foreign"} // [] };
    ok $g, "[$path] the foreign column is in the model" or next;
    is $g->{type_schema}, "${NS}_foreign", "[$path] type_schema is the foreign schema";
    ok !exists $g->{base_type}, "[$path] no base_type";
    ok !exists $g->{srid},      "[$path] no srid";
  }
};

done_testing;
