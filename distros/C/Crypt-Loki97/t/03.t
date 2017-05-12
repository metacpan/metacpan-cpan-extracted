use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Loki97')
};

BEGIN {
    my $key = pack "H32", "80000000000000000000000000000000";
    my $cipher = new Crypt::Loki97 $key;
    my $plaintext = pack "H32", "00000000000000000000000000000000";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("48f00dff8c90822417d12ecad682b014", $answer);
};

