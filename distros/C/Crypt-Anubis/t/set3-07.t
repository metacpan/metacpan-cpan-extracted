use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector#   2:
BEGIN {
    my $key = pack "H32", "02020202020202020202020202020202";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "3fd4a2b593cd9214bb26196db4678587";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("02020202020202020202020202020202", $answer);
};

