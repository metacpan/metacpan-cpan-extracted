#!/usr/bin/env perl
use strict;
use warnings;

## testvectors_kg.t
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::Key;
use Crypt::RSA::Primitives;

plan tests => 6;

my $rsa      = new Crypt::RSA::Primitives;
my $keychain = new Crypt::RSA::Key;

my ($pubkey, $prikey) = $keychain->generate( q => 2551, p => 2357, e => 3674911, Password => 'xx' );
ok( ! $keychain->errstr, "No error from generate" );

is( $prikey->d,    422191, "d" );
is( $prikey->phi, 6007800, "phi" );
is( $prikey->n,   6012707, "n" );

my $c = $rsa->core_encrypt ( Key => $pubkey, Plaintext => 5_234_673 );
is( $c, 3_650_502, "encryption");

my $d = $rsa->core_decrypt ( Key => $prikey, Cyphertext => $c );
is( $d, 5_234_673, "decryption");
