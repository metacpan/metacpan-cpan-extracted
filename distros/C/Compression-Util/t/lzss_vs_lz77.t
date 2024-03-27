#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests => 2;

foreach my $file (__FILE__) {

    my $data = do { open my $fh, '<:raw', $file; local $/; <$fh> };

    my ($u, $i, $l, $h) = lzss_encode($data);
    my ($u2, $i2, $l2) = lz77_encode($data);

    my $str1 = lz77_decode($u,  $i,  $l);
    my $str2 = lz77_decode($u2, $i2, $l2);

    is($str1, $data);
    is($str2, $data);
}
