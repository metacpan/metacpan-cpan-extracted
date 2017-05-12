use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Directory::Scratch;

use Dir::Self;
use Data::GUID;
use Path::Class qw(file dir);

use File::BaseDir qw(data_files);

my @files = data_files('mime/globs');
unless (@files) {
  plan(skip_all => "Skipping tests, you don't seem to have a mime-info database. The shared-mime-info package is available from http://freedesktop.org/");
} else {
  plan(tests => 20);
}

sub main {
  my $scratch_dir = Directory::Scratch->new;
  my $test_file = $scratch_dir->touch('test1.txt', 'This is test file 1');
  my $root_dir = $scratch_dir->base->subdir('docroot');

  use_ok('Cantella::Store::UUID');

  my $dr;
  is(exception {
    $dr = Cantella::Store::UUID->new(
      root_dir => $root_dir,
      nest_levels => 2,
    );
  }, undef, 'instantiating store');
  isa_ok($dr, 'Cantella::Store::UUID');

  {
    my $uuid = Data::GUID->from_string('A5D45AF2-73D1-11DD-AA18-4B321EADD46B');
    is(
      $dr->_get_dir_for_uuid($uuid)->stringify,
      $root_dir->subdir('A')->subdir('5')->stringify,
      '_get_dir_for_uuid works'
    );
  }

  is(exception { $dr->deploy }, undef, 'deploy successful');

  my $meta = { foo => 'bar' };
  my $check_file;
  my $uuid = $dr->new_uuid;
  my $uuid2 = $dr->new_uuid;
  isa_ok($uuid, 'Data::GUID');

  is(exception {
    $check_file = $dr->create_file($test_file, $uuid, $meta);
    $dr->create_file($test_file, $uuid2, {foo => 'baz'});
  }, undef, 'create_file');

  is($check_file->path->slurp, $test_file->slurp, 'contents survived');
  is_deeply(
    $check_file->metadata,
    {
      foo => 'bar', original_name => 'test1.txt'
    },
  );


  { #test mime-type support;
    my $file_uuid = $dr->new_uuid;
    my $png_file = file(__DIR__,'var/bubble.png');
    {
      my $file = $dr->create_file($png_file, $file_uuid);
      ok(! $file->has_property('mime-type'), 'no mime type');
      is($file->mime_type, 'image/png');
    }
    {
      my $file = $dr->from_uuid($file_uuid);
      ok($file->has_property('mime-type'), 'has mime type');
      is($file->extension, 'png', 'extension works');
      $file->remove;
    }
}


  my @grep_results = $dr->grep_files(sub { shift->metadata->{foo} eq 'baz' });
  is_deeply(\@grep_results, ["${uuid2}"], 'grep_files');

  my @map_results = $dr->map_files(sub { shift->metadata->{foo} });
  is_deeply([sort @map_results], [sort qw/bar baz/], 'map_files');

  ok($check_file->remove, 'removed cleanly');
  ok(! -e $check_file->path, 'file gone');
  ok(! -e $check_file->_meta_file, 'meta file gone');
  ok(  -e $test_file, 'test file not gone');

  ok($scratch_dir->cleanup, 'cleanup correctly');
}

main();
