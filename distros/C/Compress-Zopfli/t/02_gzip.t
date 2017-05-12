# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Compress::Zopfli::GZIP') };

use IO::Uncompress::Gunzip qw(gunzip); # RFC 1952

my $input = "The quick\0 brown fox\u0AAA jumps over the lazy dog";
my $compressed = Compress::Zopfli::GZIP::compress($input);
my ($status) = gunzip \$compressed => \my $decompressed;

is($decompressed, $input, "GZIP decompression test");
