#!perl
# -*-cperl-*-
#
# 01-signverify.t - Test ECDSA signing and verification
# Copyright (c) 2017 Ashish Gulhati <crypt-ecdsa at hash.neo.tc>

use Test::More tests => 5;

use Crypt::EC_DSA;

ok (my $ecdsa = new Crypt::EC_DSA,                    "Create Crypt::EC_DSA object");
ok (my ($pubkey, $seckey) = $ecdsa->keygen,           "Key generation");
ok (my $sig = $ecdsa->sign( Message => "Testing", Key  => $seckey ), "Sign");
ok ($ecdsa->verify( Signature => $sig, Message => 'Testing', Key => $pubkey ), "Verify signature");
ok (!$ecdsa->verify( Signature => $sig, Message => 'Foo', Key => $pubkey ), "Bad signature");

exit;
