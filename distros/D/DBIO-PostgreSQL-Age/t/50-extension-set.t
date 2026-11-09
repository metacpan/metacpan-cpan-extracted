use strict;
use warnings;
use Test::More;

use lib 't/lib';
use DBIO::Test::ExtensionSet qw(extension_set_ok extension_set_violations);
use DBIO::Extension::Protocol;
use TestAge::FakeDbh;
use TestAge::MockDeploy;

# ADR 0066 section 2.4 / Example: AGE and PostGIS. The family's canonical
# multi-extension assertion (karr k20; it carries what t/40-stacking.t asserted
# about the deploy chain in karr k12): the result of AGE beside PostGIS does
# not depend on the order, in a fixture with a graph schema that holds a
# geometry column. AGE takes the graph schema out (phase 1), PostGIS annotates
# the geometry column that stays (phase 2); phase 2 sees the model after the
# claims, so nothing is annotated in the graph schema.
#
# PostGIS is a Fake here (an extension class of this test): this distribution
# does not require DBIO::PostgreSQL::PostGIS. The live pair lives in
# t/14-age-chain-live.t.

{
  package T::Fake::PostGIS;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'postgis' }
  sub driver { 'DBIO::PostgreSQL' }

  # srid and geometry type of every geometry(Type,SRID) column of the model
  sub annotate {
    my ($class, $model, $ctx) = @_;
    my @triples;
    for my $table (sort keys %{ $model->{tables} || {} }) {
      my $columns = $model->{tables}{$table}{columns} || {};
      for my $column (sort keys %$columns) {
        next unless ($columns->{$column}{type} // '') =~ /^geometry\((\w+),(\d+)\)$/;
        my $address = [ column => $table, $column ];
        push @triples, [ $address, geometry_type => $1 ], [ $address, srid => $2 ];
      }
    }
    return \@triples;
  }

  sub verdict {
    my ($class, $change, $ctx) = @_;
    return undef unless ($change->{kind} // '') eq 'column_type';
    my ($old, $new) = @{$change}{qw(old_info new_info)};
    return undef unless defined $old->{srid} && defined $new->{srid};
    return { using => "ST_Transform($change->{column_name}, $new->{srid})" }
      if $old->{srid} != $new->{srid};
    return undef;
  }
}

my $AGE = 'DBIO::PostgreSQL::Age::Extension';
my $GIS = 'T::Fake::PostGIS';

my $source = {
  schemas => { public => 1, social => 1 },
  tables  => {
    'public.places' => { columns => { geom => { type => 'geometry(Point,4326)' } } },
    'social.Place'  => { columns => { loc  => { type => 'geometry(Point,4326)' } } },
  },
};
my $target = {
  schemas => { public => 1 },
  tables  => { 'public.places' => { columns => { geom => { type => 'geometry(Point,3857)' } } } },
};
my $dbh = TestAge::FakeDbh->new(graphs => [ { name => 'social', namespace => 'social' } ]);
my @change = ({
  kind => 'column_type', table => 'public.places', column_name => 'geom',
  old_info => { srid => 4326 }, new_info => { srid => 3857 },
});
my %base = (
  driver  => 'TestAge::MockDeploy',
  source  => $source,
  target  => $target,
  dbh     => $dbh,
  changes => \@change,
);

use_ok($AGE);

# --- the commutativity test of core ----------------------------------------

extension_set_ok(%base, extensions => [$AGE], name => 'Age::Extension alone keeps to the protocol');
extension_set_ok(%base, extensions => [ $AGE, $GIS ], name => 'age and postgis commute (declared age, postgis)');
extension_set_ok(%base, extensions => [ $GIS, $AGE ], name => 'age and postgis commute (declared postgis, age)');

# --- the intent: the test is not green because nothing happens --------------

sub extended {
  my (@classes) = @_;
  my $deploy = TestAge::MockDeploy->new;
  my $protocol = DBIO::Extension::Protocol->new(
    entries => [ map { { class => $_, name => $_->name, options => {}, installed => 1 } } @classes ],
    driver  => $deploy->_extension_driver_helpers,
  );
  $protocol->inspect($dbh);
  my @models = $protocol->extend_models($deploy, $source, $target);
  return ($protocol, @models);
}

subtest 'the pair: graph schema gone, geometry column of the application annotated' => sub {
  my ($protocol, $src, $tgt) = extended($AGE, $GIS);

  is_deeply [ sort keys %{ $src->{schemas} } ], ['public'], 'the graph schema is gone';
  ok !exists $src->{tables}{'social.Place'}, '... with its label table and the geometry column in it';
  is $src->{tables}{'public.places'}{columns}{geom}{srid}, 4326,
    'the geometry column of the application keeps its postgis annotation';
  is $src->{tables}{'public.places'}{columns}{geom}{geometry_type}, 'Point', '... all of it';

  my $diff = TestAge::MockDeploy::Diff->new(source => $src, target => $tgt);
  unlike join("\n", @{ $diff->as_sql }), qr/social/, 'nothing of the graph is dropped';

  is_deeply $protocol->verdict($change[0]), { using => 'ST_Transform(geom, 3857)' },
    'the SRID verdict of postgis still works beside age';
  is_deeply $protocol->activation, { load => ['age'], search_path => ['ag_catalog'] },
    'the activation of the list is age\'s'
    or diag explain $protocol->activation;
};

subtest 'without the AGE extension the graph is dropped (the test can fail)' => sub {
  my (undef, $src, $tgt) = extended($GIS);
  is_deeply [ sort keys %{ $src->{schemas} } ], [ 'public', 'social' ], 'the graph schema stays in the model';
  like join("\n", @{ TestAge::MockDeploy::Diff->new(source => $src, target => $tgt)->as_sql }),
    qr/DROP SCHEMA social/, 'and the diff wants to drop it';
};

subtest 'a broken Age::Extension turns the set test red' => sub {
  no warnings qw(redefine once);
  my $n = 0;
  local *DBIO::PostgreSQL::Age::Extension::claims = sub {
    # state between calls: answers differently every time
    return $n++ % 3 ? [] : [ [ schema => 'social' ] ];
  };
  my @v = extension_set_violations(%base, extensions => [ $AGE, $GIS ]);
  ok scalar(@v), 'an extension with state between calls is found out';
};

done_testing;
