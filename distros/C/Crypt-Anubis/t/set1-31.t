use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 1, vector#122:
BEGIN {
    my $key = pack "H32", "00000000000000000000000000000020";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "f423c4214cabe986f5cfd0acbb821744";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00000000000000000000000000000000", $answer);
};

