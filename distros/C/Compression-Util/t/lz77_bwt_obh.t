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

    # Compression
    my $enc = do {
        my ($uncompressed, $distances, $lengths, $matches) = lz77_encode($str);
        bwt_compress(symbols2string($uncompressed))
          . fibonacci_encode($lengths)
          . create_huffman_entry($matches)
          . obh_encode($distances, \&mrl_compress_symbolic);
    };

    # Decompression
    my $dec = do {
        open my $fh, '<:raw', \$enc;
        my $uncompressed = string2symbols(bwt_decompress($fh));
        my $lengths      = fibonacci_decode($fh);
        my $matches      = decode_huffman_entry($fh);
        my $distances    = obh_decode($fh, \&mrl_decompress_symbolic);
        lz77_decode($uncompressed, $distances, $lengths, $matches);
    };

    ok(length($enc) < length($str));
    is($str, $dec);
}
