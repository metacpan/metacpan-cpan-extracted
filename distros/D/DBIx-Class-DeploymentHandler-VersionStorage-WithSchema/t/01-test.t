#!perl

use strict;
use warnings;
use v5.020;

use lib 't/lib';
use WithSchemaTest;
use Dad;

use Test::More;
use File::Temp qw/tempdir/;
use Test::Fatal qw(lives_ok dies_ok);

my $dbh = WithSchemaTest::dbh();
my @connection = (sub { $dbh }, { ignore_version => 1 });

SCHEMA1: {
  # Each schema will use a different dir, to represent different modules coming
  # from different places.
  my $sql_dir = tempdir( CLEANUP => 1 );

  use_ok 'ResultClassOne_v1';
  my $s = SchemaClassOne->connect(@connection);
  is $s->schema_version, '1.0', 'schema version is at 1.0';
  ok($s, 'DBICVersion::Schema 1.0 instantiates correctly');
  my $handler = Dad->new({
    script_directory => $sql_dir,
    schema => $s,
    databases => 'SQLite',
    sql_translator_args => { add_drop_table => 0 },
  });

  ok($handler, 'DBIx::Class::DeploymentHandler w/1.0 instantiates correctly');

  my $version = $s->schema_version();
  $handler->prepare_install();

  dies_ok {
    $s->resultset('Foo')->create({
      bar => 'frew',
    })
  } 'schema not deployed';
  $handler->install({ version => '1.0' });
  dies_ok {
    $handler->install;
  } 'cannot install twice';
  lives_ok {
    $s->resultset('Foo')->create({
      bar => 'frew',
    })
  } 'schema is deployed';

  my $rs = $handler->version_storage->version_rs;
  is ($rs->count, 1, "One version installed");
  is ($rs->search({ schema => 'SchemaClassOne' })->count, 1, "Schema was recorded");
}

SCHEMA2: {
  my $sql_dir = tempdir( CLEANUP => 1 );

  use_ok 'ResultClassTwo_v1';
  my $s = SchemaClassTwo->connect(@connection);
  is $s->schema_version, '1.0', 'schema version is at 1.0';
  ok($s, 'DBICVersion::Schema 1.0 instantiates correctly');
  my $handler = Dad->new({
    script_directory => $sql_dir,
    schema => $s,
    databases => 'SQLite',
    sql_translator_args => { add_drop_table => 0 },
  });

  ok($handler, 'DBIx::Class::DeploymentHandler w/1.0 instantiates correctly');

  my $version = $s->schema_version();
  $handler->prepare_install();

  dies_ok {
    $s->resultset('Bar')->create({
      bar => 'frew',
    })
  } 'schema not deployed';

  dies_ok {
    $handler->install({ version => '1.0' });
  } "Can't install again: version table already exists";
  $handler->deploy();
  lives_ok {
    $s->resultset('Bar')->create({
      bar => 'frew',
    })
  } 'schema is deployed';

  my $rs = $handler->version_storage->version_rs;
  is ($rs->count, 2, "Two versions installed");
  is ($rs->search({ schema => 'SchemaClassTwo' })->count, 1, "Schema was recorded");
}

done_testing;
