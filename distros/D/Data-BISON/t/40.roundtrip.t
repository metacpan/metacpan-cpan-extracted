#!/usr/bin/perl

use strict;
use warnings;
use Data::BISON::Encoder;
use Data::BISON::Decoder;
use Data::BISON::yEnc qw(encode_yEnc decode_yEnc);
use Data::Dumper;
use Test::More;

my @tests;

BEGIN {

    my $struct = {
        unicode => 'π',
        nums    => [ -1, 12345678, 1.25 ],
        nested  => {
            hash => { slashed => '\\\\\\' },
            array => [ [], [], {} ],
        },
    };

    my $no_float = {
        unicode => 'π',
        nums    => [ -1, 12345678, 0 ],
        nested  => {
            hash => { name => '\\\\\\' },
            array => [ [], [], {} ],
        },
    };

    my $deeper = {
        struct   => $struct,
        no_float => $no_float,
    };

    @tests = (
        {
            name     => 'Simple roundtrip',
            input    => $no_float,
            enc_args => {},
            dec_args => {},
            filter   => sub { return shift },
        },
        {
            name     => 'With floats',
            input    => $struct,
            enc_args => {},
            dec_args => {},
            filter   => sub { return shift },
        },
        {
            name     => 'Deeper',
            input    => $deeper,
            enc_args => {},
            dec_args => {},
            filter   => sub { return shift },
        },
        {
            name     => 'Encoded with yEnc',
            input    => $deeper,
            enc_args => { yenc => 1 },
            dec_args => {},
            filter   => sub { return shift },
        },
        {
            name     => 'Encoded afer yEnc',
            input    => $deeper,
            enc_args => {},
            dec_args => {},
            filter   => sub { return encode_yEnc( shift ) },
        },
        {
            name     => 'Deeper w/doubles',
            input    => $deeper,
            enc_args => { double => 1 },
            dec_args => {},
            filter   => sub { return shift },
        },
    );

    plan tests => 6 * @tests;
}

for my $test ( @tests ) {
    my $name = $test->{name};
    ok my $enc = Data::BISON::Encoder->new( $test->{enc_args} ),
      "$name: encoder made OK";
    isa_ok $enc, 'Data::BISON::Encoder';
    ok my $dec = Data::BISON::Decoder->new( $test->{dec_args} ),
      "$name: decoder made OK";
    isa_ok $dec, 'Data::BISON::Decoder';

    my $data = $enc->encode( $test->{input} );
    $data = $test->{filter}->( $data );

    my $got = eval { $dec->decode( $data ) };
    unless ( ok !$@, "$name: no error" ) {
        diag "Error: $@";
    }

    unless ( is_deeply $got, $test->{input},
        "$name: structure round-tripped OK" ) {
        diag( Data::Dumper->Dump( [$got],             ['$got'] ) );
        diag( Data::Dumper->Dump( [ $test->{input} ], ['$ref'] ) );
    }
}
