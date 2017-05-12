#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Data::BISON::Encoder;

my @tests;

BEGIN {
    my @FMB = ( 0x46, 0x4d, 0x42 );

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
            data    => undef,
            expect  => [ @FMB, 0x02 ],
        },

        # Strings
        {
            name    => 'Simple string',
            options => {},
            data    => 'Hello, World',
            expect  => [ @FMB, @hello_world ],
        },
        {
            name    => 'String w/ embedded null',
            options => {},
            data    => "\0 null",
            expect =>
              [ @FMB, 0x0F, 0x5C, 0x00, 0x20, 0x6e, 0x75, 0x6c, 0x6c, 0x00 ],
        },
        {
            name    => 'String w/ backslash and null',
            options => {},
            data    => "\0\\ null",
            expect  => [
                @FMB, 0x0F, 0x5C, 0x00, 0x5C, 0x5C,
                0x20, 0x6e, 0x75, 0x6c, 0x6c, 0x00
            ],
        },

        # Integers
        {
            name    => 'Integer, zero',
            options => {},
            data    => 0,
            expect  => [ @FMB, 0x05, 0x00 ],
        },
        {
            name    => 'Integer, positive, 1 byte',
            options => {},
            data    => 127,
            expect  => [ @FMB, 0x05, 0x7F ],
        },
        {
            name    => 'Integer, -1',
            options => {},
            data    => -1,
            expect  => [ @FMB, 0x05, 0xFF ],
        },
        {
            name    => 'Integer, positive, 2 bytes, edge',
            options => {},
            data    => 128,
            expect  => [ @FMB, 0x06, 0x80, 0x00 ],
        },
        {
            name    => 'Integer, positive, 2 bytes',
            options => {},
            data    => 255,
            expect  => [ @FMB, 0x06, 0xFF, 0x00 ],
        },
        {
            name    => 'Integer, negative, 1 byte',
            options => {},
            data    => -128,
            expect  => [ @FMB, 0x05, 0x80 ],
        },
        {
            name    => 'Integer, negative, 2 bytes',
            options => {},
            data    => -255,
            expect  => [ @FMB, 0x06, 0x01, 0xFF ],
        },
        {
            name    => 'Integer, positive, 3 bytes',
            options => {},
            data    => 0x7F0000,
            expect  => [ @FMB, 0x07, 0x00, 0x00, 0x7F ],
        },
        {
            name    => 'Integer, negative, 3 bytes',
            options => {},
            data    => -0x7F0000,
            expect  => [ @FMB, 0x07, 0x00, 0x00, 0x81 ],
        },
        {
            name    => 'Integer, positive, 4 bytes',
            options => {},
            data    => 0x7F000000,
            expect  => [ @FMB, 0x08, 0x00, 0x00, 0x00, 0x7F ],
        },
        {
            name    => 'Integer, negative, 4 bytes',
            options => {},
            data    => -0x7F000000,
            expect  => [ @FMB, 0x08, 0x00, 0x00, 0x00, 0x81 ],
        },

        # Arrays
        {
            name    => 'Array, empty',
            options => {},
            data    => [],
            expect  => [ @FMB, 0x10, 0x00, 0x00 ],
        },
        {
            name    => 'Array, one string',
            options => {},
            data    => ['Hello, World'],
            expect  => [ @FMB, 0x10, 0x01, 0x00, @hello_world ],
        },
        {
            name    => 'Array, two strings',
            options => {},
            data    => [ 'Hello, World', 'Hello, World' ],
            expect  => [ @FMB, 0x10, 0x02, 0x00, @hello_world, @hello_world ],
        },

        # Hashes
        {
            name    => 'Hash, empty',
            options => {},
            data    => {},
            expect  => [ @FMB, 0x11, 0x00, 0x00 ],
        },
        {
            name    => 'Hash, one string',
            options => {},
            data    => { 'hello' => 'Hello, World' },
            expect  => [ @FMB, 0x11, 0x01, 0x00, @hello, @hello_world ],
        },
        {
            name    => 'Hash, two strings',
            options => { sort => 1 },
            data    => { 'hello' => 'Hello, World', 'abc' => 'xyz' },
            expect =>
              [ @FMB, 0x11, 0x02, 0x00, @abc, @xyz, @hello, @hello_world ],
        },

        # More complex structures
        {
            name    => 'Array of hash of strings',
            options => { sort => 1 },
            data    => [
                { 'hello' => 'Hello, World', 'abc' => 'xyz' },
                { 'hello' => 'Hello, World', 'abc' => 'xyz' }
            ],
            expect =>
              [ @FMB, 0x10, 0x02, 0x00, @two_string_hash, @two_string_hash ],
        },

    );

    plan tests => 3 * @tests;
}

sub dumpb {
    return join( ', ', map { sprintf( '0x%02x', $_ ) } @_ );
}

for my $test ( @tests ) {
    my $name = $test->{name};
    ok my $enc = Data::BISON::Encoder->new( $test->{options} ),
      "$name: create OK";
    isa_ok $enc, 'Data::BISON::Encoder';
    my $data = $enc->encode( $test->{data} );
    my @got = map { ord $_ } split //, $data;
    unless ( is_deeply \@got, $test->{expect}, "$name: data matches" ) {
        diag "got: ", dumpb( @got );
        diag "exp: ", dumpb( @{ $test->{expect} } );
    }
}
