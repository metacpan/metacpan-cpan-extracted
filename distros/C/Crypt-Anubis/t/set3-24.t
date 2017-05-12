use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector# 247:
BEGIN {
    my $key = pack "H32", "f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("2daeed82a8d7a38cad24b186fcae5a2d", $answer);
};

