use strict;
use warnings;

use Test::More;
use Test::Exception;

# Live: what a diff through $schema->pg_deploy says about the geometry type
# and the SRID of a column (karr k27).
#
# pg_deploy hands out the driver's deploy class; the schema declares
# pg_extensions('postgis'), so the driver runs the extension protocol with
# DBIO::PostgreSQL::PostGIS::Extension (ADR 0066, karr k31). Both models of the
# diff are annotated by it, and a geometry column carries base_type /
# geometry_type / srid in them and in the operation of a diff. That is what
# goes missing when the extension is not in the list -- the statement would
# not: it is written from data_type, which the plain introspector reads as
# well. So this file asks for the fields, not only for the statement.
#
# And it holds what such a diff IS: an unchanged column is no operation;
# another geometry type, or another SRID, is one `alter` of the column. The
# SRID change is written as ALTER COLUMN ... TYPE with the type of the target
# and USING ST_Transform; the change of geometry type is refused when the
# statement is written (karr k28, which replaced the first version of this
# file: that one held the statement without a USING, which the server refuses
# on a table that holds rows). t/43-geometry-using-hook-live.t runs both on
# a table that holds rows.
#
# t/40-deploy-roundtrip.t runs the same round-trip on a deploy object it
# builds itself; here the object is the one pg_deploy hands out.
#
# Gated on DBIO_TEST_PG_DSN; skips quietly without a PostGIS-capable DB.

my ($dsn, $user, $pass) =
  @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};
$dsn  //= $ENV{DBIO_TEST_PG_EXT_DSN};
$user //= $ENV{DBIO_TEST_PG_EXT_USER};
$pass //= $ENV{DBIO_TEST_PG_EXT_PASS};

plan skip_all => 'DBIO_TEST_PG_DSN not set' unless $dsn;

# What these files hold is the driver running the extension protocol for a
# declared postgis (ADR 0066): the rules are in this distribution, the running
# is dbio-postgresql's. A driver that has no extension list does not run them.
# (DBIO::PostgreSQL::Extension is the driver's table of extension classes.)
eval { require DBIO::PostgreSQL::Extension; 1 }
  or plan skip_all => 'dbio-postgresql without the extension list (ADR 0066): '
    . 'nothing runs the PostGIS extension class';

eval { require DBI; require DBD::Pg; 1 }
  or plan skip_all => 'DBI / DBD::Pg not available';

my $probe = eval {
  DBI->connect($dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1 });
};
plan skip_all => "Cannot connect: $@" unless $probe;

eval { $probe->do('CREATE EXTENSION IF NOT EXISTS postgis') };
plan skip_all => "PostGIS extension not available: $@" if $@;

my $NS    = 'dbio_postgis_pgdeploy_test';
my $TABLE = 'dbio_postgis_place';
my $KEY   = "$NS.$TABLE";

END {
  if ($probe) {
    my $h = DBI->connect($dsn, $user, $pass,
      { RaiseError => 0, PrintError => 0, PrintWarn => 0 });
    $h->do("DROP SCHEMA IF EXISTS $NS CASCADE") if $h;
  }
}

$probe->do("DROP SCHEMA IF EXISTS $NS CASCADE");
$probe->do("CREATE SCHEMA $NS");
$probe->disconnect;

# One schema class per declaration of the same column of the same table. The
# database is installed from Installed; the others are what a diff compares
# it with.
my %GEOM = (
  Installed => 'geometry(Point,4326)',
  OtherType => 'geometry(LineString,4326)',
  OtherSrid => 'geometry(Point,3857)',
);

for my $tag (sort keys %GEOM) {
  eval qq{
    package PgDeployGis::$tag;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
    __PACKAGE__->pg_schemas('$NS');
    __PACKAGE__->pg_search_path('$NS', 'public');
    # the temporary database of a diff gets its geometry type from here
    __PACKAGE__->pg_extensions('postgis');

    package PgDeployGis::${tag}::Result::Place;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::PostGIS');
    __PACKAGE__->table('$KEY');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1 },
      name => { data_type => 'text' },
      geom => { data_type => '$GEOM{$tag}' },
    );
    __PACKAGE__->set_primary_key('id');

    PgDeployGis::$tag->register_class(Place => 'PgDeployGis::${tag}::Result::Place');
    1;
  } or die $@;
}

my @connected;
sub connected {
  my ($tag) = @_;
  my $schema = "PgDeployGis::$tag"->connect($dsn, $user, $pass, {
    on_connect_do => ["SET search_path TO $NS, public"],
    PrintWarn     => 0,
  });
  push @connected, $schema;
  return $schema;
}

