use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Khazad')
};

BEGIN {
    my $key = pack "H32", "fdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfd";
    my $cipher = new Crypt::Khazad $key;
    my $ciphertext = pack "H16", "4ab8bc9c7739d6d0";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("fdfdfdfdfdfdfdfd", $answer);
};

