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
    my $ciphertext = pack "H32", "41d56a158893b1a5fe7d355090dbe924";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("fbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfb", $answer);
};

