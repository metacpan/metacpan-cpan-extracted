#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('BEGIN::Lift');

    BEGIN::Lift::install(
        ('main', 'double') => sub {
            die('Died within (' . (caller(0))[3] . ')');
        }
    );
}

our $EXCEPTION;

BEGIN {
    eval q{
        double(10);
        1;
    } or do {
        $EXCEPTION = "$@";
    };
    like(
        $EXCEPTION,
        qr/Died within \(main\:\:double\)/,
        '... got the error expected'
    );
}

done_testing;

1;
