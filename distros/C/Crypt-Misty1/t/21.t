use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Misty1')
};

BEGIN {
    my $key = pack "H32", "00000000000000000000000000000000";
    my $cipher = new Crypt::Misty1 $key;
    my $ciphertext = pack "H16", "975e0afe1323cb9a";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("4000000000000000", $answer);
};

