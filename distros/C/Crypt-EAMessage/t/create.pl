#!/usr/bin/perl

#
# Copyright (C) 2016-2018 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;

use feature 'say';
use Crypt::EAMessage;

MAIN: {
    my $key = 'abcd1234abcd1234abcd1234abcd1234';

    my $ea = Crypt::EAMessage->new( hex_key => $key );

    my $raw    = $ea->encrypt_auth('Plain Text Message RAW encoded');
    my $ascii  = $ea->encrypt_auth_ascii('Plain Text Message ASCII encoded');
    my $ascii2 = $ea->encrypt_auth_ascii( 'Plain Text Message CR-LF encoded', "\r\n" );
    my $ascii3 = $ea->encrypt_auth_ascii( 'Plain Text Message no-LF encoded', '' );

    say "MESSAGE 1: ", unpack( 'H*', $raw );
    say "MESSAGE 2: ", unpack( 'H*', $ascii );
    say "MESSAGE 3: ", unpack( 'H*', $ascii2 );
    say "MESSAGE 4: ", unpack( 'H*', $ascii3 );
}

