use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Khazad')
};

BEGIN {
    my $key = pack "H32", "01010101010101010101010101010101";
    my $cipher = new Crypt::Khazad $key;
    my $plaintext = pack "H16", "0101010101010101";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("3d666f991262fd70", $answer);
};

