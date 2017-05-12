use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 1, vector#127:
BEGIN {
    my $key = pack "H32", "00000000000000000000000000000001";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "e6141eafebe0593c48e1cdf21bbaa189";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00000000000000000000000000000000", $answer);
};

