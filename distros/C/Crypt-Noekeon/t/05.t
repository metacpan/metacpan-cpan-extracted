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
    my $ciphertext = pack "H32", "52f88a7b283c1f7bdf7b6faa5011c7d8";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("ffffffffffffffffffffffffffffffff", $answer);
};

