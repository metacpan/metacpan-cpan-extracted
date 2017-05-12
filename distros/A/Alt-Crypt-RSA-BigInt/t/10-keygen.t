#!/usr/bin/env perl
use strict;
use warnings;

## 09-publickey.t
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::Key;

plan tests => 5 * 4;
my $keychain = new Crypt::RSA::Key;

for my $ksize (qw(128 256 512 768 1024)) {

    my ($pub, $pri) = $keychain->generate( Identity => 'mail@vipul.net',
                                           Password => 'a day so foul and fair',
                                           #Verbosity => 1,
                                           Size     => $ksize );
    ok( ! $keychain->errstr(), "Generated key (size $ksize) correctly" );

    die $keychain->errstr if $keychain->errstr();
    is( $pub->Identity, 'mail@vipul.net', "Identity set correctly" );
    is( $pub->n, $pri->p * $pri->q, "n = p*q" );
    ok( $pri->check, "private key checks" );
}
