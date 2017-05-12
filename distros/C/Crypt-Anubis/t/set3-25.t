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
    my $ciphertext = pack "H32", "2daeed82a8d7a38cad24b186fcae5a2d";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7", $answer);
};

