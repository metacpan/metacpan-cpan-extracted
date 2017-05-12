use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector# 248:
BEGIN {
    my $key = pack "H32", "f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("c8baa93bd0d5725f1f67d9e26c3e79ce", $answer);
};

