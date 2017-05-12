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

my $ar = Archive::Ar::Libarchive->new($fn);

ok $ar->contains_file('foo.txt'), "contains foo.txt";
ok $ar->contains_file('bar.txt'), "contains bar.txt";
ok $ar->contains_file('baz.txt'), "contains baz.txt";
ok !$ar->contains_file('bogus.txt'), "does not contains bogus.txt";

__DATA__
!<arch>
foo.txt         1384344423  1000  1000  100644  9         `
hi there

bar.txt         1384344423  1000  1000  100644  31        `
this is the content of bar.txt

baz.txt         1384344423  1000  1000  100644  11        `
and again.

