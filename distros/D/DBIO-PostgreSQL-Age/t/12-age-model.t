use strict;
use warnings;
use Test::More;

use lib 't/lib';
use DBIO::Extension;
use DBIO::Extension::Protocol;
use TestAge::FakeDbh;
use TestAge::MockDeploy;

# ADR 0066 of core (karr k20), the offline half of what karr k12 asserted: the
# graph schemas of Apache AGE are known to the deploy and never dropped.
# create_graph's schema, label tables, sequences and _age_cache_invalidate
# trigger have no pg_depend row to the extension, so the driver's member filter
# does not hide them, and an unrestricted diff against a target built in a
# temporary database (which holds no graph) wants to drop all of it.
#
# The mechanism changed: Age::Introspect/Age::Deploy are gone, the extension
# class reads the graphs (inspect) and claims their schemas; the driver removes
# what is claimed. The assertion is the old one: nothing of a graph is dropped.
# The live half is t/13-age-model-live.t.

use_ok('DBIO::PostgreSQL::Age::Extension');
my $AGE = 'DBIO::PostgreSQL::Age::Extension';

# --- the class -------------------------------------------------------------

ok $AGE->isa('DBIO::Extension'), 'derives from DBIO::Extension';
is $AGE->name, 'age', 'names the engine extension';
is $AGE->driver, 'DBIO::PostgreSQL', 'asserts the driver, does not become one';
ok !$AGE->isa('DBIO::PostgreSQL'), '... and inherits no driver component (ADR 0032 section 7)';
ok !$AGE->isa('DBIO::Schema'), '... nor a schema class';
ok eval { DBIO::Extension->check_interface($AGE); 1 }, "the interface version is accepted by core"
  or diag $@;
is $AGE->storage_layer, 'DBIO::PostgreSQL::Age::Storage', 'names its storage layer';
is_deeply $AGE->activation, { load => 'age', search_path => ['ag_catalog'] },
  'activation is data: load age, ag_catalog on the search_path';
is_deeply $AGE->claims({}, {}), [], 'claims nothing without a state';
is $AGE->verdict({ kind => 'column_type' }, {}), undef, 'no column rules';
is_deeply $AGE->annotate({}, {}), [], 'annotates nothing';

# --- inspect ---------------------------------------------------------------

subtest 'inspect reads ag_catalog.ag_graph' => sub {
  my $dbh = TestAge::FakeDbh->new(graphs => [
    { name => 'social', namespace => 'social' },
    { name => 'g2',     namespace => 'g2_schema' },
  ]);
  is_deeply $AGE->inspect({ dbh => $dbh }), { graphs => [
    { name => 'social', namespace => 'social' },
    { name => 'g2',     namespace => 'g2_schema' },
  ] }, 'name and the schema of each graph';
  my ($probe, $read) = $dbh->calls;
  like $probe, qr/to_regclass\('ag_catalog\.ag_graph'\)/, 'probed with to_regclass first';
  like $read, qr/ag_catalog\.ag_graph.*pg_namespace/s, 'then read the graphs';
};

subtest 'extension not installed' => sub {
  my $dbh = TestAge::FakeDbh->new(graphs => undef);
  is_deeply $AGE->inspect({ dbh => $dbh }), { graphs => [] }, 'no graphs';
  is scalar($dbh->calls), 1, 'only the existence probe was asked';
};

# --- claims ----------------------------------------------------------------

is_deeply $AGE->claims({}, { self => { state => { graphs => [
    { name => 'social', namespace => 'social' },
    { name => 'g2',     namespace => 'g2_schema' },
  ] } } }),
  [ [ schema => 'social' ], [ schema => 'g2_schema' ] ],
  'claims the schema of each graph, by its schema name (not the graph name)';

# --- the intent: the diff keeps the graph ----------------------------------

sub source_model {
  return {
    schemas => { public => 1, social => 1 },
    tables  => {
      'public.users'          => { columns => { id => { type => 'integer' } } },
      'social.KNOWS'          => { columns => { id => { type => 'graphid' }, properties => { type => 'agtype' } } },
      'social._ag_label_edge' => { columns => { id => { type => 'graphid' } } },
    },
  };
}
# what a target built in a temporary database looks like: no graph
sub target_model {
  return { schemas => { public => 1 }, tables => { 'public.users' => { columns => { id => { type => 'integer' } } } } };
}

my $dbh = TestAge::FakeDbh->new(graphs => [ { name => 'social', namespace => 'social' } ]);
my $deploy = TestAge::MockDeploy->new;

# Control: without the extension the diff does want to drop the graph. This is
# what makes the assertions below able to fail.
{
  my $diff = TestAge::MockDeploy::Diff->new(source => source_model(), target => target_model());
  like join("\n", @{ $diff->as_sql }), qr/DROP SCHEMA social/,
    'control: without the extension the graph schema is up for dropping';
}

subtest 'with the extension nothing of the graph is dropped' => sub {
  my $protocol = DBIO::Extension::Protocol->new(
    entries => [ { name => 'age', class => $AGE, options => {}, installed => 1 } ],
    driver  => $deploy->_extension_driver_helpers,
  );
  $protocol->inspect($dbh);
  my ($src, $tgt) = $protocol->extend_models($deploy, source_model(), target_model());

  is_deeply [ sort keys %{ $src->{schemas} } ], ['public'], 'the graph schema left the live model';
  is_deeply [ sort keys %{ $src->{tables} } ], ['public.users'], 'with its label tables';
  is_deeply [ sort keys %{ $tgt->{schemas} } ], ['public'], 'the target is untouched';

  my $diff = TestAge::MockDeploy::Diff->new(source => $src, target => $tgt);
  ok !$diff->has_changes, 'no change at all'
    or diag join "\n", @{ $diff->as_sql };
  unlike join("\n", @{ $diff->as_sql }), qr/social|KNOWS|_age_cache_invalidate/,
    'nothing about the graph in the SQL';
};

# --- stubs -----------------------------------------------------------------

use_ok('DBIO::PostgreSQL::Age::Deploy');
use_ok('DBIO::PostgreSQL::Age::Introspect');
for my $stub (qw(DBIO::PostgreSQL::Age::Deploy DBIO::PostgreSQL::Age::Introspect)) {
  no strict 'refs';
  is_deeply [ grep { defined &{"${stub}::$_"} } keys %{"${stub}::"} ], [],
    "$stub defines no subs of its own (stub, ADR 0066 section 4)";
}
ok !DBIO::PostgreSQL::Age::Storage->can('dbio_deploy_class'),
  'the storage layer defines no dbio_deploy_class (it is the driver\'s)'
  if eval { require DBIO::PostgreSQL::Age::Storage; 1 };

done_testing;
