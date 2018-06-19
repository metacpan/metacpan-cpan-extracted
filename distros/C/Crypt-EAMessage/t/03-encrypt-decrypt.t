#!/usr/bin/perl

#
# Copyright (C) 2016-2018 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::V0 0.000111;

use Crypt::EAMessage;

# Tests for creating and erasing messages

my (@MSG) = (
    {
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        text => 'Plain Text Message',
    },
    {
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        text => '',
    },
    {
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        text => undef,
    },
    {
        key  => 'abcd1234abcd1234abcd1234abcd1234',
        text => { a => [ 'b', 'c' ], c => 3 },
    },
);

my $cnt = 0;
foreach my $msg (@MSG) {
    $cnt++;

    my $key = $msg->{key};
    my $txt = $msg->{text};

    my $eamsg = Crypt::EAMessage->new( hex_key => $key );

    my $encrypted  = $eamsg->encrypt_auth($txt);
    my $ascii      = $eamsg->encrypt_auth_ascii($txt);
    my $ascii_crlf = $eamsg->encrypt_auth_ascii($txt, "\r\n");
    my $ascii_nolf = $eamsg->encrypt_auth_ascii($txt, "");
    my $urlsafe    = $eamsg->encrypt_auth_urlsafe($txt);

    ok(length($encrypted) < length($ascii), "ASCII encrypted message is longer for msg $cnt");
    ok(length($encrypted) < length($ascii_crlf), "ASCII CRLF encrypted message is longer for msg $cnt");
    ok(length($encrypted) < length($ascii_nolf), "ASCII no-LF encrypted message is longer for msg $cnt");
    ok(length($ascii) <= length($ascii_crlf), "ASCII CRLF encrypted message is longer than or same length as LF encrypted for msg $cnt");
    ok(length($ascii_nolf) <= length($ascii), "ASCII no-LF encrypted message is longer than or same length as ascii encrypted for msg $cnt");
    ok(length($ascii_nolf) < length($ascii_crlf), "ASCII CRLF encrypted message is longer than CRLF encrypted for msg $cnt");
    ok(length($urlsafe) == length($ascii_nolf), "URL-Safe encrypted message is same length as ASCII no-LF encrypted message for msg $cnt");

    my ($plain, $plain2, $plain3, $plain4, $plain5);

    ok(lives( sub { $plain = $eamsg->decrypt_auth($encrypted) } ), "Decrypted raw msg $cnt");
    is( $plain, $txt, "Decrypted raw msg $cnt correctly" );

    ok(lives( sub { $plain2 = $eamsg->decrypt_auth($ascii) } ), "Decrypted B64 msg $cnt");
    is( $plain2, $txt, "Decrypted B64 msg $cnt correctly" );

    ok(lives( sub { $plain3 = $eamsg->decrypt_auth($ascii_crlf) } ), "Decrypted B64 CRLF msg $cnt");
    is( $plain3, $txt, "Decrypted B64 CRLF msg $cnt correctly" );

    ok(lives( sub { $plain4 = $eamsg->decrypt_auth($ascii_nolf) } ), "Decrypted B64 NOLF msg $cnt");
    is( $plain4, $txt, "Decrypted B64 msg $cnt correctly" );

    ok(lives( sub { $plain5 = $eamsg->decrypt_auth($urlsafe) } ), "Decrypted URL Safe msg $cnt");
    is( $plain5, $txt, "Decrypted B64 msg $cnt correctly" );

    my $badkey = '11112222333344445555666677778888';
    $eamsg = Crypt::EAMessage->new( hex_key => $badkey );
    ok(dies( sub { $eamsg->decrypt_auth($encrypted) } ), "Can't decrypt msg $cnt with bad key");;

    $encrypted =~ s/.$//;
    ok(dies( sub { $eamsg->decrypt_auth($encrypted) } ), "Can't decrypt msg $cnt with tampered-with message");

    my $encrypted2 = $eamsg->encrypt_auth($txt);
    isnt($encrypted2, $encrypted, "Two encrypts of msg $cnt return different values");
}

done_testing;

1;

