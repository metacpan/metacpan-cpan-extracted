use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector#   9:
BEGIN {
    my $key = pack "H32", "09090909090909090909090909090909";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "09090909090909090909090909090909";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("cdecdcfb48d6af61cc3e3fafa9b9bfac", $answer);
};

