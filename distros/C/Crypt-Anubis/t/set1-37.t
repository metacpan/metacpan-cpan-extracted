use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 1, vector#125:
BEGIN {
    my $key = pack "H32", "00000000000000000000000000000004";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "6b8b0b2878e66169e18aac25a843c57c";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00000000000000000000000000000000", $answer);
};

