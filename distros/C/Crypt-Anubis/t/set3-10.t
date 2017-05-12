use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 3, vector#   4:
BEGIN {
    my $key = pack "H32", "04040404040404040404040404040404";
    my $cipher = new Crypt::Anubis $key;
    my $plaintext = pack "H32", "04040404040404040404040404040404";
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("90bee6d210452ef185ec908440d0d716", $answer);
};

