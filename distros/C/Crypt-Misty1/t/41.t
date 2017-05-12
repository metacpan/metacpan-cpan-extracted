use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Misty1')
};

BEGIN {
    my $key = pack "H32", "03030303030303030303030303030303";
    my $cipher = new Crypt::Misty1 $key;
    my $ciphertext = pack "H16", "7e12eab92c53c081";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("0303030303030303", $answer);
};

