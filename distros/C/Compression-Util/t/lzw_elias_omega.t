#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests => 2;

foreach my $file (__FILE__) {

    my $str = do {
        local $/;
        open my $fh, '<:raw', $file;
        <$fh>;
    };

    my $enc = lzw_compress($str, \&elias_omega_encode);
    my $dec = lzw_decompress($enc, \&elias_omega_decode);

    ok(length($enc) < length($str));
    is($str, $dec);
}
