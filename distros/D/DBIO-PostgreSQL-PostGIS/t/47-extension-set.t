use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use DBIO::Extension::Protocol;
use DBIO::Test::ExtensionSet qw(extension_set_ok extension_set_violations);
use DBIO::PostgreSQL::PostGIS::Extension;
use DBIO::PostgreSQL::PostGIS::Topology::Extension;
use MockPgDeploy;

# karr k31, ADR 0066 section 2.4: the commutativity test over the extensions of
# this distribution and a peer. The driver's table of extension classes does not
# exist in the PostgreSQL driver this was built beside, so the driver is a
# PostgreSQL-shaped mock (t/lib/MockPgDeploy.pm) and the peer is a stand-in for
# Apache AGE, which claims the schema of each graph exactly as the real
# extension does.

my $GIS  = 'DBIO::PostgreSQL::PostGIS::Extension';
my $TOPO = 'DBIO::PostgreSQL::PostGIS::Topology::Extension';

{
  package T::AgeLike;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'age' }
  sub driver { 'DBIO::PostgreSQL' }
  sub inspect {
    my ($class, $ctx) = @_;
    return { graphs => [ @{ $ctx->{dbh}{graphs} || [] } ] };
  }
  sub claims {
    my ($class, $model, $ctx) = @_;
    return [ map { [ schema => $_->{namespace} ] } @{ ($ctx->{self}{state} || {})->{graphs} || [] } ];
  }
}

{
  # What inspect reads: topology.topology through the handle, AGE's graphs
  package T::Dbh;
  sub new { my ($c, %a) = @_; bless { %a }, $c }
  sub quote_identifier { qq{"$_[1]"} }
  sub selectrow_array  { my ($s, $sql, undef, $name) = @_; return ($name) }
  sub selectall_arrayref { $_[0]{topologies} }
}

sub place {
  my ($srid, $table_schema) = @_;
  return { column_name => 'geom', data_type => "public.geometry(Point,$srid)", type_schema => 'public' };
}

sub model {
  my ($srid, %extra_schemas) = @_;
  my %schemas = (public => { name => 'public' }, %extra_schemas);
  my (%tables, %columns);
  $tables{'public.places'}  = { schema_name => 'public', table_name => 'places' };
  $columns{'public.places'} = [ { column_name => 'id', data_type => 'integer' }, place($srid) ];
  for my $s (grep { $_ ne 'public' } sort keys %schemas) {
    $tables{"$s.t"}  = { schema_name => $s, table_name => 't' };
    $columns{"$s.t"} = [ { column_name => 'g', data_type => 'public.geometry(Point,4326)', type_schema => 'public' } ];
  }
  return {
    schemas    => \%schemas,
    extensions => { postgis => { name => 'postgis', schema_name => 'public' } },
    tables     => \%tables,
    columns    => \%columns,
  };
}

my %world = (
  driver => 'MockPgDeploy',
  # the graph schema holds a geometry column, as do the topology's tables
  source => model(4326, graph1 => { name => 'graph1' }, city => { name => 'city' }),
  target => model(3857),
  dbh    => T::Dbh->new(
    graphs     => [ { name => 'g', namespace => 'graph1' } ],
    topologies => [ [ city => 4326 ] ],
  ),
  changes => [ {
    kind => 'column_type', table => 'public.places', column_name => 'geom',
    old_info => { data_type => 'public.geometry(Point,4326)', base_type => 'geometry', geometry_type => 'point', srid => 4326 },
    new_info => { data_type => 'public.geometry(Point,3857)', base_type => 'geometry', geometry_type => 'point', srid => 3857 },
  } ],
);

# --- the claim of the test: it is not vacuous -------------------------------
# Run the protocol once and look at what it does, so the commutativity below is
# a statement about something.
{
  my $entries = [ map { { name => $_->name, class => $_, options => {}, installed => 1, schema => 'public' } }
    'T::AgeLike', $GIS, $TOPO ];
  my $deploy   = MockPgDeploy->new;
  my $protocol = DBIO::Extension::Protocol->new(entries => $entries, driver => {});
  $protocol->inspect($world{dbh});
  my ($source, $target) = $protocol->extend_models($deploy, $world{source}, $world{target});

  is_deeply [ sort keys %{ $source->{schemas} } ], ['public'],
    'the graph schema (AGE) and the topology schema are claimed away';
  is_deeply [ sort keys %{ $source->{tables} } ], ['public.places'],
    '... with their tables, and the geometry columns in them';
  my ($geom) = grep { $_->{column_name} eq 'geom' } @{ $source->{columns}{'public.places'} };
  is_deeply [ @{$geom}{qw(base_type geometry_type srid)} ], [ 'geometry', 'point', 4326 ],
    'PostGIS annotates the column that stays, on the source';
  ($geom) = grep { $_->{column_name} eq 'geom' } @{ $target->{columns}{'public.places'} };
  is $geom->{srid}, 3857, 'and on the target';

  is_deeply $protocol->verdict($world{changes}[0]), { using => 'ST_Transform(geom, 3857)' },
    'the verdict of PostGIS reaches the diff through the protocol';
  is_deeply [ MockPgDeploy::Diff->new(source => $source, target => $target, extensions => $protocol)->as_sql ],
    [ 'ALTER TABLE public.places ALTER COLUMN geom TYPE public.geometry(Point,3857) USING ST_Transform(geom, 3857)' ],
    'the diff writes the conversion, and no DROP of the claimed schemas';
}

# --- commutativity ---------------------------------------------------------------
for my $set (
  [ $GIS, 'T::AgeLike' ],
  [ $GIS, $TOPO ],
  [ $GIS, $TOPO, 'T::AgeLike' ],
  [ $GIS ],
  [ $TOPO ],
) {
  my $label = join ' + ', map { $_->name } @$set;
  extension_set_ok(%world, extensions => $set, name => "$label: the orders commute");
}

# --- an alien ordering of the declaration is no input -------------------------------
is_deeply [ extension_set_violations(%world, extensions => [ 'T::AgeLike', $TOPO, $GIS ]) ], [],
  'declared in the other order: the same';

# --- the test turns red for a PostGIS that breaks the protocol ------------------------
{
  package T::Stateful;
  our @ISA = ('DBIO::PostgreSQL::PostGIS::Extension');
  my $n = 0;
  sub annotate { my $r = $_[0]->SUPER::annotate(@_[1, 2]); push @$r, [ [ column => 'public.places', 'id' ], seq => ++$n ]; $r }
}
{
  package T::Mutating;
  our @ISA = ('DBIO::PostgreSQL::PostGIS::Extension');
  sub annotate { $_[1]{columns}{'public.places'}[0]{touched} = 1; $_[0]->SUPER::annotate(@_[1, 2]) }
}
ok scalar(extension_set_violations(%world, extensions => ['T::Stateful', 'T::AgeLike'])),
  'a PostGIS that keeps state between calls turns the test red';
ok scalar(extension_set_violations(%world, extensions => ['T::Mutating', 'T::AgeLike'])),
  'a PostGIS that changes the model it was handed turns the test red';

done_testing;
