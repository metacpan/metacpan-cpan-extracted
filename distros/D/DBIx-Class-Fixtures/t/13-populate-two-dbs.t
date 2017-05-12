#!perl

use DBIx::Class::Fixtures;
use Test::More tests => 7;
use lib qw(t/lib);
use DBICTest;
use Path::Class;
use Data::Dumper;
use DBICTest::Schema2;
use Devel::Confess;
use Test::TempDir::Tiny;
use IO::All;

my $tempdir = tempdir;

# set up and populate normal schema
ok(my $schema = DBICTest->init_schema(db_dir => $tempdir), 'got schema');
my $config_dir = io->catfile(qw't var configs')->name;
my $dbix_class_different = io->catfile($tempdir, qw[ DBIxClassDifferent.db ])->name;
my @different_connection_details = (
    "dbi:SQLite:$dbix_class_different",
    '', 
    ''
)
;
my $schema2 = DBICTest::Schema2->compose_namespace('DBICTest2')
                               ->connect(@different_connection_details);

ok $schema2;

unlink($dbix_class_different) if (-e $dbix_class_different );

DBICTest->deploy_schema($schema2, io->catfile(qw't lib sqlite_different.sql')->name);

# do dump
ok(my $fixtures = DBIx::Class::Fixtures->new({ 
      config_dir => $config_dir, 
      debug => 0
   }), 
   'object created with correct config dir');

ok($fixtures->dump({ 
      config => "simple.json", 
      schema => $schema,
      directory => $tempdir 
    }), 
    "simple dump executed okay");

ok($fixtures->populate({ 
      ddl => io->catfile(qw[t lib sqlite_different.sql])->name,
      connection_details => [@different_connection_details], 
      directory => $tempdir
    }),
    'mysql populate okay');

ok($fixtures->populate({ 
      ddl => io->catfile(qw[ t lib sqlite.sql ])->name,
      connection_details => ['dbi:SQLite:'.io->catfile($tempdir, qw[ DBIxClass.db ])->name, '', ''],
      directory => $tempdir
    }), 
    'sqlite populate okay');

$schema = DBICTest->init_schema(db_dir => $tempdir,no_deploy => 1);
is($schema->resultset('Artist')->count, 1, 'artist imported to sqlite okay');
