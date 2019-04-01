#!/usr/bin/perl

#
# Copyright (C) 2016-2019 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::V0 0.000111;

use Crypt::EAMessage;

# Tests to make sure we don't end up with versions that are incompatible
# with past implementations

# Note the "ct" elements below are produced by running the output
# of the encrypt_auth or encrypt_auth_ascii routines through
# unpack("H*", ...

my (@MSG) = (
    {
        ct => '311a725f4c3ed0693673b8a2303ea6f8c38a6f62c93bafc53'
          . '9512eacdc075106d21b2c6a412129407a6cde2b824f2d60a3fd'
          . 'cd9b88d9714269ce85cd066748115470bf',
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
    {
        ct => '323762596650674451455a6c5664346c634e76493170552f6'
          . 'f713433555838487370306d594f2b55665a37532b4f53335241'
          . '636d59626336387048582f596d3355515371693133596c356c6'
          . '2560d0a3265434f61713335444638643243733d0d0a',
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        text => 'Plain Text Message CR-LF encoded',
    },
    {
        ct => '323454774c437a664764356f4a41756636794a312f466a564'
          . 'c4a38546c362b55466e44646d6d6b4c71726b6677784b2b546d'
          . '41754a5032477038516571614d3973727967535153754f54526'
          . 'c6870772f4c64384d6b72536859764a773d',
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        text => 'Plain Text Message no-LF encoded',
    },
    {
        ct => '33454c6343575141385046746f6954774451366a51564c7a66'
          . '6a504f524456424558536f555f6c762d4f4d6577696c776f544e'
          . '3037745a3553584b716256506137587a5047634f51716a35737a'
          . '4469436d57304b676f6b7535',
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        text => 'Plain Text Message URL encoded',
    },
    {
        ct => '334e4f6b4b593032495164595a46362d686673324148477254'
          . '503063786c496a376a467379354c5376706466557331546f556e'
          . '68566b5a426e2d347839316d723656576c435074473445704438'
          . '696e3071397736365f7141755143714661686b3d',
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        text => 'Plain Text Message Portable encoded',
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

