use Test2::V0 -no_srand => 1;
use 5.020;
use Archive::Libarchive::DiskWrite;
use Archive::Libarchive::Entry;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use File::chdir;
use Test::Archive::Libarchive;

subtest 'basic' => sub {

  my $dw = Archive::Libarchive::DiskWrite->new;
  isa_ok $dw, 'Archive::Libarchive::DiskWrite';

};

subtest 'write entry to disk' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  my $dw = Archive::Libarchive::DiskWrite->new;
  my $e = Archive::Libarchive::Entry->new;
  my $path = path("foo.txt");
  my $content = "Hello World!\n";

  $e->set_pathname("$path");
  $e->set_filetype('reg');
  $e->set_size(length $content);
  $e->set_mtime(time,0);
  $e->set_perm(oct('0644'));

  la_ok $dw, write_header => [$e];
  is($dw->write_data(\$content), length $content);
  la_ok $dw, 'finish_entry';
  la_ok $dw, 'close';

  undef $e;
  undef $dw;

  is($path->slurp_utf8, $content);

};

subtest 'write entry to disk with offset' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  my $dw = Archive::Libarchive::DiskWrite->new;
  my $e = Archive::Libarchive::Entry->new;
  my $path = path("foo.bin");
  my $content = "\0\0Hello\0\0World\0\0";

  $e->set_pathname("$path");
  $e->set_filetype('reg');
  $e->set_size(length $content);
  $e->set_mtime(time,0);
  $e->set_perm(oct('0644'));

  la_ok $dw, write_header => [$e];
  la_ok $dw, write_data_block => [\'Hello', 2];
  la_ok $dw, write_data_block => [\'World', 9];

  la_ok $dw, 'finish_entry';
  la_ok $dw, 'close';

  undef $dw;
  undef $e;

  is($path->slurp_utf8, $content);
};

done_testing;
