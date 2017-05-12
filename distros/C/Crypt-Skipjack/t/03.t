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
    my $ciphertext = pack "H16", "2587cae27a12d300";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("33221100ddccbbaa", $answer);
};

