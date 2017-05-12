use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Khazad')
};

BEGIN {
    my $key = pack "H32", "fefefefefefefefefefefefefefefefe";
    my $cipher = new Crypt::Khazad $key;
    my $plaintext = pack "H16", "fefefefefefefefe";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("1bce18d41d14b58b", $answer);
};

