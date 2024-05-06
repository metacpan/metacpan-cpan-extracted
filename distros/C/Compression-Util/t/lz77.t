#!perl -T

use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests => 4;

foreach my $file (__FILE__) {

    my $str = do {
        local $/;
        open my $fh, '<:raw', $file;
        <$fh>;
    };

    {    # regular
        my $enc = lz77_compress($str);
        my $dec = lz77_decompress($enc);

        ok(length($enc) < length($str));
        is($str, $dec);
    }

    {    # symbolic
        my $enc = lz77_compress_symbolic($str);
        my $dec = lz77_decompress_symbolic($enc);

        ok(length($enc) < length($str));
        is($str, symbols2string($dec));
    }
}
