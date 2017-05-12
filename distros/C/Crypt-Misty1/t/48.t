use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Misty1')
};

BEGIN {
    my $key = pack "H32", "ffffffffffffffffffffffffffffffff";
    my $cipher = new Crypt::Misty1 $key;
    my $plaintext = pack "H16", "ffffffffffffffff";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("651f3092afa551d0", $answer);
};

