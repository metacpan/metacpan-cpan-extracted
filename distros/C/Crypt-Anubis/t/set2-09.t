use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 2, vector#  3:
BEGIN {
    my $key = pack "H32", "00000000000000000000000000000000";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "708eb676b1dae91caac8bfaaf060f1b9";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("10000000000000000000000000000000", $answer);
};

