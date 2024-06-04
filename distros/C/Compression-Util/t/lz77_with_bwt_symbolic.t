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

    my $enc = lz77_compress($str, \&bwt_compress_symbolic);
    my $dec = lz77_decompress($enc, \&bwt_decompress_symbolic);

    ok(length($enc) < length($str));
    is($str, $dec);
}
