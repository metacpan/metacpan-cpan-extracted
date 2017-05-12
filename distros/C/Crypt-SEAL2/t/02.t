use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::SEAL2')
};

BEGIN {
    my $key = pack "H40", "000102030405060708090a0b0c0d0e0f10111213";
    my $cipher = new Crypt::SEAL2 $key;
    my $plaintext = pack "H60", "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("d98acb4a472bbce09c17102661a384f6be3024c625a100fb05b2e6ff4618", $answer);
};


