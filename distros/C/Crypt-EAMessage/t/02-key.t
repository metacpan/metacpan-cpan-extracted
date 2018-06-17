#!/usr/bin/perl

#
# Copyright (C) 2016 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::Bundle::Extended 0.000058;

use Crypt::EAMessage;

# Validate key checking methods

my (@KEYS) = (
    [ 1, 'raw_key', 'abcdefghijklmnop' ],
    [ 1, 'raw_key', 'abcdefghijklmnopqrstuvwx' ],
    [ 1, 'raw_key', 'abcdefghijklmnopqrstuvwxyz012345' ],
    [ 0, 'raw_key', '' ],
    [ 0, 'raw_key', 'abcdefghijklmnl' ],
    [ 0, 'raw_key', "abcdefghijklmno\x{0100}" ],

    [ 1, 'hex_key', '11223344556677889900112233445566' ],
    [ 1, 'hex_key', '112233445566778899001122334455667788990011223344' ],
    [ 1, 'hex_key', '1122334455667788990011223344556677889900112233445566778899001122' ],
    [ 1, 'hex_key', '11223344556677889900aabBccDDeeFF' ],
    [ 1, 'hex_key', '0x11223344556677889900aaBBccDDeeFF' ],
    [ 0, 'hex_key', '' ],
    [ 0, 'hex_key', 'zz223344556677889900aaBBccDDeeFF' ],
    [ 0, 'hex_key', '11223344556677889900aaBBccDDeeFF1' ],
);

my $ea = Crypt::EAMessage->new( raw_key => '1234567890123456' );

my $cnt = 0;
foreach my $test (@KEYS) {
    $cnt++;
    my ( $valid, $type, $key ) = @$test;

    if ($valid) {
        ok( lives( sub { Crypt::EAMessage->new( $type => $key ) } ), "Key $cnt is valid" );

        if ($type eq 'hex_key') {
            ok( lives( sub { $ea->hex_key($key) } ), "Key $cnt can be set with hex_key");
        } elsif ($type eq 'raw_key') {
            ok( lives( sub { $ea->raw_key($key) } ), "Key $cnt can be set with raw_key");
        }

        my $raw_key = $ea->raw_key();
        my $hex_key = $ea->hex_key();

        isnt($raw_key, $hex_key, "Key $cnt has different hex and raw");

        if ($type eq 'hex_key') {
            my $k = $key;
            $k =~ s/^0x//;
            is( $ea->hex_key(), lc $k, "Key $cnt matches hex_key");
        } elsif ($type eq 'raw_key') {
            is( $ea->raw_key(), $key, "Key $cnt matches raw_key");
        }
    } else {
        my $f;
        ok( dies( sub { Crypt::EAMessage->new( $type => $key ) } ), "Key $cnt is not valid" );
    }
}

done_testing;

1;

