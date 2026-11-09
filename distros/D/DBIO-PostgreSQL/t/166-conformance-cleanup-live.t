use strict;
use warnings;
use Test::More;

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $ENV{DBIO_TEST_PG_DSN};

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use DBIO::PostgreSQL::Test::Conformance;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k138: conformance_cleanup drops only the schemas
# conformance_namespace created in this run, and nothing without that mark.

my $CF = 'DBIO::PostgreSQL::Test::Conformance';
my $foreign = "dbio_cf_foreign_$$";

{
  package CfClean::Result::T;
  use base 'DBIO::Core';
  __PACKAGE__->table('t');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
{
  package CfClean::Result::Q;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_cf_foreign_$$.t");
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
for my $n (qw( Plain Extra Fresh )) {
  no strict 'refs';
  @{"CfClean::${n}::ISA"} = ('DBIO::Schema');
}
CfClean::Plain->register_class(T => 'CfClean::Result::T');
CfClean::Fresh->register_class(T => 'CfClean::Result::T');
CfClean::Extra->register_class(Q => 'CfClean::Result::Q');

my $ctl = LiveServer->control_dbh;
my $has = sub {
  my ($name) = @_;
  my ($there) = $ctl->selectrow_array(
    'SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = ?', undef, $name);
  return $there ? 1 : 0;
};
my $drop = sub { $ctl->do(qq{DROP SCHEMA IF EXISTS "$_" CASCADE}) for @_ };

$drop->($foreign);

# (a) a schema the case declares that is there already survives the refused
# case and a cleanup without a mark
{
  $ctl->do(qq{CREATE SCHEMA "$foreign"});
  my $schema = $CF->conformance_connect('CfClean::Extra');
  my $main = $CF->_namespace_of($schema);
  my $err = eval { $CF->conformance_namespace($schema, undef); 1 } ? '' : "$@";
  like $err, qr/\Q$foreign\E.*in the database already/s,
    'a declared schema that is there refuses the case';
  ok !$has->($main), 'the refused case created no schema of its own';
  $CF->conformance_cleanup($schema, undef, undef);
  ok $has->($foreign), 'the foreign schema survives cleanup without a mark';
  $drop->($foreign, $main);
}

# (b) a main schema that was there before is not the run's to drop
{
  my $schema = $CF->conformance_connect('CfClean::Plain');
  my $main = $CF->_namespace_of($schema);
  $ctl->do(qq{CREATE SCHEMA "$main"});
  $CF->conformance_cleanup($schema, undef, undef);
  ok $has->($main), 'cleanup without a mark drops nothing, not the main schema';
  $drop->($main);

  $schema = $CF->conformance_connect('CfClean::Plain');
  $main = $CF->_namespace_of($schema);
  $ctl->do(qq{CREATE SCHEMA "$main"});
  my $token = $CF->conformance_namespace($schema, undef);
  $CF->conformance_cleanup($schema, undef, $token);
  ok $has->($main), 'a main schema that existed before the run is not dropped by its token';
  $drop->($main);
}

# (c) the normal case: what the run created is dropped
{
  my $schema = $CF->conformance_connect('CfClean::Fresh');
  my $main = $CF->_namespace_of($schema);
  my $token = $CF->conformance_namespace($schema, undef);
  ok $has->($main), 'conformance_namespace creates the main schema';
  $CF->conformance_cleanup($schema, undef, $token);
  ok !$has->($main), 'cleanup drops the schema the run created';

  # extra schemas are created by the install; the mark is made before
  $schema = $CF->conformance_connect('CfClean::Extra');
  $main = $CF->_namespace_of($schema);
  $token = $CF->conformance_namespace($schema, undef);
  $ctl->do(qq{CREATE SCHEMA "$foreign"});
  $CF->conformance_cleanup($schema, undef, $token);
  ok !$has->($main), 'the main schema is dropped';
  ok !$has->($foreign), 'the extra schema the install made is dropped';
}

$drop->($foreign);
done_testing;
