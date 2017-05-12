use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Khazad')
};

BEGIN {
    my $key = pack "H32", "00000000000000000000000000000002";
    my $cipher = new Crypt::Khazad $key;
    my $plaintext = pack "H16", "0000000000000000";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("ecc4949d1992491a", $answer);
};

