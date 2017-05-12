#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

our $TEST;
BEGIN {
    use_ok('BEGIN::Lift');

    $TEST = 0;

    BEGIN::Lift::install(
        ('main', 'double') => sub { $TEST = $_[0] * 2; $TEST }
    );
}

our $EXCEPTION;
BEGIN {
    eval q{
        my $x = double(10);
        ok(not(defined($x)), '... there is no value for $x');
        1;
    } or do {
        $EXCEPTION = "$@";
    };
    is($TEST, 20, '... got the value from double()');
    is($EXCEPTION, undef, '... got no error (as expected)');
}

done_testing;

1;
