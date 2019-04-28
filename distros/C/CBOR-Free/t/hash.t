#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Data::Dumper;

use_ok('CBOR::Free');

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

#----------------------------------------------------------------------

my @canonical_tests = (
    [
        { a => 1, aa => 4, b => 7, c => 8 },
        "\xa4 \x41a \x01 \x41b \x07 \x41c \x08 \x42aa \x04",
    ],
    [
        { "\0" => 0, "\0\0" => 0, "a\0a" => 0, "a\0b" => 1, },
        "\xa4 \x41\0 \0 \x42\0\0 \0 \x43a\0a \0 \x43a\0b \1",
    ],
);

$_->[1] =~ s< ><>g for @canonical_tests;

for my $t (@canonical_tests) {
    my ($in, $enc) = @$t;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Indent = 0;

    _cmpbin( CBOR::Free::encode($in, canonical => 1), $enc, "Encode canonical: " . Dumper($in) );
}

#----------------------------------------------------------------------

sub _cmpbin {
    my ($got, $expect, $label) = @_;

    $_ = sprintf('%v.02x', $_) for ($got, $expect);

    return is( $got, $expect, $label );
}

done_testing;
