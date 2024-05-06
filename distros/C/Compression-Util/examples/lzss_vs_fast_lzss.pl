#!/usr/bin/perl

# Comparison of LZSS vs Fast-LZSS.

use 5.036;
use lib               qw(../lib);
use Compression::Util qw(:all);

foreach my $file (__FILE__, $^X) {

    my $data = do { open my $fh, '<:raw', $file; local $/; <$fh> };

    my ($u1, $i1, $l1) = lzss_encode($data);
    my ($u2, $i2, $l2) = lzss_encode_fast($data);

    my $str1 = lzss_decode($u1, $i1, $l1);
    my $str2 = lzss_decode($u2, $i2, $l2);

    $str1 eq $data or die "error";
    $str2 eq $data or die "error";

    say "Uncompressed (LZSS vs Fast-LZSS): ", scalar(grep { defined } @$u1), " <=> ", scalar(grep { defined } @$u2);
}
