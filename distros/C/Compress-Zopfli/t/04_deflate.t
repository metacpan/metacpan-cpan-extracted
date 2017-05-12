# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Compress::Zopfli::Deflate') };

use IO::Uncompress::RawInflate qw(rawinflate); #  # RFC 1951

my $input = "The quick\0 brown fox\u0AAA jumps over the lazy dog";
my $compressed = Compress::Zopfli::Deflate::compress($input);
my ($status) = rawinflate \$compressed => \my $decompressed;

is($decompressed, $input, "Deflate decompression test");
