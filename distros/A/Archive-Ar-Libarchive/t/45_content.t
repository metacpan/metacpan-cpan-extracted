use strict;
use warnings;

use Test::More tests => 13;
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
isa_ok $ar, 'Archive::Ar::Libarchive';
is $ar->get_content("foo.txt")->{data}, "hi there\n", 'get content 1';
is $ar->get_content("bar.txt")->{data}, "this is the content of bar.txt\n",
                                                      'get content 2';
is $ar->get_content("baz.txt")->{data}, "and again.\n", 'get content 3';

is $ar->get_data("foo.txt"), "hi there\n", 'get data 1';
is $ar->get_data("bar.txt"), "this is the content of bar.txt\n", 'get data 2';
is $ar->get_data("baz.txt"), "and again.\n", 'get data 3';

my $h = $ar->get_handle("foo.txt");
diag $ar->error() unless $h;
ok defined fileno($h) || $h->can('read'), 'get handle 1';
my $data = do {local $/ = undef; <$h>};
is $data, "hi there\n", 'handle data 1';

$h = $ar->get_handle("bar.txt");
diag $ar->error() unless $h;
ok defined fileno($h) || $h->can('read'), 'get handle 2';
$data = do {local $/ = undef; <$h>};
is $data, "this is the content of bar.txt\n", 'handle data 2';

$h = $ar->get_handle("baz.txt");
diag $ar->error() unless $h;
ok defined fileno($h) || $h->can('read'), 'get handle 3';
$data = do {local $/ = undef; <$h>};
is $data, "and again.\n", 'handle data 3';


__DATA__
!<arch>
foo.txt         1384344423  1000  1000  100644  9         `
hi there

bar.txt         1384344423  1000  1000  100644  31        `
this is the content of bar.txt

baz.txt         1384344423  1000  1000  100644  11        `
and again.

