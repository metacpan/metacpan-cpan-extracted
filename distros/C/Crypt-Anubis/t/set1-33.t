use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Anubis')
};

# Set 1, vector#123:
BEGIN {
    my $key = pack "H32", "00000000000000000000000000000010";
    my $cipher = new Crypt::Anubis $key;
    my $ciphertext = pack "H32", "91150aec3f6844ac312e4a2ab258b1d9";
    my $plaintext = $cipher->decrypt($ciphertext);
    my $answer = unpack "H*", $plaintext;
    is("00000000000000000000000000000000", $answer);
};

