#!/usr/bin/perl

#
# Copyright (C) 2016 Joel C. Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;

use feature 'say';
use Crypt::EAMessage;

MAIN: {
    my $key = 'abcd1234abcd1234abcd1234abcd1234';

    my $ea = Crypt::EAMessage->new( hex_key => $key );
    
    my $raw   = $ea->encrypt_auth('Plain Text Message RAW encoded');
    my $ascii = $ea->encrypt_auth_ascii('Plain Text Message ASCII encoded');

    say "MESSAGE 1: ", unpack('H*', $raw);
    say "MESSAGE 2: ", unpack('H*', $ascii);
}


