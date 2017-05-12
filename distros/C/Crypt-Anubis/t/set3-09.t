use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector#   3:
BEGIN {
    my $key = pack "H32", "03030303030303030303030303030303";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "0e040f70e9c93a76c02fa19bf19b9ccf";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("03030303030303030303030303030303", $answer);
};

