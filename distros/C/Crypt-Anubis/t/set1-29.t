use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 1, vector#121:
BEGIN {
    my $key = pack "H32", "00000000000000000000000000000040";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "6aae01cb06fa100506a551d97d7eb662";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00000000000000000000000000000000", $answer);
};

