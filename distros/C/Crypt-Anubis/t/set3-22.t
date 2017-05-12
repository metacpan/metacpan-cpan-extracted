use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector# 246:
BEGIN {
    my $key = pack "H32", "f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("7c9945109222fd0fd865c6b3eff5c93e", $answer);
};

