use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 2, vector#122:
BEGIN {
    my $key = pack "H32", "00000000000000000000000000000000";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "42edcf7e7e3cec9256d982a72e83f188";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00000000000000000000000000000020", $answer);
};

