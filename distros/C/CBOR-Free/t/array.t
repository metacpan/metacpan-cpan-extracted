#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Data::Dumper;

use_ok('CBOR::Free');

my @tests = (
    [ [] => "\x80" ],
    [ [undef] => "\x81\xf6"],
    [ [undef, undef] => "\x82\xf6\xf6"],
    [ [undef, 1] => "\x82\xf6\x01" ],
    [ [undef, [65536]] => "\x82\xf6\x81\x1a\0\1\0\0" ],
);

for my $t (@tests) {
    my ($in, $enc) = @$t;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Indent = 0;

    _cmpbin( CBOR::Free::encode($in), $enc, "Encode: " . Dumper($in) );
}

sub _cmpbin {
    my ($got, $expect, $label) = @_;

    $_ = sprintf('%v.02x', $_) for ($got, $expect);

    return is( $got, $expect, $label );
}

done_testing;
