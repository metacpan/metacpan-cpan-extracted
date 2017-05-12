use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 1, vector#119:
BEGIN {
    my $key = pack "H32", "00000000000000000000000000000100";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "b200440956ab384971599f924f9f5809";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00000000000000000000000000000000", $answer);
};

