use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector#   6:
BEGIN {
    my $key = pack "H32", "06060606060606060606060606060606";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "06060606060606060606060606060606";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("d35a33352565a32deedf3d5a5e9973d5", $answer);
};

