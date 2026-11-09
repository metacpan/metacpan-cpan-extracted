use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::DeploymentHandler;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k149.
#
# CLAIM: an upgrade through DeploymentHandler inside a txn_scope_guard runs
# through and warns nothing. _create_temp_db and _drop_temp_db used to end the
# open transaction themselves (COMMIT, local AutoCommit = 1), which DBI reports
# as "commit ineffective with AutoCommit enabled" once the guard commits; the
# deploy now gets an AutoCommit handle from core and never touches the mode.

my @db = PrivatePgDatabase->create('t194');

{
  package K149::Result::Thing;
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
  package K149::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL',
    '+DBIO::DeploymentHandler::VersionStorage::Standard::Component');
  our $VERSION = '1';
  __PACKAGE__->register_class(Thing => 'K149::Result::Thing');
}

my $schema = K149::Schema->connect(@db, { PrintWarn => 0 });
my $dh     = DBIO::DeploymentHandler->new({ schema => $schema });
ok eval { $dh->install; 1 }, 'install runs through' or diag $@;

$schema->storage->dbh->do('ALTER TABLE things ADD COLUMN stray text');

my @warn;
{
  local $SIG{__WARN__} = sub { push @warn, @_ };
  no warnings 'once';
  local $K149::Schema::VERSION = '2';

  my $ok = eval {
    my $guard = $schema->txn_scope_guard;
    DBIO::DeploymentHandler->new({ schema => $schema })->upgrade({ allow_destructive => 1 });
    $guard->commit;
    1;
  };
  ok $ok, 'upgrade inside a txn_scope_guard runs through' or diag $@;
}

is $schema->resultset('__VERSION')->database_version, 2, '... version 2 is stored';
is_deeply [ grep { /commit ineffective/i } @warn ], [], '... no "commit ineffective" warning'
  or diag @warn;

$schema->storage->disconnect;
done_testing;
