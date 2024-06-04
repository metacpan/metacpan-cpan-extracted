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

    my $enc = bwt_compress($str, \&create_adaptive_ac_entry);
    my $dec = bwt_decompress($enc, \&decode_adaptive_ac_entry);

    ok(length($enc) < length($str));
    is($str, $dec);
}
