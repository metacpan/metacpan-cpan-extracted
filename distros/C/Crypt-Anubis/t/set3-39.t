use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector# 254:
BEGIN {
    my $key = pack "H32", "fefefefefefefefefefefefefefefefe";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "6dc5daa2267d626f08b7528e6e6e8690";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("fefefefefefefefefefefefefefefefe", $answer);
};

