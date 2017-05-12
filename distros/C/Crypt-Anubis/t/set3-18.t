use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector#   8:
BEGIN {
    my $key = pack "H32", "08080808080808080808080808080808";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "08080808080808080808080808080808";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("256c03e938b5532df5c7d3037edc4817", $answer);
};

