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
ok($fixtures->dump({ config => 'multiple-has-many.json', schema => $schema, directory => $tempdir }), 'fetch dump executed okay');

# check dump is okay
my $dir = dir($tempdir);

ok( -e io->catfile($tempdir, qw'producer')->name, "We fetched some producers" );
ok( -e io->catfile($tempdir, qw'cd_to_producer')->name, "We fetched some cd producer xrefs" );
ok( -e io->catfile($tempdir, qw'CD')->name, "We fetched some cds" );
ok( -e io->catfile($tempdir, qw'artist')->name, "We fetched some artists" );

__END__
while ( my ($dirname, $sourcename) = each %dirs ) {
  my $this_dir = dir($dir, $dirname);
}

my $cd_dir = dir($dir, 'cd');
my $track_dir = dir($dir, 'track');

# check only artist1's cds that matched the rule were fetched
my $artist1 = $schema->resultset('Artist')->find(1);
my $artist1_cds = $artist1->cds;
while (my $a1_cd = $artist1_cds->next) {
  my $cd_fix_file = file($cd_dir, $a1_cd->id . '.fix');
  if ($a1_cd->tags->search({ tag => 'Cheesy' })->count) {
    ok(-e $cd_fix_file, 'cd matching rule fetched');
  } else {
    isnt(-e $cd_fix_file, 1, 'cd not matching rule not fetched');
  }
}

# check only cds' tracks that matched the rule were fetched
foreach my $cd_fix_file ($cd_dir->children) {
  my $HASH1; eval($cd_fix_file->slurp());
  is(ref $HASH1, 'HASH', 'cd fixture evals into hash');

  my $cd = $schema->resultset('CD')->find($HASH1->{cdid});
  foreach my $track ($cd->tracks->all) {
    my $track_fix_file = file($track_dir, $track->id . '.fix');
    if ($track->get_column('position') eq 2) {
      is(-e $track_fix_file, 1, 'track matching rule fetched');
    } else {
      isnt(-e $track_fix_file, 1, 'track not matching rule not fetched');
    }
  }
}

