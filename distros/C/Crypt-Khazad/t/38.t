use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Khazad')
};

BEGIN {
    my $key = pack "H32", "02020202020202020202020202020202";
    my $cipher = new Crypt::Khazad $key;
    my $plaintext = pack "H16", "0202020202020202";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("d5b53e4cf8bba7e4", $answer);
};

