use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector# 252:
BEGIN {
    my $key = pack "H32", "fcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfc";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "fcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfc";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("cbee419760f1db34d553208a18416a85", $answer);
};

