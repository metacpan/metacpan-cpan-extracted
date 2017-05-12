use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Noekeon')
};

BEGIN {
    my $key = pack "H32", "ffffffffffffffffffffffffffffffff";
    my $cipher = new Crypt::Noekeon $key;
    my $plaintext = pack "H32", "ffffffffffffffffffffffffffffffff";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("52f88a7b283c1f7bdf7b6faa5011c7d8", $answer);
};

