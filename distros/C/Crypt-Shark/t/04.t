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
    my $ciphertext = pack "H16", "9f09c9765eb336a1";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("8000000000000000", $answer);
};

