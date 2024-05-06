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

    my $enc = lz77_compress($str, \&abc_encode);
    my $dec = lz77_decompress($enc, \&abc_decode);

    ok(length($enc) < length($str));
    is($str, $dec);
}
