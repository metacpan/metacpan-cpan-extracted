use diagnostics;
use strict;
use warnings;
use Test::More tests => 2;
BEGIN {
    use_ok('Crypt::Rabbit')
};

BEGIN {
    my $key = pack "H32", "c21fcf3881cd5ee8628accb0a9890df8";
    my $cipher = new Crypt::Rabbit $key;
    my $plaintext = pack "H64", 0;
    my $ciphertext = $cipher->encrypt($plaintext);
    my $answer = unpack "H*", $ciphertext;
    is("3d02e0c730559112b473b790dee018dfcd6d730ce54e19f0c35ec4790eb6c74a", $answer);
};

