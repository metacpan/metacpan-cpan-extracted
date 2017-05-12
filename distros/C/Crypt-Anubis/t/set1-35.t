use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 1, vector#124:
BEGIN {
    my $key = pack "H32", "00000000000000000000000000000008";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "220091f836039a59522dcc0797abf5b2";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00000000000000000000000000000000", $answer);
};

