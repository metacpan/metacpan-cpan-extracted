use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Square')
};

BEGIN {
    my $key;
    my $cipher;
    my $plaintext;
    my $ciphertext;
    my $answer;

    $key = pack "H32", "80000000000000000000000000000000";
    $cipher = new Crypt::Square $key;
    $plaintext = pack "H32", "0f1e2d3c4b5a69788796a5b4c3d2e1f0";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("ffd90e8a92a1b025108168714f7923f7", $answer);
}

