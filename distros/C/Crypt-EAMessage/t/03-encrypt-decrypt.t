#!/usr/bin/perl

#
# Copyright (C) 2016 J. Maslak
# All Rights Reserved - See License
#

use Test2::Bundle::Extended 0.000058;

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

    my $encrypted = $eamsg->encrypt_auth($txt);
    my $ascii     = $eamsg->encrypt_auth_ascii($txt);

    ok(length($encrypted) < length($ascii), "ASCII encrypted message is longer for msg $cnt");

    my ($plain, $plain2);
    ok(lives( sub { $plain = $eamsg->decrypt_auth($encrypted) } ), "Decrypted raw msg $cnt");
    is( $plain, $txt, "Decrypted raw msg $cnt correctly" );
    ok(lives( sub { $plain2 = $eamsg->decrypt_auth($ascii) } ), "Decrypted B64 msg $cnt");
    is( $plain2, $txt, "Decrypted B64 msg $cnt correctly" );

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

