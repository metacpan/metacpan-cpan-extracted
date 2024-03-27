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

    my $enc = lzhd_compress($str, undef, sub ($symbols, $out_fh) { print $out_fh delta_encode($symbols) });
    my $dec = lzhd_decompress($enc, undef, sub ($fh) { delta_decode($fh) });

    is($str, $dec);
}
