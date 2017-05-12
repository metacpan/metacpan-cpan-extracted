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
    my $ciphertext = pack "H32", "d35a33352565a32deedf3d5a5e9973d5";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("06060606060606060606060606060606", $answer);
};

