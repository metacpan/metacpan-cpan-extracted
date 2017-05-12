use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector# 255:
BEGIN {
    my $key = pack "H32", "ffffffffffffffffffffffffffffffff";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "ffffffffffffffffffffffffffffffff";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("65b4ce4647be798fc4390d2bcf43bf99", $answer);
};

