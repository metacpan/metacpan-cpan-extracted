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

    my $enc = mrl_compress($str);
    my $dec = mrl_decompress($enc);

    is($str, pack('C*', @$dec));

    my $enc_sym = mrl_compress([reverse unpack('C*', $str)]);
    my $dec_sym = mrl_decompress($enc_sym);

    is(scalar(reverse($str)), pack('C*', @$dec_sym));
}
