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
    my $ciphertext = pack "H32", "65b4ce4647be798fc4390d2bcf43bf99";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("ffffffffffffffffffffffffffffffff", $answer);
};

