use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Rabbit')
};

BEGIN {
    my $key = pack "H32", 0;
    my $cipher = new Crypt::Rabbit $key;
    my $ciphertext = pack "H64", "02f74a1c26456bf5ecd6a536f05457b1a78ac689476c697b390c9cc515d8e888";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("0000000000000000000000000000000000000000000000000000000000000000", $answer);
};


