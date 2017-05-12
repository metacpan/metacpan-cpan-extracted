
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium;

my $crypto = Crypt::NaCl::Sodium->new();

ok($crypto, "got crypto wrapper object");

isa_ok($crypto->$_, "Crypt::NaCl::Sodium::$_")
    for qw(
        aead
        auth
        box
        generichash
        hash
        onetimeauth
        pwhash
        scalarmult
        secretbox
        shorthash
        sign
        stream
    );

done_testing();
