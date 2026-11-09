use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;
use DBIO::DeploymentHandler;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k131 (e): the connect key 'schema' beside an AccessBroker,
# and DeploymentHandler on such a connection.
#
# CLAIM: the namespace of a connection does not depend on how its connect info
# is given. Whether the details come from a broker that answers connection
# parameters (sync and future_io), from one that answers the DBI form, or from
# the broker's own attribute hash, every connection has the namespace first in
# its search_path and an install over it puts the objects there. And the
# version table of DeploymentHandler is a table of the namespace like any
# other: one per tenant, found along the search_path, part of the restricted
# diff (which stays empty after the install), and an upgrade of one tenant
# leaves the other alone.

my @db  = PrivatePgDatabase->create('t188');
my $dbh = LiveServer->control_dbh(login => [@db]);

{
  package K131E::Result::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('things');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package K131E::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Thing => 'K131E::Result::Thing');
}
{
  package K131E::Versioned;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL',
    '+DBIO::DeploymentHandler::VersionStorage::Standard::Component');
  our $VERSION = '1';
  __PACKAGE__->register_class(Thing => 'K131E::Result::Thing');
}
{
  # A broker that answers the DBI form.
  package K131E::DbiBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, %args) = @_; bless {%args}, $class }
  sub connect_info_for {
    my $self = shift;
    return [ $self->{dsn}, $self->{user}, $self->{pass}, { %{ $self->{attrs} || {} } } ];
  }
}

my ($db_dsn, $db_user, $db_pass) = @db;
my %part = $db_dsn =~ /(\w+)=([^;]+)/g;

sub static_broker {
  DBIO::AccessBroker::Static->new(
    (map { $_ => $part{$_} } grep { defined $part{$_} } qw( host port dbname )),
    username => $db_user, password => $db_pass,
  );
}

sub tables_of {
  my ($namespace) = @_;
  return $dbh->selectcol_arrayref(
    q{SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = ? ORDER BY 1},
    undef, $namespace);
}

sub path_of { scalar $_[0]->storage->dbh->selectrow_array('SHOW search_path') }

sub diff_is_empty {
  my ($schema, $name) = @_;
  my $diff = eval { $schema->pg_deploy->diff };
  ok $diff && !$diff->has_changes, "$name: the diff after the install is empty"
    or diag $@ || $diff->as_sql;
}

# --- the three forms of a broker's answer, sync ----------------------------

{
  my $schema = K131E::Schema->connect(static_broker(), { schema => 'ns_static', PrintWarn => 0 });
  is path_of($schema), 'ns_static, public',
    'broker answering parameters: the namespace is first in the search_path';
  ok eval { $schema->pg_deploy->install; 1 }, '... install runs through' or diag $@;
  is_deeply tables_of('ns_static'), [qw( things )], '... the table is in the namespace';
  diff_is_empty($schema, 'ns_static');
  $schema->storage->disconnect;
}
{
  my $broker = K131E::DbiBroker->new(dsn => $db_dsn, user => $db_user, pass => $db_pass);
  my $schema = K131E::Schema->connect($broker, { schema => 'ns_dbi', PrintWarn => 0 });
  is path_of($schema), 'ns_dbi, public', 'broker answering the DBI form: the namespace is first';
  ok eval { $schema->pg_deploy->install; 1 }, '... install runs through' or diag $@;
  is_deeply tables_of('ns_dbi'), [qw( things )], '... the table is in the namespace';
  diff_is_empty($schema, 'ns_dbi');
  $schema->storage->disconnect;
}
{
  my $broker = K131E::DbiBroker->new(dsn => $db_dsn, user => $db_user, pass => $db_pass,
    attrs => { schema => 'ns_attr', PrintWarn => 0 });
  my $schema = K131E::Schema->connect($broker);
  is path_of($schema), 'ns_attr, public', 'the key in the broker\'s own attributes: the namespace is first';
  ok eval { $schema->pg_deploy->install; 1 }, '... install runs through' or diag $@;
  is_deeply tables_of('ns_attr'), [qw( things )], '... the table is in the namespace';
  $schema->storage->disconnect;

  my $same = K131E::Schema->connect($broker, { schema => 'ns_attr' });
  is path_of($same), 'ns_attr, public', 'the same key beside the broker as well: accepted';
  $same->storage->disconnect;
  ok !eval { K131E::Schema->connect($broker, { schema => 'ns_other' }); 1 },
    'another value beside the broker: refused';
  like $@, qr/'schema'.*different values/s, '... naming the setting';
}
is_deeply tables_of('public'), [], 'public holds no table: nothing of the installs went there';

