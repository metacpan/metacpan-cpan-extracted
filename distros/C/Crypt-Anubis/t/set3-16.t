use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector#   7:
BEGIN {
    my $key = pack "H32", "07070707070707070707070707070707";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "07070707070707070707070707070707";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("66e83582cefeecb9cd3c46432e550aca", $answer);
};

