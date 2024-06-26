#!/usr/bin/perl

# LZ77 + BWT + OBH compressor/decompressor, for compressing a given string.

use 5.036;
use lib               qw(../lib);
use Compression::Util qw(:all);

local $Compression::Util::VERBOSE    = 0;
local $Compression::Util::LZ_MIN_LEN = 7;
local $Compression::Util::LZ_MAX_LEN = ~0;

foreach my $file (__FILE__, $^X) {

    say "Compressing: $file";

    my $str = do {
        local $/;
        open my $fh, '<:raw', $file;
        <$fh>;
    };

    # Compression
    my $enc = do {
        my ($uncompressed, $lengths, $matches, $distances) = lz77_encode($str);
        bwt_compress(symbols2string($uncompressed))
          . fibonacci_encode($lengths)
          . create_huffman_entry($matches)
          . obh_encode($distances, \&mrl_compress_symbolic);
    };

    # Decompression
    my $dec = do {
        open my $fh, '<:raw', \$enc;
        my $uncompressed = string2symbols(bwt_decompress($fh));
        my $lengths      = fibonacci_decode($fh);
        my $matches      = decode_huffman_entry($fh);
        my $distances    = obh_decode($fh, \&mrl_decompress_symbolic);
        lz77_decode($uncompressed, $lengths, $matches, $distances);
    };

    say "Original size  : ", length($str);
    say "Compressed size: ", length($enc);

    if ($str ne $dec) {
        die "Decompression error";
    }

    say '';
}
