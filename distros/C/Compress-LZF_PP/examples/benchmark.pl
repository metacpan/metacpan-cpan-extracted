#!perl
use strict;
use warnings;
use Compress::LZF;
use Compress::LZF_PP;
use Benchmark qw(cmpthese);

my $string     = 'Hello' x 10;
my $compressed = Compress::LZF::compress($string);

cmpthese(
    -1,
    {   'lzf' => sub {
            my $uncompressed = Compress::LZF::decompress($compressed);
        },
        'lzf_pp' => sub {
            my $uncompressed = Compress::LZF_PP::decompress($compressed);
        },
    }
);
