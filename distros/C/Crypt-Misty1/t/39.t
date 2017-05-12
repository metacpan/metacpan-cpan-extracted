use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Misty1')
};

BEGIN {
    my $key = pack "H32", "02020202020202020202020202020202";
    my $cipher = new Crypt::Misty1 $key;
    my $ciphertext = pack "H16", "08faa3bcf4c057e9";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("0202020202020202", $answer);
};

