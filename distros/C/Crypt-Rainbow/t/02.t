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
    my $ciphertext = pack "H32", "664e6a126c05ce620616dbd09b7ed6e8";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00112233445566778899aabbccddeeff", $answer);
};

