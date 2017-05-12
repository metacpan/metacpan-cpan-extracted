use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Noekeon')
};

BEGIN {
    my $key = pack "H32", "80000000000000000000000000000000";
    my $cipher = new Crypt::Noekeon $key;
    my $plaintext = pack "H32", "00000000000000000000000000000000";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("98fe359a01cd3f66f8d662b746f825d7", $answer);
};

