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
    my $ciphertext = pack "H16", "1bce18d41d14b58b";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("fefefefefefefefe", $answer);
};

