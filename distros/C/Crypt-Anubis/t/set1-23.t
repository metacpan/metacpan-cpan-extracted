use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 1, vector#118:
BEGIN {
    my $key = pack "H32", "00000000000000000000000000000200";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "bad29df650ee00c2b7a06c98ae831633";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00000000000000000000000000000000", $answer);
};

