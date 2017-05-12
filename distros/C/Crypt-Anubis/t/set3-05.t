use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector#   1:
BEGIN {
    my $key = pack "H32", "01010101010101010101010101010101";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "295bd1f12c803ebcce087049ecdf8c79";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("01010101010101010101010101010101", $answer);
};

