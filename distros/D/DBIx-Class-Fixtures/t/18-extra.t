use DBIx::Class::Fixtures;
use Test::More;
use File::Path 'rmtree';

use lib qw(t/lib);
use ExtraTest::Schema;
use Test::TempDir::Tiny;
use IO::All;

my $tempdir = tempdir;

(my $schema = ExtraTest::Schema->connect(
  'DBI:SQLite::memory:','',''))->init_schema;

open(my $fh, '<', io->catfile(qw't 18-extra.t')->name) ||
  die "Can't open the filehandle, test is trash!";

ok my $row = $schema
  ->resultset('Photo')
  ->create({
    photographer=>'john',
    file=>$fh,
  });

close($fh);

my $fixtures = DBIx::Class::Fixtures
  ->new({
    config_dir => io->catfile(qw't var configs')->name,
    config_attrs => { photo_dir => io->catfile(qw't var files')->name },
    debug => 0 });

ok(
  $fixtures->dump({
    config => 'extra.json',
    schema => $schema,
    directory => io->catfile($tempdir, qw" photos")->name }),
  'fetch dump executed okay');

ok my $key = $schema->resultset('Photo')->first->file;

ok -e $key, 'File Created';

ok $schema->resultset('Photo')->delete;

ok ! -e $key, 'File Deleted';

ok(
  $fixtures->populate({
    no_deploy => 1,
    schema => $schema,
    directory => io->catfile($tempdir, qw" photos")->name}),
  'populated');

is $key, $schema->resultset('Photo')->first->file,
  'key is key';

ok -e $key, 'File Restored';

done_testing;

END {
    rmtree io->catfile(qw't var files')->name;
    rmtree io->catfile($tempdir, qw'photos')->name;
}
