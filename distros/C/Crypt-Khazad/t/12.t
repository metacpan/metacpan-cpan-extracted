use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Khazad')
};

BEGIN {
    my $key = pack "H32", "00000000000000000000000000000004";
    my $cipher = new Crypt::Khazad $key;
    my $plaintext = pack "H16", "0000000000000000";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("ddbe3c223b1466b0", $answer);
};

