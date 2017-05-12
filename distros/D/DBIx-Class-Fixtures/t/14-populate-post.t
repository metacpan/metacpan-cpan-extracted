#!perl

use DBIx::Class::Fixtures;
use Test::More tests => 5;
use lib qw(t/lib);
use DBICTest;
use Path::Class;
use Data::Dumper;
use Test::TempDir::Tiny;
use IO::All;

my $tempdir = tempdir;

# set up and populate schema
ok(my $schema = DBICTest->init_schema(db_dir => $tempdir), 'got schema');
my $config_dir = io->catfile(qw't var configs')->name;

# do dump
ok(my $fixtures = DBIx::Class::Fixtures->new({ 
      config_dir => $config_dir, 
      debug => 0 }), 
   'object created with correct config dir');

ok($fixtures->dump({ 
      config => "simple.json",
      schema => $schema,
      directory => $tempdir,
   }),
   "simple dump executed okay");

$fixtures->populate({ 
      ddl => io->catfile(qw't lib sqlite.sql')->name,
      connection_details => ['dbi:SQLite:'.io->catfile($tempdir, 'DBIxClass.db')->name, '', ''], 
      directory => $tempdir, 
      post_ddl => io->catfile(qw't lib post_sqlite.sql')->name
});
  
$schema = DBICTest->init_schema(db_dir => $tempdir,no_deploy => 1);

my $producer = $schema->resultset('Producer')->find(999999);
isa_ok($producer, "DBICTest::Producer", "Got post-ddl producer");
is($producer->name, "PostDDL", "Got producer name");

