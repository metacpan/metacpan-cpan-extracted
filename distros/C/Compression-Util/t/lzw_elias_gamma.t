#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests => 1;

foreach my $file (__FILE__) {

    my $str = do {
        local $/;
        open my $fh, '<:raw', $file;
        <$fh>;
    };

    my $enc = lzw_compress($str, \&elias_gamma_encode);
    my $dec = lzw_decompress($enc, \&elias_gamma_decode);

    is($str, $dec);
}
