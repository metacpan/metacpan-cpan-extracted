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
    my $ciphertext = pack "H32", "7c9945109222fd0fd865c6b3eff5c93e";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6f6", $answer);
};

