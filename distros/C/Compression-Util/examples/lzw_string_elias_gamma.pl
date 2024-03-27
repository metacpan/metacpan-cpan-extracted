#!/usr/bin/perl

# LZWW compressor/decompressor + Elias Gamma coding, for compressing a given string.

use 5.036;
use lib               qw(../lib);
use Compression::Util qw(:all);

local $Compression::Util::VERBOSE = 0;

foreach my $file (__FILE__, $^X) {

    say "Compressing: $file";

    my $str = do {
        local $/;
        open my $fh, '<:raw', $file;
        <$fh>;
    };

    my $enc = lzw_compress($str, undef, \&elias_gamma_encode);
    my $dec = lzw_decompress($enc, undef, \&elias_gamma_decode);

    say "Original size  : ", length($str);
    say "Compressed size: ", length($enc);

    if ($str ne $dec) {
        die "Decompression error";
    }

    say '';
}
