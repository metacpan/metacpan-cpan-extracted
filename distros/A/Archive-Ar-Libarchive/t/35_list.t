use strict;
use warnings;

use Test::More tests => 4;
use File::Temp qw( tempdir );
use File::Spec;

use Archive::Ar::Libarchive;

my $dir = tempdir( CLEANUP => 1 );
my $fn  = File::Spec->catfile($dir, 'foo.ar');

note "fn = $fn";

my $content = do {local $/ = undef; <DATA>};
open my $fh, '>', $fn or die "$fn: $!\n";
binmode $fh;
print $fh $content;
close $fh;

my $filenames = [ qw(foo.txt bar.txt baz.txt) ];

subtest 'filename' => sub {
  plan tests => 3;
  
  my $ar = Archive::Ar::Libarchive->new($fn);
  isa_ok $ar, 'Archive::Ar::Libarchive';

  is_deeply scalar $ar->list_files, $filenames, "scalar context";
  is_deeply [$ar->list_files],      $filenames, "list context";
};

subtest 'glob' => sub {
  plan tests => 3;

  open my $fh, '<', $fn;
  my $ar = Archive::Ar::Libarchive->new($fh);
  isa_ok $ar, 'Archive::Ar::Libarchive';

  is_deeply scalar $ar->list_files, $filenames, "scalar context";
  is_deeply [$ar->list_files],      $filenames, "list context";
};

subtest 'memory' => sub {
  plan tests => 4;

  open my $fh, '<', $fn;
  my $data = do { local $/ = undef; <$fh> };
  close $fh;
  
  my $ar = Archive::Ar::Libarchive->new;
  isa_ok $ar, 'Archive::Ar::Libarchive';
  is $ar->read_memory($data), 242, "size matches";

  is_deeply scalar $ar->list_files, $filenames, "scalar context";
  is_deeply [$ar->list_files],      $filenames, "list context";
};

subtest 'rename' => sub {
  plan tests => 6;

  open my $fh, '<', $fn;
  my $data = do { local $/ = undef; <$fh> };
  close $fh;
  
  my $ar = Archive::Ar::Libarchive->new;
  isa_ok $ar, 'Archive::Ar::Libarchive';
  is $ar->read_memory($data), 242, "size matches";

  my $renames = $filenames;
  $renames->[1] = 'goo.txt';
  $ar->rename('bar.txt', 'goo.txt');
  is_deeply scalar $ar->list_files, $filenames, "scalar context";
  is_deeply [$ar->list_files],      $filenames, "list context";

  $renames->[2] = 'zoo.txt';
  $ar->rename('baz.txt', 'zoo.txt');
  is_deeply scalar $ar->list_files, $filenames, "scalar context";
  is_deeply [$ar->list_files],      $filenames, "list context";
};

__DATA__
!<arch>
foo.txt         1384344423  1000  1000  100644  9         `
hi there

bar.txt         1384344423  1000  1000  100644  31        `
this is the content of bar.txt

baz.txt         1384344423  1000  1000  100644  11        `
and again.

