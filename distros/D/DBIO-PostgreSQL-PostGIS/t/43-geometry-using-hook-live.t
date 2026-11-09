use strict;
use warnings;

use Test::More;
use Test::Exception;

# Live: the diff of a geometry column on a table that HOLDS ROWS (karr k28).
#
# t/41 holds what the diff writes; this file holds what the server does with
# it, which is the point -- the statement of k27 without a USING is accepted
# on an empty table and refused on one with a row. The decision under test
# (maintainer, 2026-10-14):
#
#  * another SRID, same geometry type: the rows are CONVERTED. After the
#    statement ST_SRID is the new one and the coordinates are what
#    ST_Transform computes -- a relabelled row would keep 10 / 50 under 3857,
#    which is a different place; that is what this asserts against.
#  * another geometry type: REFUSED when the statement is written, and the
#    table is untouched.
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

my $dbh = eval {
  DBI->connect($dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1 });
};
plan skip_all => "Cannot connect: $@" unless $dbh;

eval { $dbh->do('CREATE EXTENSION IF NOT EXISTS postgis') };
plan skip_all => "PostGIS extension not available: $@" if $@;

my $NS    = 'dbio_postgis_usinghook_test';
my $TABLE = 'dbio_postgis_place';
my $KEY   = "$NS.$TABLE";

END {
  if ($dbh) {
    local $@;
    eval { $dbh->do("DROP SCHEMA IF EXISTS $NS CASCADE") };
  }
}

$dbh->do("DROP SCHEMA IF EXISTS $NS CASCADE");
$dbh->do("CREATE SCHEMA $NS");

my %GEOM = (
  Installed => 'geometry(Point,4326)',
  OtherType => 'geometry(LineString,4326)',
  OtherSrid => 'geometry(Point,3857)',
);

for my $tag (sort keys %GEOM) {
  eval qq{
    package UsingHookGis::$tag;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
    __PACKAGE__->pg_schemas('$NS');
    __PACKAGE__->pg_search_path('$NS', 'public');
    __PACKAGE__->pg_extensions('postgis');

    package UsingHookGis::${tag}::Result::Place;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::PostGIS');
    __PACKAGE__->table('$KEY');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1 },
      geom => { data_type => '$GEOM{$tag}' },
    );
    __PACKAGE__->set_primary_key('id');

    UsingHookGis::$tag->register_class(Place => 'UsingHookGis::${tag}::Result::Place');
    1;
  } or die $@;
}

my @connected;
sub connected {
  my ($tag) = @_;
  my $schema = "UsingHookGis::$tag"->connect($dsn, $user, $pass, {
    on_connect_do => ["SET search_path TO $NS, public"],
    PrintWarn     => 0,
  });
  push @connected, $schema;
  return $schema;
}

# the column operation of a diff, whatever else (an extension) it holds
sub column_ops {
  my ($diff) = @_;
  return grep { $_->isa('DBIO::PostgreSQL::Diff::Column') } @{ $diff->operations };
}

lives_ok { connected('Installed')->pg_deploy->install } 'install lives';

$dbh->do("INSERT INTO $KEY (geom) VALUES (ST_SetSRID(ST_MakePoint(10, 50), 4326))");
$dbh->do("INSERT INTO $KEY (geom) VALUES (ST_SetSRID(ST_MakePoint(-3.5, 40.25), 4326))");

# the values the conversion has to arrive at, computed by the server itself
my $expect = $dbh->selectall_arrayref(
  "SELECT id, ST_X(ST_Transform(geom, 3857)), ST_Y(ST_Transform(geom, 3857)) FROM $KEY ORDER BY id");
is scalar @$expect, 2, 'two rows to convert';
cmp_ok abs($expect->[0][1] - 10), '>', 1e5,
  'the converted x is not the one that was stored (a relabel would keep it)';

subtest 'another geometry type: refused, the table is untouched' => sub {
  # The extension's verdict is a refusal; at which step the driver raises it --
  # when the diff is built or when its statements are written -- is the
  # driver's. Either way nothing is produced and the message names the column
  # and both types.
  my ($sql, $ok);
  $ok = eval { $sql = connected('OtherType')->pg_deploy->diff->as_sql; 1 };
  ok !$ok, 'the change is refused' or diag $sql;
  like "$@", qr/column \Q$KEY\E\.geom changes from geometry point to geometry linestring/,
    'naming the column and both types';

  is_deeply
    $dbh->selectrow_arrayref("SELECT count(*), min(ST_SRID(geom)), max(ST_SRID(geom)) FROM $KEY"),
    [ 2, 4326, 4326 ],
    'the rows are as they were';
};

subtest 'another SRID: the rows are converted' => sub {
  my $diff;
  lives_ok { $diff = connected('OtherSrid')->pg_deploy->diff } 'diff lives' or return;
  my @ops = column_ops($diff);
  is scalar @ops, 1, 'one column operation';

  my $sql = $ops[0]->as_sql;
  like $sql, qr/ USING ST_Transform\(geom, 3857\);$/, 'the statement carries the USING';
  lives_ok { $dbh->do($sql) } 'the server takes it on a table that holds rows'
    or return;

  my $rows = $dbh->selectall_arrayref(
    "SELECT id, ST_SRID(geom), ST_X(geom), ST_Y(geom) FROM $KEY ORDER BY id");
  is scalar @$rows, 2, 'no row lost';
  for my $i (0, 1) {
    is $rows->[$i][1], 3857, "row $i: the SRID is the new one";
    cmp_ok abs($rows->[$i][2] - $expect->[$i][1]), '<', 1e-6, "row $i: x is the transformed one";
    cmp_ok abs($rows->[$i][3] - $expect->[$i][2]), '<', 1e-6, "row $i: y is the transformed one";
  }

  my $again = connected('OtherSrid')->pg_deploy->diff;
  is scalar(column_ops($again)), 0, 'the diff is empty afterwards';
};

$_->storage->disconnect for @connected;

done_testing;
