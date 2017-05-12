use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Khazad')
};

BEGIN {
    my $key = pack "H32", "00000000000000000000000000000000";
    my $cipher = new Crypt::Khazad $key;
    my $ciphertext = pack "H16", "a9df3d2c64d3ea28";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("0000000000000001", $answer);
};

