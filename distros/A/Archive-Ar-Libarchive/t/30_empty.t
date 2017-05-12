use strict;
use warnings;

use Test::More tests => 2;

use Archive::Ar::Libarchive;

my $content = do {local $/ = undef; <DATA>};

my $a = Archive::Ar::Libarchive->new();
$a->read_memory($content);
my $d = $a->get_content('zero');
isnt "$d->{size}", '', 'size is not empty string';
is "$d->{size}", "0", 'size is zero';

__DATA__
!<arch>
zero            1394762259  1000  1000  100644  0         `

