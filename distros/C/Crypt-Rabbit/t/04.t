use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Rabbit')
};

BEGIN {
    my $key = pack "H32", "1d272c6a2d8e3dfcac14056b78d633a0";
    my $cipher = new Crypt::Rabbit $key;
    my $plaintext = pack "H72", 0;
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("a3a97abb80393820b7e50c4abb53823dc4423799c2efc9ffb3a4125f1f4c99a8ae953e56", $answer);
};

