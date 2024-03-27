#!/usr/bin/perl

# Bzip2-like compressor/decompressor, for compressing a given string.

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

    my $enc = bz2_compress($str, undef, \&create_adaptive_ac_entry);
    my $dec = bz2_decompress($enc, undef, \&decode_adaptive_ac_entry);

    say "Original size  : ", length($str);
    say "Compressed size: ", length($enc);

    if ($str ne $dec) {
        die "Decompression error";
    }

    say '';
}
