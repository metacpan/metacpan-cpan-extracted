use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Misty1')
};

BEGIN {
    my $key = pack "H32", "fdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfd";
    my $cipher = new Crypt::Misty1 $key;
    my $ciphertext = pack "H16", "21d5792e34359d32";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("fdfdfdfdfdfdfdfd", $answer);
};

