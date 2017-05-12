use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 1, vector#126:
BEGIN {
    my $key = pack "H32", "00000000000000000000000000000002";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "06030fe32cd601f812281671d729f4ff";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00000000000000000000000000000000", $answer);
};