# --- future_io -------------------------------------------------------------

SKIP: {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    require DBIO::PostgreSQL::Storage::Async;
    1;
  } or skip 'Future::IO::Impl::IOAsync, IO::Async and DBIO::Async are needed for future_io', 5;

  my $schema = K131E::Schema->connect(static_broker(),
    { schema => 'ns_async', async => 'future_io', pool_size => 2, PrintWarn => 0 });
  my $async = $schema->storage->async;
  ok eval { $async->deploy_async($schema)->get; 1 }, 'broker + future_io: deploy_async runs through'
    or diag $@;
  is_deeply tables_of('ns_async'), [qw( things )], '... the table is in the namespace';
  my @rows = map { $_->get } map {
    $async->select_async('pg_namespace', [ \q{current_setting('search_path')} ], { nspname => 'pg_catalog' })
  } 1, 2;
  is_deeply [ map { $_->[0] } @rows ], [ ('ns_async, public') x 2 ],
    '... every pool connection has the namespace first';
  $async->insert_async($schema->source('Thing'), { name => 'x' })->get;
  is scalar $dbh->selectrow_array('SELECT count(*) FROM ns_async.things'), 1,
    '... a row written over the pool is in the namespace';
  is_deeply tables_of('public'), [], '... and public still holds no table';
  $schema->storage->disconnect;
}

# --- DeploymentHandler -----------------------------------------------------

{
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  my %tenant = map {
    $_ => K131E::Versioned->connect(@db, { schema => $_, PrintWarn => 0 })
  } qw( dh_a dh_b );

  ok !$tenant{dh_a}->resultset('__VERSION')->version_storage_is_installed,
    'DeploymentHandler: no version table in a namespace that is not there';

  for my $name (qw( dh_a dh_b )) {
    my $dh = DBIO::DeploymentHandler->new({ schema => $tenant{$name} });
    ok eval { $dh->install; 1 }, "$name: install runs through" or diag $@;
    is_deeply tables_of($name), [qw( dbio_deploymenthandler_versions things )],
      "$name: the table and its own version table are in the namespace";
    is $tenant{$name}->resultset('__VERSION')->database_version, 1, "$name: version 1 is stored";
    diff_is_empty($tenant{$name}, $name);
  }

  # An upgrade of one tenant, with drift in it, leaves the other alone.
  $dbh->do('ALTER TABLE dh_a.things ADD COLUMN stray text');
  $dbh->do('ALTER TABLE dh_b.things ADD COLUMN stray text');
  {
    no warnings 'once';
    local $K131E::Versioned::VERSION = '2';
    my $dh = DBIO::DeploymentHandler->new({ schema => $tenant{dh_a} });
    ok eval { $dh->upgrade({ allow_destructive => 1 }); 1 }, 'dh_a: upgrade to version 2 runs through (it drops the stray column)' or diag $@;
  }
  is $tenant{dh_a}->resultset('__VERSION')->database_version, 2, 'dh_a: version 2 is stored';
  is $tenant{dh_b}->resultset('__VERSION')->database_version, 1, 'dh_b: still at version 1';
  my $stray = sub {
    scalar $dbh->selectrow_array(
      q{SELECT count(*) FROM pg_catalog.pg_attribute
         WHERE attrelid = ?::regclass AND attname = 'stray' AND NOT attisdropped}, undef, "$_[0].things");
  };
  is $stray->('dh_a'), 0, 'dh_a: the upgrade removed its drift';
  is $stray->('dh_b'), 1, 'dh_b: ... and left the drift of the other namespace';

  $_->storage->disconnect for values %tenant;
}

$dbh->disconnect;

done_testing;
