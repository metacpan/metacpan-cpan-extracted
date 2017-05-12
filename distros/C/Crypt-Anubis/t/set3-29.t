use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector# 249:
BEGIN {
    my $key = pack "H32", "f9f9f9f9f9f9f9f9f9f9f9f9f9f9f9f9";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "dca5a31e7772c669ff8a35b865932ede";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("f9f9f9f9f9f9f9f9f9f9f9f9f9f9f9f9", $answer);
};

