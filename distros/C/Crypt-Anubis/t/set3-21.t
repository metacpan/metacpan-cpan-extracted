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
    my $ciphertext = pack "H32", "cdecdcfb48d6af61cc3e3fafa9b9bfac";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("09090909090909090909090909090909", $answer);
};

