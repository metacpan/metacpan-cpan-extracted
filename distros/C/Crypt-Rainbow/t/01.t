use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Rainbow')
};

BEGIN {
    my $key = pack "H32", "00112233445566778899aabbccddeeff";
    my $cipher = new Crypt::Rainbow $key;
    my $plaintext = pack "H32", "00112233445566778899aabbccddeeff";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("664e6a126c05ce620616dbd09b7ed6e8", $answer);
};

