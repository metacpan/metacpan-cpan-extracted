use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::SEAL2')
};

BEGIN {
    my $key = pack "H40", 0;
    my $cipher = new Crypt::SEAL2 $key;
    my $ciphertext = pack "H60", "c312b1e0c74a02928930e0a271d31aca2b0284a8f1e7b990aae2425684f3";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("000000000000000000000000000000000000000000000000000000000000", $answer);
};

