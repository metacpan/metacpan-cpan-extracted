use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Loki97')
};

BEGIN {
    my $key = pack "H32", "000102030405060708090a0b0c0d0e0f";
    my $cipher = new Crypt::Loki97 $key;
    my $plaintext = pack "H32", "000102030405060708090a0b0c0d0e0f";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("f65cf3b53c5c7d3a44e4190cb2057622", $answer);
};

