use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Loki97')
};

BEGIN {
    my $key = pack "H32", "04000000000000000000000000000000";
    my $cipher = new Crypt::Loki97 $key;
    my $ciphertext = pack "H32", "2b13b2d2fafaedab5b0e28e9beffccfb";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00000000000000000000000000000000", $answer);
};

