#!/usr/bin/env perl

package t::hash;

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

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

        _cmpbin( CBOR::Free::encode($in, hahaha => 0, canonical => 1), $enc, "Encode canonical (later arg): " . Dumper($in) );
    }
}

#----------------------------------------------------------------------

sub T1_text_key {
    my $hash_w_text_key = { "\x{100}" => '123' };
    my $cbor = CBOR::Free::encode($hash_w_text_key);

    is(
        $cbor,
        "\xa1\x62\xc4\x80C123",
        'hash w/ text key encoded as expected',
    ) or diag explain sprintf('%v.02x', $cbor);
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

sub T2_encode_text_keys__utf8_decode {
    my $eacute_utf8 = "é";

    my $cbor = CBOR::Free::encode( { $eacute_utf8 => 2 }, text_keys => 1 );

    _cmpbin(
        $cbor,
        "\xa1" . "\x64\xc3\x83\xc2\xa9" . "\2",
        'undecoded UTF-8',
    );

    my $eacute = $eacute_utf8;
    utf8::decode($eacute) or die "bad UTF-8??";

    $cbor = CBOR::Free::encode( { $eacute => 2 }, text_keys => 1 );

    _cmpbin(
        $cbor,
        "\xa1" . "\x62$eacute_utf8" . "\2",
        'decoded UTF-8',
    );
}

sub T2_encode_text_keys_canonical__utf8_decode {
    my $eacute_utf8 = "\xc3\xa9";

    my $cbor = CBOR::Free::encode( { $eacute_utf8 => 2 },
        canonical => 1,
        text_keys => 1,
    );

    _cmpbin(
        $cbor,
        "\xa1" . "\x64\xc3\x83\xc2\xa9" . "\2",
        'undecoded UTF-8',
    );

    my $eacute = $eacute_utf8;
    utf8::decode($eacute) or die "bad UTF-8??";

    $cbor = CBOR::Free::encode( { $eacute => 2 },
        canonical => 1,
        text_keys => 1,
    );

    _cmpbin(
        $cbor,
        "\xa1" . "\x62$eacute_utf8" . "\2",
        'decoded UTF-8',
    );
}

sub T4_encode_text_keys {
    my $cbor;

    my %simple = ( foo => 1 );
    $cbor = CBOR::Free::encode(
        \%simple,
        text_keys => 1,
    );

    _cmpbin(
        $cbor,
        "\xa1cfoo\1",
        'simple key',
    );

    #----------------------------------------------------------------------

    my %high_bit_char_code = ( "\xff" => 1 );
    $cbor = CBOR::Free::encode(
        \%high_bit_char_code,
        text_keys => 1,
    );

    my $utf8_255 = "\xff";
    utf8::encode($utf8_255);

    _cmpbin(
        $cbor,
        "\xa1" . "\x62$utf8_255" . "\1",
        'high-bit char code is converted to UTF-8',
    );

    #----------------------------------------------------------------------

    my %already_utf8 = ( "\x{100}" => 1 );

    $cbor = CBOR::Free::encode(
        \%already_utf8,
        text_keys => 1,
    );

    _cmpbin(
        $cbor,
        "\xa1\x62\xc4\x80\1",
        'high-charcode key',
    );

    my $bar_upgraded = "bar";
    utf8::upgrade($bar_upgraded);

    my %input = (
        foo => 1,
        $bar_upgraded => 2,
        q<> => 3,
        "\x{100}" => 4,
        "\xff" => 5,
    );

    $cbor = CBOR::Free::encode(
        \%input,
        canonical => 1,
        text_keys => 1,
    );

    _cmpbin(
        $cbor,
        "\xa5" . "\x60\3" . "\x62$utf8_255\5" . "\x62\xc4\x80\4" . "\x63bar\2" . "\x63foo\1",
        'w/ canonical flag',
    );
}

sub _cmpbin {
    my ($got, $expect, $label) = @_;

    $_ = sprintf('%v.02x', $_) for ($got, $expect);

    return is( $got, $expect, $label );
}
