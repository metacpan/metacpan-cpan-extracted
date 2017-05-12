use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Shark')
};

BEGIN {
    my $key = pack "H32", "000102030405060708090a0b0c0d0e0f";
    my $cipher = new Crypt::Shark $key;
    my $plaintext = pack "H16", "8000000000000000";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("9f09c9765eb336a1", $answer);
};

