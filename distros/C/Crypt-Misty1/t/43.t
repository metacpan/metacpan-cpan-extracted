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
    my $ciphertext = pack "H16", "2271163d80d4a3c1";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("fcfcfcfcfcfcfcfc", $answer);
};

