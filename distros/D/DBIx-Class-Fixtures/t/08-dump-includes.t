#!perl

use DBIx::Class::Fixtures;
use Test::More tests => 7;
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
ok(my $fixtures = DBIx::Class::Fixtures->new({ config_dir => $config_dir, debug => 0 }), 'object created with correct config dir');
ok($fixtures->dump({ config => 'includes.json', schema => $schema, directory => $tempdir }), 'simple dump executed okay');

# check dump is okay
my $producer_dir = dir(io->catfile($tempdir, qw'producer')->name);
ok(-e $producer_dir, 'producer directory created');

my @producer_children = $producer_dir->children;
is(scalar(@producer_children), 1, 'right number of fixtures created');

my $artist_dir = dir(io->catfile($tempdir, qw'artist')->name);
ok(-e $artist_dir, 'artist directory created');

my @artist_children = $artist_dir->children;
is(scalar(@artist_children), 1, 'right number of fixtures created');

