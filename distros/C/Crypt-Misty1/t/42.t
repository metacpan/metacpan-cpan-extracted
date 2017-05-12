use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Misty1')
};

BEGIN {
    my $key = pack "H32", "fcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfc";
    my $cipher = new Crypt::Misty1 $key;
    my $plaintext = pack "H16", "fcfcfcfcfcfcfcfc";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("2271163d80d4a3c1", $answer);
};

