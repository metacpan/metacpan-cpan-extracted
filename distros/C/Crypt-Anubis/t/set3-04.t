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
    my $plaintext = pack "H32", "01010101010101010101010101010101";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("295bd1f12c803ebcce087049ecdf8c79", $answer);
};

