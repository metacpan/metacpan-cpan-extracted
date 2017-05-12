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

ok($fixtures->dump({ config => 'scalar_ref.json', schema => $schema, directory => $tempdir }), 'simple dump executed okay');

{
  # check dump is okay
  my $dir = dir(io->catfile($tempdir, qw'artist')->name);
  my @children = $dir->children;
  is(scalar(@children), 1, 'right number of fixtures created');
  
  my $fix_file = $children[0];
  my $HASH1; eval($fix_file->slurp());

  is($HASH1->{name}, 'We Are Goth', 'correct artist dumped');
}

{
  # check dump is okay
  my $dir = dir(io->catfile($tempdir, qw'CD')->name);
  my @children = $dir->children;
  is(scalar(@children), 1, 'right number of fixtures created');
  
  my $fix_file = $children[0];
  my $HASH1; eval($fix_file->slurp());

  like($HASH1->{title}, qr/with us/, 'correct cd dumped');
}


