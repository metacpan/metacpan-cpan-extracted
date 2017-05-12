#!/usr/bin/perl

package Flube;

sub new {
    return bless {}, shift;
}

package main;

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Data::BISON::Decoder;

my @tests;

BEGIN {
    my @FMB    = ( 0x46, 0x4d, 0x42 );
    my @FMB2   = ( 0x46, 0x4d, 0x42, 0xFF, 0x02, 0x00 );
    my @FMB2br = ( 0x46, 0x4d, 0x42, 0xFF, 0x02, 0x80 );

    my @hello = ( 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x00 );
    my @abc = ( 0x61, 0x62, 0x63, 0x00 );

    my @hello_world = (
        0x0f, 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20,
        0x57, 0x6f, 0x72, 0x6c, 0x64, 0x00
    );
    my @xyz = ( 0x0f, 0x78, 0x79, 0x7a, 0x00 );
    my @two_string_hash
      = ( 0x11, 0x02, 0x00, @abc, @xyz, @hello, @hello_world );

    @tests = (

        # undef
        {
            name    => 'Undef',
            options => {},
            data    => [ @FMB, 0x02 ],
            expect  => undef,
        },

        # Strings
        {
            name    => 'Simple string',
            options => {},
            data    => [ @FMB, @hello_world ],
            expect  => 'Hello, World',
        },
        {
            name    => 'String w/ embedded null',
            options => {},
            data =>
              [ @FMB, 0x0F, 0x5C, 0x00, 0x20, 0x6e, 0x75, 0x6c, 0x6c, 0x00 ],
            expect => "\0 null",
        },
        {
            name    => 'String w/ backslash and null',
            options => {},
            data    => [
                @FMB, 0x0F, 0x5C, 0x00, 0x5C, 0x5C,
                0x20, 0x6e, 0x75, 0x6c, 0x6c, 0x00
            ],
            expect => "\0\\ null",
        },

        # Integers
        {
            name    => 'Integer, zero',
            options => {},
            data    => [ @FMB, 0x05, 0x00 ],
            expect  => 0,
        },
        {
            name    => 'Integer, positive, 1 byte',
            options => {},
            data    => [ @FMB, 0x05, 0x7F ],
            expect  => 127,
        },
        {
            name    => 'Integer, -1',
            options => {},
            data    => [ @FMB, 0x05, 0xFF ],
            expect  => -1,
        },
        {
            name    => 'Integer, positive, 2 bytes, edge',
            options => {},
            data    => [ @FMB, 0x06, 0x80, 0x00 ],
            expect  => 128,
        },
        {
            name    => 'Integer, positive, 2 bytes',
            options => {},
            data    => [ @FMB, 0x06, 0xFF, 0x00 ],
            expect  => 255,
        },
        {
            name    => 'Integer, negative, 1 byte',
            options => {},
            data    => [ @FMB, 0x05, 0x80 ],
            expect  => -128,
        },
        {
            name    => 'Integer, negative, 2 bytes',
            options => {},
            data    => [ @FMB, 0x06, 0x01, 0xFF ],
            expect  => -255,
        },
        {
            name    => 'Integer, positive, 3 bytes',
            options => {},
            data    => [ @FMB, 0x07, 0x00, 0x00, 0x7F ],
            expect  => 0x7F0000,
        },
        {
            name    => 'Integer, negative, 3 bytes',
            options => {},
            data    => [ @FMB, 0x07, 0x00, 0x00, 0x81 ],
            expect  => -0x7F0000,
        },
        {
            name    => 'Integer, positive, 4 bytes',
            options => {},
            data    => [ @FMB, 0x08, 0x00, 0x00, 0x00, 0x7F ],
            expect  => 0x7F000000,
        },
        {
            name    => 'Integer, negative, 4 bytes',
            options => {},
            data    => [ @FMB, 0x08, 0x00, 0x00, 0x00, 0x81 ],
            expect  => -0x7F000000,
        },

        # Arrays
        {
            name    => 'Array, empty',
            options => {},
            data    => [ @FMB, 0x10, 0x00, 0x00 ],
            expect  => [],
        },
        {
            name    => 'Array, one string',
            options => {},
            data    => [ @FMB, 0x10, 0x01, 0x00, @hello_world ],
            expect  => ['Hello, World'],
        },
        {
            name    => 'Array, two strings',
            options => {},
            data    => [ @FMB, 0x10, 0x02, 0x00, @hello_world, @hello_world ],
            expect => [ 'Hello, World', 'Hello, World' ],
        },

        # Hashes
        {
            name    => 'Hash, empty',
            options => {},
            data    => [ @FMB, 0x11, 0x00, 0x00 ],
            expect  => {},
        },
        {
            name    => 'Hash, one string',
            options => {},
            data    => [ @FMB, 0x11, 0x01, 0x00, @hello, @hello_world ],
            expect => { 'hello' => 'Hello, World' },
        },
        {
            name    => 'Hash, two strings',
            options => {},
            data =>
              [ @FMB, 0x11, 0x02, 0x00, @abc, @xyz, @hello, @hello_world ],
            expect => { 'hello' => 'Hello, World', 'abc' => 'xyz' },
        },

        # More complex structures
        {
            name    => 'Array of hash of strings',
            options => {},
            data =>
              [ @FMB, 0x10, 0x02, 0x00, @two_string_hash, @two_string_hash ],
            expect => [
                { 'hello' => 'Hello, World', 'abc' => 'xyz' },
                { 'hello' => 'Hello, World', 'abc' => 'xyz' }
            ],
        },

        # Version 2 data
        {
            name    => 'Simple string, V2',
            options => {},
            data    => [ @FMB2, @hello_world ],
            expect  => 'Hello, World',
        },
        {
            name    => 'Simple string, V2, backref',
            options => {},
            data    => [ @FMB2br, @hello_world ],
            expect  => 'Hello, World',
        },
        {
            name    => 'Backref to string',
            options => {},
            data    => [ @FMB2br, 0x10, 0x02, 0x00, @hello_world, 0x14, 0x01, 0x00 ],
            expect  => [ 'Hello, World', 'Hello, World' ],
        },

    );

    plan tests => 3 * @tests;
}

sub dumpb {
    return join( ', ', map { sprintf( '0x%02x', $_ ) } @_ );
}

for my $test ( @tests ) {
    my $name = $test->{name};
    ok my $dec = Data::BISON::Decoder->new( $test->{options} ),
      "$name: create OK";
    isa_ok $dec, 'Data::BISON::Decoder';
    my $data = join( '', map { chr $_ } @{ $test->{data} } );
    my $got = $dec->decode( $data );
    unless ( is_deeply $got, $test->{expect}, "$name: data matches" ) {
        diag "Data: ", dumpb( @{ $test->{data} } );
        diag( Data::Dumper->Dump( [$got], ['$got'] ) );
        diag( Data::Dumper->Dump( [ $test->{expect} ], ['$exp'] ) );
    }
}
