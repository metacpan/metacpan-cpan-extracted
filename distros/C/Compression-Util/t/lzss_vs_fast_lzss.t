#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests => 3;

foreach my $file (__FILE__) {

    my $data = do { open my $fh, '<:raw', $file; local $/; <$fh> };

    my ($u1, $i1, $l1) = lzss_encode($data);
    my ($u2, $i2, $l2) = lzss_encode_fast($data);

    my $str1 = lzss_decode($u1, $i1, $l1);
    my $str2 = lzss_decode($u2, $i2, $l2);

    ok(scalar(@$u1) < scalar($u2));

    is($str1, $data);
    is($str2, $data);
}
