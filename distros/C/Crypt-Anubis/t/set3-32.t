use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector# 251:
BEGIN {
    my $key = pack "H32", "fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfb";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfb";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("41d56a158893b1a5fe7d355090dbe924", $answer);
};

