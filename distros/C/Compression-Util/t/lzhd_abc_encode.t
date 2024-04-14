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

    my $enc = lzhd_compress($str, undef, \&abc_encode);
    my $dec = lzhd_decompress($enc, undef, \&abc_decode);

    is($str, $dec);
}
