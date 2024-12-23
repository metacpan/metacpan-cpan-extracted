#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 10;

use Test::Exception;

use Carp::Assert::More;

MAIN: {
    my @false_values = (
        '',
        0,
        undef,
    );
    my @true_values = (
        1,
        14,
        '00',
        ' ',
        [],
        {},
        'foo',
    );

    for my $val ( @false_values ) {
        throws_ok( sub { assert( $val ) }, qr/^Assertion failed/, 'Val: ' . ($val // 'undef') );
    }

    for my $val ( @true_values ) {
        lives_ok( sub { assert( $val ) }, "Val: $val" );
    }
}


exit 0;
