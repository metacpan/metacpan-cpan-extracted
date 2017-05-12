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
    my $ciphertext = pack "H32", "5c78e97ecaea5003ec59a9295da3dda9";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("fdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfd", $answer);
};

