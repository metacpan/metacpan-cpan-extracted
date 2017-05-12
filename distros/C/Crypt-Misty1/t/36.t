use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Misty1')
};

BEGIN {
    my $key = pack "H32", "01010101010101010101010101010101";
    my $cipher = new Crypt::Misty1 $key;
    my $plaintext = pack "H16", "0101010101010101";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("571b932d3a5b958c", $answer);
};

