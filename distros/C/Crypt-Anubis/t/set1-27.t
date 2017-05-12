use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 1, vector#120:
BEGIN {
    my $key = pack "H32", "00000000000000000000000000000080";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "bc31e0433c180b47c4b0e423446e41f6";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00000000000000000000000000000000", $answer);
};

