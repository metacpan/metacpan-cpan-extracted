#!/usr/bin/perl

#
# Copyright (C) 2016-2022 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::V0 0.000111;

use Crypt::EAMessage;

# Validate key generation methods

my $key1 = Crypt::EAMessage->generate_key();
my $key2 = Crypt::EAMessage->generate_key();

is( length($key1), 64, "key1 is 64 chars long" );
is( length($key2), 64, "key2 is 64 chars long" );
like( $key1, qr/^[0-9a-f]+$/s, "key1 consists only of hex characters" );
like( $key2, qr/^[0-9a-f]+$/s, "key2 consists only of hex characters" );
isnt( $key1, $key2, "key1 != key2" );

my $ea1 = Crypt::EAMessage->new( hex_key => $key1 );
my $ea2 = Crypt::EAMessage->new( hex_key => $key2 );

ok( defined($ea1), "ea1 defined" );
ok( defined($ea2), "ea2 defined" );

my $output;
ok(
    lives(
        sub {
            open local *STDOUT, '>', \$output or die("Could not open output");
            require Crypt::EAMessage::Keygen;
        }
    ),
    "require Crypt::EAMessage::Keygen"
);
chomp($output);

is( length($output), 64, "keygen is 64 chars long" );
like( $output, qr/^[0-9a-f]+$/s, "keygen consists only of hex characters" );

isnt( $key1, $output, "keygen is not key1" );
isnt( $key2, $output, "keygen is not key2" );

my $ea3 = Crypt::EAMessage->new( hex_key => $output );

ok( defined($ea3), "ea3 defined" );

done_testing;

1;

