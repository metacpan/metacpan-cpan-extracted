#!/usr/bin/perl

#
# Copyright (C) 2016 J. Maslak
# All Rights Reserved - See License
#

use Test2::Bundle::Extended 0.000058;

use Crypt::EAMessage;

# Tests to make sure we don't end up with versions that are incompatible
# with past implementations

# Note the "ct" elements below are produced by running the output
# of the encrypt_auth or encrypt_auth_ascii routines through
# unpack("H*", ...

my (@MSG) = (
    {
        ct => '311a725f4c3ed0693673b8a2303ea6f8c38a6f62c93bafc5395'
          . '12eacdc075106d21b2c6a412129407a6cde2b824f2d60a3fdcd9b'
          . '88d9714269ce85cd066748115470bf',
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        text => 'Plain Text Message RAW encoded',
    },
    {
        ct => '3247457338585962724b37663146646237444830386750467'
          . '273776d45417843716b667a78724b44532b5742755a63344f69'
          . '474b3747423759655558636133426b6e4f4b6656504f574f6f6'
          . '6670a564254744b584c4457496a5a574e413d0a',
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        text => 'Plain Text Message ASCII encoded',
    },
);

my $cnt = 0;
foreach my $msg (@MSG) {
    $cnt++;

    my $ct  = pack( 'H*', $msg->{ct} );
    my $key = $msg->{key};
    my $txt = $msg->{text};

    my $eamsg = Crypt::EAMessage->new( hex_key => $key );

    my $pt = $eamsg->decrypt_auth($ct);

    is( $pt, $txt, "Decryption of msg $cnt is correct" );
}

done_testing;

1;

