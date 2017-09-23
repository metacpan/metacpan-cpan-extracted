use strict;
use warnings;

use DBIx::Class::Fixtures;
use Test::More;
use Test::Fatal;
use File::Path 'rmtree';

use lib qw(t/lib/DBICTest);
use Schema3;
use Test::TempDir::Tiny;
use IO::All;

my $tempdir = tempdir;

(my $schema = Schema3->connect(
  'DBI:SQLite::memory:','',''))->init_schema;

ok my $row = $schema
  ->resultset('Person')
  ->first;

ok $row->get_column('weight_to_height_ratio'),
    'has virtual column';

my $fixtures = DBIx::Class::Fixtures
  ->new({
    config_dir => io->catfile(qw't var configs')->name,
    debug => 0 });

ok(
  $fixtures->dump({
    config => 'virtual-columns.json',
    schema => $schema,
    directory => io->catfile($tempdir, 'people')->name }),
  'fetch dump executed okay');

ok $schema->resultset('Person')->delete;

is exception {
  $fixtures->populate({
    no_deploy => 1,
    schema => $schema,
    directory => io->catfile($tempdir, 'people')->name
  })
}, undef, 'populated';

$row = $schema->resultset('Person')->first;

BAIL_OUT("can't continue without data") unless $row;

ok $row->get_column('weight_to_height_ratio'),
  'still has virtual column';

done_testing;

END {
    rmtree io->catfile(qw't var files')->name;
    rmtree io->catfile($tempdir, 'people')->name;
}
