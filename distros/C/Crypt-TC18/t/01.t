use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::TC18')
};

BEGIN {
    my $key = pack "H16", "0001020304050607";
    my $cipher = new Crypt::TC18 $key;
    my $plaintext = pack "H32", "000102030405060708090a0b0c0d0e0f";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("479e3a9947168262855b5719a8dbc382", $answer);
};

