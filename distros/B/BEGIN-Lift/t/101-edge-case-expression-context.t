#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('BEGIN::Lift');

    BEGIN::Lift::install(
        ('main', 'double') => sub { $_[0] * 2 }
    );
}

our $EXCEPTION;
BEGIN {
    eval q{
        if ( double(10) && 100 ) {
            fail('... this should never happen since double() evals to undef at runtime');
        }
        1;
    } or do {
        $EXCEPTION = "$@";
    };
    is($EXCEPTION, undef, '... got no error (as expected)');
}

done_testing;

1;
