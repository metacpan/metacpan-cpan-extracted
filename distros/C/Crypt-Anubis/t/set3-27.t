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
    my $ciphertext = pack "H32", "c8baa93bd0d5725f1f67d9e26c3e79ce";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8", $answer);
};

