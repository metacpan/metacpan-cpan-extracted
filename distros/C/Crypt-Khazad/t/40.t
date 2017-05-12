use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Khazad')
};

BEGIN {
    my $key = pack "H32", "03030303030303030303030303030303";
    my $cipher = new Crypt::Khazad $key;
    my $plaintext = pack "H16", "0303030303030303";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("9bc7395bf39227d9", $answer);
};

