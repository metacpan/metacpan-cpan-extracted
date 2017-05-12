#!perl

use DBIx::Class::Fixtures;
use Test::More tests => 11;
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
ok($fixtures->dump({ config => 'fetch.json', schema => $schema, directory => $tempdir }), 'fetch dump executed okay');

# check dump is okay
my $dir = dir(io->catfile($tempdir, qw'artist')->name);
my @children = $dir->children;
is(scalar(@children), 3, 'right number of artist fixtures created');

# check both artists dumped
foreach my $id (1, 2) {
  my $artist_fix_file = dir($dir, $id . '.fix');
  ok(-e $artist_fix_file, "artist $id dumped okay");
}

# check all of artist1's cds were fetched
my $artist1 = $schema->resultset('Artist')->find(1);
my @artist1_cds = $artist1->cds->all;
foreach my $cd (@artist1_cds) {
  my $cd_fix_file = dir($tempdir, 'CD', $cd->id . '.fix');
  ok(-e $cd_fix_file, "artist1's cd rel dumped okay");
}

# check only cds matching artist2's cond were fetched
my $artist2 = $schema->resultset('Artist')->find(2);
my @artist2_cds = $artist2->cds->search({ year => { '>' => 2002 } });
foreach my $cd (@artist2_cds) {
  my $cd_fix_file = dir($tempdir, 'CD', $cd->id . '.fix');
  ok(-e $cd_fix_file, "artist2's cd rel dumped okay");
}

my $cd_dir = dir(io->catfile($tempdir, qw'CD')->name);
@children = $cd_dir->children;
is(scalar(@children), scalar(@artist1_cds) + scalar(@artist2_cds), 'no extra cd fixtures dumped');



