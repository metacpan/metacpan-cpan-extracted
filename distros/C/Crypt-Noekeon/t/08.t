use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Noekeon')
};

BEGIN {
    my $key = pack "H32", "01010101010101010101010101010101";
    my $cipher = new Crypt::Noekeon $key;
    my $plaintext = pack "H32", "01010101010101010101010101010101";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("471f4980b2abaf5a0a4826c6bdea10be", $answer);
};

