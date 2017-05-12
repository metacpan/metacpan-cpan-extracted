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
    my $plaintext = pack "H32", "fefefefefefefefefefefefefefefefe";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("6dc5daa2267d626f08b7528e6e6e8690", $answer);
};

