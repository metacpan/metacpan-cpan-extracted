use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Khazad')
};

BEGIN {
    my $key = pack "H32", "fdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfd";
    my $cipher = new Crypt::Khazad $key;
    my $plaintext = pack "H16", "fdfdfdfdfdfdfdfd";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("4ab8bc9c7739d6d0", $answer);
};

