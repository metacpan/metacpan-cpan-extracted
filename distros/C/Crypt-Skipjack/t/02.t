use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Skipjack')
};

BEGIN {
    my $key = pack "H20", "00998877665544332211";
    my $cipher = new Crypt::Skipjack $key;
    my $plaintext = pack "H16", "33221100ddccbbaa";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("2587cae27a12d300", $answer);
};

