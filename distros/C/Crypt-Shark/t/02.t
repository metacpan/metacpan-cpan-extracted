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
    my $ciphertext = pack "H16", "f63cf59238507a0b";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("0000000000000000", $answer);
};

