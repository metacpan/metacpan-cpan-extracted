#!perl

use DBIx::Class::Fixtures;
use Test::More tests => 4;
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
ok(my $fixtures = DBIx::Class::Fixtures->new({ config_dir => $config_dir }), 'object created with correct config dir');

my $output_dir = dir($tempdir);
$output_dir->mkpath;
my $file = file($output_dir, 'test_file');
my $fh = $file->open('w');
print $fh 'test file';
$fh->close;

ok($fixtures->dump({ config => 'simple.json', schema => $schema, directory => $tempdir }), 'simple dump executed okay');

ok(-e $file, 'file still exists');
