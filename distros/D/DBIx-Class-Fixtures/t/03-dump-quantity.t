#!perl

use DBIx::Class::Fixtures;
use Test::More tests => 10;
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
ok($fixtures->dump({ config => 'quantity.json', schema => $schema, directory => $tempdir }), 'quantity dump executed okay');

# check dump is okay
my $dir = dir(io->catfile($tempdir, qw'CD')->name);
my @children = $dir->children;
is(scalar(@children), 3, 'right number of cd fixtures created');

foreach my $cd_fix_file (@children) {
  my $HASH1; eval($cd_fix_file->slurp());
  is(ref $HASH1, 'HASH', 'fixture evals into hash');
  my $cd = $schema->resultset('CD')->find($HASH1->{cdid});
  is_deeply({$cd->get_columns}, $HASH1, 'dumped fixture is equivalent to cd row');
}
