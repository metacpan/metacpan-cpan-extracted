use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector# 253:
BEGIN {
    my $key = pack "H32", "fdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfd";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "fdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfd";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("5c78e97ecaea5003ec59a9295da3dda9", $answer);
};

