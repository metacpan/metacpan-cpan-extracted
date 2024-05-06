#!/usr/bin/perl

# LZSS compressor/decompressor, for compressing a given string.

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

    my $enc = lzss_compress($str, \&create_adaptive_ac_entry);
    my $dec = lzss_decompress($enc, \&decode_adaptive_ac_entry);

    say "Original size  : ", length($str);
    say "Compressed size: ", length($enc);

    if ($str ne $dec) {
        die "Decompression error";
    }

    say '';
}
