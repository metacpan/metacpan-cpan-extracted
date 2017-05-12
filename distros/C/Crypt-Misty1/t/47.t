use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Misty1')
};

BEGIN {
    my $key = pack "H32", "fefefefefefefefefefefefefefefefe";
    my $cipher = new Crypt::Misty1 $key;
    my $ciphertext = pack "H16", "b3e9b62f0df07de0";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("fefefefefefefefe", $answer);
};

