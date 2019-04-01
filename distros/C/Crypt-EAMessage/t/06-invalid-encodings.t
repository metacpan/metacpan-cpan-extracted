#!/usr/bin/perl

#
# Copyright (C) 2019 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::V0 0.000111;

use Crypt::EAMessage;

my (@MSG) = (
    {
        ct => '301a725f4c3ed0693673b8a2303ea6f8c38a6f62c93bafc53'
          . '9512eacdc075106d21b2c6a412129407a6cde2b824f2d60a3fd'
          . 'cd9b88d9714269ce85cd066748115470bf',
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        desc => 'Type 0',
    },
    {
        ct => '351a725f4c3ed0693673b8a2303ea6f8c38a6f62c93bafc53'
          . '9512eacdc075106d21b2c6a412129407a6cde2b824f2d60a3fd'
          . 'cd9b88d9714269ce85cd066748115470bf',
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        desc => 'Type 5',
    },
    {
        # Type chr(0)
        ct => '001a725f4c3ed0693673b8a2303ea6f8c38a6f62c93bafc53'
          . '9512eacdc075106d21b2c6a412129407a6cde2b824f2d60a3fd'
          . 'cd9b88d9714269ce85cd066748115470bf',
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        desc => 'Type chr(0)',
    },
    {
        # Type space
        ct => '20311a725f4c3ed0693673b8a2303ea6f8c38a6f62c93bafc53'
          . '9512eacdc075106d21b2c6a412129407a6cde2b824f2d60a3fd'
          . 'cd9b88d9714269ce85cd066748115470bf',
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        desc => 'Type Space',
    },
);

my $cnt = 0;
foreach my $msg (@MSG) {
    $cnt++;

    my $ct   = pack( 'H*', $msg->{ct} );
    my $key  = $msg->{key};
    my $desc = $msg->{desc};

    my $eamsg = Crypt::EAMessage->new( hex_key => $key );

    my $e;
    ok(
        $e = dies {
            $eamsg->decrypt_auth($ct);
        },
        "Exception thrown by $desc"
    );
    $e =~ s/ at .*//s;

    is($e, 'Unsupported encoding type', "Exception is correct for $desc");
}

done_testing;

1;

