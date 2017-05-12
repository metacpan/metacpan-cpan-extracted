# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Compress::Zopfli::ZLIB') };

use IO::Uncompress::Inflate qw(inflate); # RFC 1950

my $input = "The quick\0 brown fox\u0AAA jumps over the lazy dog";
my $compressed = Compress::Zopfli::ZLIB::compress($input);
my ($status) = inflate \$compressed => \my $decompressed;

is($decompressed, $input, "ZLIB decompression test");
