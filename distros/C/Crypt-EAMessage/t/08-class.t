#!/usr/bin/perl

#
# Copyright (C) 2016-2023 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::V0 0.000111;

use Crypt::EAMessage;
use English;
use Feature::Compat::Class;
use Scalar::Util;

# Tests for creating and erasing CLASSes

class foobar {
    field $x : param;
    method baz { return 1 }
}

my $x = foobar->new( x => 1 );

my (@MSG) = (
    {
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        text => $x,
        type => 'class',
    },
);

my $cnt = 0;
SKIP: {
    skip "Corinna does not exist before Perl 5.38" if $PERL_VERSION lt v5.38.0;
    foreach my $msg (@MSG) {
        $cnt++;

        my $key = $msg->{key};
        my $txt = $msg->{text};

        my $eamsg = Crypt::EAMessage->new( hex_key => $key );

        ok( dies( sub { $eamsg->encrypt_auth($txt) } ),
            "Cannot encrypt a perl class (new style) object" );
        ok( dies( sub { $eamsg->encrypt_auth_ascii($txt) } ),
            "Cannot encrypt a perl class (new style) object" );
        ok( dies( sub { $eamsg->encrypt_auth_ascii($txt, "\r\n") } ),
            "Cannot encrypt a perl class (new style) object" );
        ok( dies( sub { $eamsg->encrypt_auth_ascii($txt, "") } ),
            "Cannot encrypt a perl class (new style) object" );
        ok( dies( sub { $eamsg->encrypt_auth_urlsafe($txt) } ),
            "Cannot encrypt a perl class (new style) object" );
        ok( dies( sub { $eamsg->encrypt_auth_portable($txt) } ),
            "Cannot encrypt a perl class (new style) object" );
    }
}

done_testing;

1;

