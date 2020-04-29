#!/usr/bin/env perl

package t::hash;

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;
use Test::Exception;

use parent qw( Test::Class::Tiny );

use Data::Dumper;

use CBOR::Free;

__PACKAGE__->runtests() if !caller;

sub T3_basic {
    my @tests = (
        [ {} => "\xa0" ],
        [ { a => 12 } => "\xa1\x41\x61\x0c"],
        [ { a => [12] } => "\xa1\x41\x61\x81\x0c"],
    );

    for my $t (@tests) {
        my ($in, $enc) = @$t;

        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Useqq = 1;
        local $Data::Dumper::Indent = 0;

        _cmpbin( CBOR::Free::encode($in), $enc, "Encode: " . Dumper($in) );
    }
}

sub T1_many_keys {
    my %hash = map { $_ => 1 } 1 .. 1256;

    my $as_cbor = CBOR::Free::encode(\%hash);

    my $rt = CBOR::Free::decode($as_cbor);

    is_deeply( $rt, \%hash, '%Config-sized hash round trips' );
}

#----------------------------------------------------------------------

sub T6_canonical {
    my $a_upgraded = "0";
    utf8::upgrade($a_upgraded);

    my $b_upgraded = "1";
    utf8::upgrade($b_upgraded);

    my @canonical_tests = (
        [
            { a => 1, aa => 4, b => 7, c => 8 },
            "\xa4 \x41a \x01 \x41b \x07 \x41c \x08 \x42aa \x04",
        ],
        [
            { "\0" => 0, "\0\0" => 0, "a\0a" => 0, "a\0b" => 1, },
            "\xa4 \x41\0 \0 \x42\0\0 \0 \x43a\0a \0 \x43a\0b \1",
        ],
        [
            { q<x> => 1, "y" => 2, "z" => 3,
                $a_upgraded => 4, $b_upgraded => 5,
            },
            "\xa5 \x41x \1 \x41y \2 \x41z \3 \x61 0 \4 \x61 1 \5",
        ],
    );

    $_->[1] =~ s< ><>g for @canonical_tests;

    for my $t (@canonical_tests) {
        my ($in, $enc) = @$t;

        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Useqq = 1;
        local $Data::Dumper::Indent = 0;

        _cmpbin( CBOR::Free::encode($in, canonical => 1), $enc, "Encode canonical (first arg): " . Dumper($in) );

        _cmpbin( CBOR::Free::encode($in, scalar_references => 0, canonical => 1), $enc, "Encode canonical (later arg): " . Dumper($in) );
    }
}

#----------------------------------------------------------------------

sub T2_text_key {
    my $hash_w_text_key = { "\x{100}" => '123' };
    my $cbor = CBOR::Free::encode($hash_w_text_key);

    is(
        $cbor,
        "\xa1\x62\xc4\x80C123",
        'hash w/ text key encoded as expected',
    ) or diag explain sprintf('%v.02x', $cbor);

    my $decoded = CBOR::Free::decode("$cbor");

    is(
        ord( (keys %$decoded)[0] ),
        256,
        'decoded map’s key is decoded correctly',
    );
}

sub T4_invalid_text_key {
    my $cbor = "\xa1\x63\0\xff\x80C123";

    throws_ok(
        sub { CBOR::Free::decode("$cbor") },
        'CBOR::Free::X::InvalidUTF8',
        'die() on normal attempt to decode invalid-UTF8 text map key',
    );

    my $str = "$@";
    like($str, qr<\\x00\\xff\\x80(?!=C)>, 'string is hex-escaped as part of error' );

    require CBOR::Free::Decoder;
    my $decoder = CBOR::Free::Decoder->new();
    $decoder->naive_utf8();
    my $dec_hr = $decoder->decode("$cbor");

    ok( utf8::is_utf8( (keys %$dec_hr)[0] ), 'UTF8 flag is set on invalid hash key' );
    ok( !utf8::valid( (keys %$dec_hr)[0] ), '… but the actual value is invalid UTF-8' );
}

sub T2_invalid_map_key__float {
    my $cbor_float = CBOR::Free::encode( 1.1 );
    my $cbor = "\xa2\x41a\x41z$cbor_float\x43abc";

    throws_ok(
        sub { CBOR::Free::decode($cbor) },
        'CBOR::Free::X::InvalidMapKey',
        'reject float as map key',
    );

    my $err = $@;

    cmp_deeply(
        $err,
        all(
            re( qr<double float> ),
            re( qr<5> ),
        ),
        '… with the expected error message',
    );
}

#----------------------------------------------------------------------

sub T1_decoded_high_bit_key {
    my $eacute_utf8 = "é";

    my $eacute = $eacute_utf8;
    utf8::decode($eacute);

    my $cbor = CBOR::Free::encode( { $eacute => 1 } );

    _cmpbin(
        $cbor,
        "\xa1" . "\x62$eacute_utf8" . "\1",
        'decoded UTF-8 e-acute encodes correctly',
    );
}

sub _cmpbin {
    my ($got, $expect, $label) = @_;

    $_ = sprintf('%v.02x', $_) for ($got, $expect);

    return is( $got, $expect, $label );
}
