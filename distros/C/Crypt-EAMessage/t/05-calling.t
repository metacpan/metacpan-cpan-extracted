#!/usr/bin/perl

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;

use v5.22;

use Test2::V0 0.000111;

use Crypt::EAMessage;

# Tests for improper ways of calling some methods

MAIN: {
    my $eamsg = Crypt::EAMessage->new( hex_key => '12345678901234567890123456789012' );

    ok( dies( sub { $eamsg->decrypt_auth() } ),         'decrypt_auth no args' );
    ok( dies( sub { $eamsg->encrypt_auth() } ),         'encrypt_auth no args' );
    ok( dies( sub { $eamsg->encrypt_auth_ascii() } ),   'encrypt_auth_ascii no args' );
    ok( dies( sub { $eamsg->encrypt_auth_urlsafe() } ), 'encrypt_auth_urlsafe no args' );

    ok( dies( sub { $eamsg->decrypt_auth( 1, 2 ) } ), 'decrypt_auth two args' );
    ok( dies( sub { $eamsg->encrypt_auth( 1, 2 ) } ), 'encrypt_auth two args' );
    ok( dies( sub { $eamsg->encrypt_auth_ascii( 1, 2, 3 ) } ), 'encrypt_auth_ascii three args' );
    ok( dies( sub { $eamsg->encrypt_auth_urlsafe( 1, 2 ) } ), 'encrypt_auth_urlsafe two args' );

}

done_testing;

1;

