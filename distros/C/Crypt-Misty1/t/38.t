use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Misty1')
};

BEGIN {
    my $key = pack "H32", "02020202020202020202020202020202";
    my $cipher = new Crypt::Misty1 $key;
    my $plaintext = pack "H16", "0202020202020202";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("08faa3bcf4c057e9", $answer);
};

