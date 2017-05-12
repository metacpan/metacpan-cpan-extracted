use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector# 250:
BEGIN {
    my $key = pack "H32", "fafafafafafafafafafafafafafafafa";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "3e1abbe354f62e1be5d9bd0599f5b2ed";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("fafafafafafafafafafafafafafafafa", $answer);
};

