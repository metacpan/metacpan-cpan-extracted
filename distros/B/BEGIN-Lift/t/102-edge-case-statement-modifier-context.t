#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

our $TEST;
BEGIN {
    use_ok('BEGIN::Lift');

    $TEST = 0;
    BEGIN::Lift::install(
        ('main', 'test') => sub { $TEST = $_[0] }
    );
}

# MAYBE[FIXME]:
# I would actually prefer that we die here, but
# this is perhaps outside of my abilities as a
# core Perl hacker, so it can work (w/ caveat)
# for now.
# - SL

our $EXCEPTION;
BEGIN {
    eval q{
        test(10) if 0;
        1;
    } or do {
        $EXCEPTION = "$@";
    };

    is($TEST, 10, '... the statement modifier had no effect');
    is($EXCEPTION, undef, '... got no error (as expected)');
}

done_testing;

1;