# The operations of a diff that are not about an extension. The deploy is
# restricted to $NS and drops no extension, but the database is shared and
# its postgis may be behind the version the server installs today; an
# extension update is not what this file is about.
sub operations {
  my ($diff) = @_;
  return grep { !$_->isa('DBIO::PostgreSQL::Diff::Extension') } @{ $diff->operations };
}

# The geom column as a model of the diff has it.
sub geom_of {
  my ($model) = @_;
  my ($column) = grep { $_->{column_name} eq 'geom' } @{ $model->{columns}{$KEY} // [] };
  return $column;
}

sub spatial_fields {
  my ($column) = @_;
  return { map { $_ => $column->{$_} } qw( base_type geometry_type srid ) };
}

my $installed = connected('Installed');

my $deploy = $installed->pg_deploy;
isa_ok $deploy, 'DBIO::PostgreSQL::Deploy',
  'the deploy object pg_deploy hands out';

lives_ok { $deploy->install } 'install through pg_deploy lives';

subtest 'unchanged: no operation, and both models know the geometry type and the SRID' => sub {
  my $diff;
  lives_ok { $diff = $installed->pg_deploy->diff } 'diff lives' or return;

  is_deeply [ map { $_->summary } operations($diff) ], [],
    'no operation'
    or diag $diff->as_sql;

  # The three fields come from the annotate phase of
  # DBIO::PostgreSQL::PostGIS::Extension and from nowhere else: without the
  # extension in the list they are not there.
  is_deeply spatial_fields(geom_of($diff->source)),
    { base_type => 'geometry', geometry_type => 'point', srid => 4326 },
    'the model of the database carries base_type, geometry_type and srid';
  is_deeply spatial_fields(geom_of($diff->target)),
    { base_type => 'geometry', geometry_type => 'point', srid => 4326 },
    'the model of the target carries them as well';
};

# One `alter` of the geom column, old_info and new_info as the two models
# have the column, and the one statement the diff writes for it.
sub one_column_alter {
  my ($tag, %want) = @_;

  if ($want{refused}) {
    # The extension's verdict is a refusal; at which step the driver raises it
    # -- when the diff is built or when its statements are written -- is the
    # driver's. Either way no statement is produced and the message names the
    # column and both types.
    my ($sql, $ok);
    $ok = eval { $sql = connected($tag)->pg_deploy->diff->as_sql; 1 };
    ok !$ok, 'the change is refused' or diag $sql;
    like "$@", $want{refused}, 'naming the column and both types';
    return;
  }

  my $diff;
  lives_ok { $diff = connected($tag)->pg_deploy->diff } 'diff lives' or return;
  ok $diff->has_changes, 'the diff has changes';

  my @ops = operations($diff);
  is scalar @ops, 1, 'one operation'
    or diag join "\n", map { $_->summary } @ops;
  my $op = $ops[0] or return;

  isa_ok $op, 'DBIO::PostgreSQL::Diff::Column', 'the operation';
  is_deeply [ $op->action, $op->table_key, $op->column_name ],
    [ 'alter', $KEY, 'geom' ],
    'an alter of the geom column';

  is_deeply spatial_fields($op->old_info),
    { base_type => 'geometry', geometry_type => 'point', srid => 4326 },
    'old_info: the column as the database has it';
  is_deeply spatial_fields($op->new_info), $want{new},
    'new_info: the column as the target has it';
  is $op->new_info->{data_type}, $want{type},
    'new_info: the type the statement is written from';

  my $statement = "ALTER TABLE $KEY ALTER COLUMN geom TYPE $want{type}"
    . " USING $want{using};";
  is $op->as_sql, $statement, 'the statement of the operation';
  like $diff->as_sql, qr/^\Q$statement\E$/m, 'the diff writes it';
  like $diff->summary, qr/~column: \Q$KEY\E\.geom \(\Q$want{type}\E\)/,
    'the summary names the column and its new type';
}

subtest 'another geometry type: refused' => sub {
  one_column_alter('OtherType',
    new  => { base_type => 'geometry', geometry_type => 'linestring', srid => 4326 },
    type => 'public.geometry(LineString,4326)',
    refused => qr/column \Q$KEY\E\.geom changes from geometry point to geometry linestring/,
  );
};

subtest 'another SRID: one ALTER COLUMN ... TYPE ... USING ST_Transform' => sub {
  one_column_alter('OtherSrid',
    new  => { base_type => 'geometry', geometry_type => 'point', srid => 3857 },
    type => 'public.geometry(Point,3857)',
    using => 'ST_Transform(geom, 3857)',
  );
};

$_->storage->disconnect for @connected;

done_testing;
