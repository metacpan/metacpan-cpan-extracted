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
    $plaintext = pack "H32", "00000000000000000000000000000000";
    $ciphertext = $cipher->encrypt($plaintext);
    $answer = unpack "H*", $ciphertext;
    is("05f8aafdefb4f5f9c751e5b36c8a37d8", $answer);
}

