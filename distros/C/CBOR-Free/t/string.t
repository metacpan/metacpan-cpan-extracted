#!/usr/bin/env perl

package t::string;

use strict;
use warnings;

use parent qw( Test::Class::Tiny );

use Test::More;
use Test::FailWarnings;

use Data::Dumper;

use CBOR::Free;
use CBOR::Free::Decoder;
use CBOR::Free::SequenceDecoder;

__PACKAGE__->runtests() if !caller;

sub T7_basic {
    my @tests = (
        [ q<> => "\x40" ],
        [ "\xff" => "\x41\xff" ],
        [ 'abc' => "\x43\x61\x62\x63" ],
        [ ('a' x 23) => "\x57" . ('a' x 23) ],
        [ ('a' x 24) => "\x58\x18" . ('a' x 24) ],

        [ 'épée' => "\x46\xc3\xa9p\xc3\xa9e" ],

        [ do { utf8::decode(my $v = 'épée'); $v } => "\x66\xc3\xa9p\xc3\xa9e" ],
    );

    for my $t (@tests) {
        my ($in, $enc) = @$t;

        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Useqq = 1;
        local $Data::Dumper::Indent = 0;

        _cmpbin( CBOR::Free::encode($in), $enc, "Encode: " . Dumper($in) );
    }
}

sub T1_ascii_text_string_roundtrip {
    my $cbor_text = "cabc";

    my $dec = CBOR::Free::decode($cbor_text);
    my $cbor2 = CBOR::Free::encode($dec);

    is( $cbor2, $cbor_text, 'text string round-trips, even if all code points are ASCII' );
}

sub T3_decode_naive_utf8 {
    my $bad_utf8 = "c\xff\xff\xff";

    my $decoder = CBOR::Free::Decoder->new();
    my $ret = $decoder->naive_utf8();
    is($ret, 1, 'naive_utf8() returns truthy' );

    my $got = $decoder->decode($bad_utf8);

    ok( utf8::is_utf8($got), 'UTF8 flag is set' );
    ok( !utf8::valid($got), '… but the actual value is invalid UTF-8' );
}

sub T3_decode_naive_utf8__sequence_decoder {
    my $bad_utf8 = "c\xff\xff\xff";

    my $decoder = CBOR::Free::SequenceDecoder->new();
    my $ret = $decoder->naive_utf8();
    is($ret, 1, 'naive_utf8() returns truthy' );

    my $got = ${ $decoder->give($bad_utf8) };

    ok( utf8::is_utf8($got), 'UTF8 flag is set' );
    ok( !utf8::valid($got), '… but the actual value is invalid UTF-8' );
}

sub _cmpbin {
    my ($got, $expect, $label) = @_;

    $_ = sprintf('%v.02x', $_) for ($got, $expect);

    return is( $got, $expect, $label );
}

1;
