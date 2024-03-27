#!/usr/bin/perl

# Comparison of LZSS vs LZ77.

use 5.036;
use lib               qw(../lib);
use Compression::Util qw(:all);

foreach my $file (__FILE__, $^X) {

    my $data = do { open my $fh, '<:raw', $file; local $/; <$fh> };

    my ($u, $i, $l, $h) = lzss_encode($data);
    my ($u2, $i2, $l2) = lz77_encode($data);

    my $str1 = lz77_decode($u,  $i,  $l);
    my $str2 = lz77_decode($u2, $i2, $l2);

    $str1 eq $data or die "error";
    $str2 eq $data or die "error";

    say "Uncompressed (LZSS vs LZ77): ", scalar(@$u), " <=> ", scalar(@$u2);
}
