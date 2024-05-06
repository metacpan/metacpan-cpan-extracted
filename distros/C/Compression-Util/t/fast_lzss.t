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

    my $enc = lzss_compress($str, \&create_huffman_entry, \&lzss_encode_fast);
    my $dec = lzss_decompress($enc);

    ok(length($enc) < length($str));
    is($str, $dec);
}
