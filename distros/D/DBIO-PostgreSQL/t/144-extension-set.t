use strict;
use warnings;
use Test::More;

use DBIO::Test::ExtensionSet qw(extension_set_ok extension_set_violations);
use DBIO::PostgreSQL::Deploy;   # the test does not load the driver class it is given

# OFFLINE test: a set of extension classes over DBIO::PostgreSQL::Deploy runs
# through core's commutativity test (ADR 0066, section 2.4).
#
# WHY: the protocol makes the result independent of the order of the
# extensions only as long as each extension keeps to it. The driver is the one
# that applies claims and annotations to its model, so the driver is also what
# the test has to be run over: a way of applying them that depends on order
# would show here and nowhere else.
#
# What this file claims:
#   1. extensions that claim, annotate and give verdicts -- one of them
#      reading its peers -- commute over the PostgreSQL deploy, in every order;
#   2. the claim of one extension takes out the object another one would
#      annotate, in either order (phase 2 reads the model after phase 1);
#   3. the test is not vacuous here: an extension that keeps state between
#      calls, one that answers differently in another position, and one whose
#      annotation clashes with another's are reported.

{
  package T144::Graph;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'graph' }
  sub driver { 'DBIO::PostgreSQL' }
  sub inspect { { graphs => [ { name => 'g', namespace => 'gr' } ] } }
  sub claims {
    my ($class, $model, $ctx) = @_;
    return [ map { $ctx->{driver}{schema}->($_->{namespace}) } @{ $ctx->{self}{state}{graphs} || [] } ];
  }
  sub activation { { load => 'graph', search_path => ['graph_catalog'] } }

  package T144::Spatial;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'spatial' }
  sub driver { 'DBIO::PostgreSQL' }
  sub annotate {
    my ($class, $model, $ctx) = @_;
    my @out;
    for my $table (sort keys %{ $model->{columns} }) {
      for my $column (@{ $model->{columns}{$table} }) {
        next unless ($column->{data_type} // '') =~ /^geometry\((\w+),(\d+)\)$/;
        push @out, [ $ctx->{driver}{column}->($table, $column->{column_name}), geometry_type => $1 ],
                   [ $ctx->{driver}{column}->($table, $column->{column_name}), srid => $2 + 0 ];
      }
    }
    return \@out;
  }
  sub verdict {
    my ($class, $change, $ctx) = @_;
    return undef unless ($change->{kind} // '') eq 'column_type';
    my ($from, $to) = map { $change->{$_}{srid} } qw( old_info new_info );
    return undef unless defined $from && defined $to && $from != $to;
    # yields to a peer that regulates the same column (rule 5 of the ADR)
    return undef if $ctx->{peers}{graph} && $ctx->{peers}{graph}{installed}
      && $change->{table} =~ /^gr\./;
    return { using => "ST_Transform($change->{column_name}, $to)" };
  }
  sub storage_layer { undef }

  package T144::Citext;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'citext' }
  sub driver { 'DBIO::PostgreSQL' }
  sub activation { { search_path => ['public'] } }

  package T144::Stateful;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'stateful' }
  sub driver { 'DBIO::PostgreSQL' }
  my $calls = 0;
  sub claims { $calls++ ? [ [ schema => 'gr' ] ] : [] }

  package T144::Clash;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'clash' }
  sub driver { 'DBIO::PostgreSQL' }
  sub annotate { [ [ [ column => 'app.users', 'geom' ], srid => 1 ] ] }
}

sub model {
  my ($srid) = @_;
  return {
    schemas => { public => {}, gr => {}, app => {} },
    tables  => {
      'gr.v'      => { schema_name => 'gr',  table_name => 'v',     kind => 'r', depends_on => [], depends_on_columns => {}, inherits => [] },
      'app.users' => { schema_name => 'app', table_name => 'users', kind => 'r', depends_on => [], depends_on_columns => {}, inherits => [] },
    },
    columns => {
      'gr.v'      => [ { column_name => 'shape', data_type => "geometry(Point,$srid)" } ],
      'app.users' => [ { column_name => 'id', data_type => 'integer' },
                       { column_name => 'geom', data_type => "geometry(Point,$srid)" } ],
    },
    extensions => {},
  };
}

my %fixture = (
  driver => 'DBIO::PostgreSQL::Deploy',
  source => model(4326),
  target => model(3857),
  dbh    => {},
  changes => [
    { kind => 'column_type', table => 'app.users', column_name => 'geom',
      old_info => { srid => 4326 }, new_info => { srid => 3857 } },
    { kind => 'column_type', table => 'gr.v', column_name => 'shape',
      old_info => { srid => 4326 }, new_info => { srid => 3857 } },
  ],
);

# --- 1 ------------------------------------------------------------------------
extension_set_ok(
  %fixture,
  extensions => [qw( T144::Graph T144::Spatial T144::Citext )],
  name       => 'graph, spatial and citext commute over the PostgreSQL deploy',
);

# --- 2 ------------------------------------------------------------------------
{
  my @v = extension_set_violations(%fixture, extensions => [qw( T144::Graph T144::Spatial )]);
  is_deeply \@v, [], 'graph and spatial commute';

  require DBIO::Extension::Protocol;
  for my $order ([qw( graph spatial )], [qw( spatial graph )]) {
    my $protocol = DBIO::Extension::Protocol->new(
      entries   => [ map { { name => $_->name, class => $_, options => {}, installed => 1 } } qw( T144::Graph T144::Spatial ) ],
      run_order => $order,
      driver    => DBIO::PostgreSQL::Deploy->new->_extension_driver_helpers,
    );
    $protocol->inspect({});
    my ($source) = $protocol->extend_models(DBIO::PostgreSQL::Deploy->new, model(4326), model(3857));
    ok !exists $source->{columns}{'gr.v'}, "[@$order] the claimed schema's table is gone ...";
    is $source->{columns}{'app.users'}[1]{srid}, 4326, "[@$order] ... and the one outside it is annotated";
  }
}

# --- 3 -----------------------------------------------------------------------
{
  my @v = extension_set_violations(%fixture, extensions => [qw( T144::Graph T144::Stateful )]);
  ok scalar @v, 'an extension that keeps state between calls is reported';
  like join("\n", @v), qr/differs from order/, '... as a difference between runs';

  @v = extension_set_violations(%fixture, extensions => [qw( T144::Spatial T144::Clash )]);
  ok scalar @v, 'two extensions that annotate one attribute differently are reported';
  like join("\n", @v), qr/annotate the same object differently/, '... with the protocol\'s message';
}

done_testing;
