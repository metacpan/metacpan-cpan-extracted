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
    my $ciphertext = pack "H32", "471f4980b2abaf5a0a4826c6bdea10be";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("01010101010101010101010101010101", $answer);
};

