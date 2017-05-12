use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector#   5:
BEGIN {
    my $key = pack "H32", "05050505050505050505050505050505";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "05050505050505050505050505050505";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("b3836902a3dd98a3fad4bfd3b4d7fb8d", $answer);
};

