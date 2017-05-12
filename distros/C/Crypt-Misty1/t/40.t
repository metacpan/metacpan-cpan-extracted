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
    my $plaintext = pack "H16", "0303030303030303";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("7e12eab92c53c081", $answer);
};

