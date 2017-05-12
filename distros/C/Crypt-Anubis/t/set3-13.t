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
    my $ciphertext = pack "H32", "b3836902a3dd98a3fad4bfd3b4d7fb8d";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("05050505050505050505050505050505", $answer);
};

