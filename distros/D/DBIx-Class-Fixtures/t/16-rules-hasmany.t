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
ok($fixtures->dump({ config => 'rules2.json', schema => $schema, directory => $tempdir }), 'quantity dump executed okay');

# check dump is okay
foreach my $test (
  [ 'artist', 1, 'Artist', 'artistid' ],
  [ 'CD', 2, 'CD', 'cdid' ],
) {
  my ($dirname, $count, $moniker, $id) = @$test;
  my $dir = dir(io->catfile($tempdir,$dirname)->name);
  my @children = $dir->children;
  is(scalar(@children), $count, "right number of $dirname fixtures created");

  foreach my $fix_file (@children) {
    my $HASH1; eval($fix_file->slurp());
    is(ref $HASH1, 'HASH', 'fixture evals into hash');
    my $obj = $schema->resultset($moniker)->find($HASH1->{$id});
    is_deeply({$obj->get_columns}, $HASH1, "dumped fixture is equivalent to $dirname row");
  }
}

