use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Khazad')
};

BEGIN {
    my $key = pack "H32", "02020202020202020202020202020202";
    my $cipher = new Crypt::Khazad $key;
    my $ciphertext = pack "H16", "d5b53e4cf8bba7e4";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("0202020202020202", $answer);
};

