use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Extension;
use DBIO::PostgreSQL::PostGIS::Extension;
use DBIO::PostgreSQL::PostGIS::Topology::Extension;

# karr k31, ADR 0066: the two extension classes of this distribution, method by
# method. annotate and verdict of PostGIS have their cases in
# t/annotate-geometry.t and t/42-geometry-using-hook.t; the commutativity beside
# other extensions is t/47-extension-set.t.

my $GIS  = 'DBIO::PostgreSQL::PostGIS::Extension';
my $TOPO = 'DBIO::PostgreSQL::PostGIS::Topology::Extension';

for my $class ($GIS, $TOPO) {
  subtest "$class: identity" => sub {
    isa_ok $class, 'DBIO::Extension';
    lives_ok { DBIO::Extension->check_interface($class) }
      'core accepts the interface version it states';
    is $class->extension_interface, DBIO::Extension->interface_current,
      'it implements the interface version of this core';
    is $class->driver, 'DBIO::PostgreSQL', 'it asserts the PostgreSQL driver';

    # ADR 0032 section 7 / house rules: an extension never determines the driver
    ok !$class->isa('DBIO::Storage::DBI') && !$class->isa('DBIO::PostgreSQL::Storage')
      && !$class->isa('DBIO::Schema'),
      'it inherits no storage, driver component or schema';
    ok !$class->can('storage_type') && !$class->can('connection'),
      'it has no storage_type and no connection() hook to decide a driver with';
  };
}

is $GIS->name,  'postgis',          'PostGIS: the engine\'s name';
is $TOPO->name, 'postgis_topology', 'Topology: the engine\'s name, its own entry';

# --- PostGIS: what it does not answer ---------------------------------------
is $GIS->inspect({}), undef, 'PostGIS: inspect has nothing to read';
is_deeply $GIS->claims({ schemas => { public => {} } }, {}), [],
  'PostGIS: claims nothing (its relations are pg_depend members of the extension)';
is $GIS->activation({}), undef, 'PostGIS: no activation, no LOAD and no search_path';
is $GIS->storage_layer, 'DBIO::PostgreSQL::PostGIS::Storage',
  'PostGIS: names its storage layer';
is $GIS->inflation_component, 'DBIO::PostgreSQL::PostGIS',
  'PostGIS: names the geometry inflation component';
is $TOPO->storage_layer, undef, 'Topology: no runtime layer';
is $TOPO->activation({}), undef, 'Topology: no activation';
is $TOPO->verdict({ kind => 'column_type' }, {}), undef, 'Topology: no verdict';
is_deeply $TOPO->annotate({ columns => {} }, {}), [], 'Topology: annotates nothing';

for my $component ($GIS->inflation_component, $GIS->storage_layer) {
  lives_ok { (my $f = "$component.pm") =~ s{::}{/}g; require $f }
    "$component loads";
}

# --- Topology: a fake handle that answers like the catalog -------------------
{
  package T::Dbh;
  sub new { my ($c, %a) = @_; bless { %a, sql => [] }, $c }
  sub quote_identifier { my ($s, $i) = @_; qq{"$i"} }
  sub selectrow_array {
    my ($s, $sql, undef, @bind) = @_;
    push @{ $s->{sql} }, [ $sql, @bind ];
    return $s->{table} ? ($bind[0]) : (undef);
  }
  sub selectall_arrayref {
    my ($s, $sql) = @_;
    push @{ $s->{sql} }, [ $sql ];
    return $s->{rows};
  }
}

{
  my $dbh = T::Dbh->new(table => 1, rows => [ [ city => 4326 ], [ rural => 25832 ] ]);
  my $state = $TOPO->inspect({ dbh => $dbh, self => { name => 'postgis_topology' } });
  is_deeply $state,
    { topologies => [ { name => 'city', srid => 4326 }, { name => 'rural', srid => 25832 } ] },
    'Topology: inspect reads the topologies of topology.topology';
  is_deeply $dbh->{sql}[0][1], '"topology"."topology"',
    'it probes the table of the extension with to_regclass, in schema topology by default';
  like $dbh->{sql}[1][0], qr/FROM "topology"\."topology" ORDER BY name\z/,
    'and reads it ordered by name';

  my $moved = T::Dbh->new(table => 1, rows => []);
  $TOPO->inspect({ dbh => $moved, self => { schema => 'tp' } });
  is $moved->{sql}[0][1], '"tp"."topology"', 'the schema of the installed extension is used when known';
}
{
  my $dbh = T::Dbh->new(table => 0);
  is $TOPO->inspect({ dbh => $dbh, self => {} }), undef,
    'Topology: no topology.topology (extension not installed): no state';
  is scalar @{ $dbh->{sql} }, 1, '... and no further query';
  is $TOPO->inspect({}), undef, 'no handle, no state';
}

{
  my $ctx = { self => { state => { topologies => [ { name => 'rural', srid => 1 }, { name => 'city', srid => 2 } ] } } };
  is_deeply $TOPO->claims({ schemas => { public => {}, city => {}, rural => {} } }, $ctx),
    [ [ schema => 'rural' ], [ schema => 'city' ] ],
    'Topology: claims the schema of each topology';
  is_deeply $TOPO->claims({}, { self => { state => undef } }), [],
    'Topology: no state, no claims';
  is_deeply $TOPO->claims({}, { self => { state => { topologies => [] } } }), [],
    'Topology: no topologies, no claims';
  is_deeply $TOPO->claims({}, {}), [], 'Topology: no entry, no claims';
}

done_testing;
