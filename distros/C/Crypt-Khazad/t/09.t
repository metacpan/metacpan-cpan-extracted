use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Khazad')
};

BEGIN {
    my $key = pack "H32", "10000000000000000000000000000000";
    my $cipher = new Crypt::Khazad $key;
    my $ciphertext = pack "H16", "2c8146e405c2ea36";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("0000000000000000", $answer);
};

