use strict;
use warnings;

use Test::More tests => 2;
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

subtest 'remove list' => sub {
  plan tests => 3;
  
  my $ar = Archive::Ar::Libarchive->new($fn);
  isa_ok $ar, 'Archive::Ar::Libarchive';
  
  my $count = eval { $ar->remove('foo.txt', 'baz.txt') };
  is $count, 2, 'count = 2';
  diag $@ if $@;

  is_deeply scalar $ar->list_files, ['bar.txt'], "just bar";
};

subtest 'remove ref' => sub {
  plan tests => 3;
  
  my $ar = Archive::Ar::Libarchive->new($fn);
  isa_ok $ar, 'Archive::Ar::Libarchive';
  
  my $count = eval { $ar->remove(['foo.txt', 'baz.txt']) };
  is $count, 2, 'count = 2';
  diag $@ if $@;

  is_deeply scalar $ar->list_files, ['bar.txt'], "just bar";
};

__DATA__
!<arch>
foo.txt         1384344423  1000  1000  100644  9         `
hi there

bar.txt         1384344423  1000  1000  100644  31        `
this is the content of bar.txt

baz.txt         1384344423  1000  1000  100644  11        `
and again.

