use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector#   7:
BEGIN {
    my $key = pack "H32", "07070707070707070707070707070707";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "66e83582cefeecb9cd3c46432e550aca";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("07070707070707070707070707070707", $answer);
};

