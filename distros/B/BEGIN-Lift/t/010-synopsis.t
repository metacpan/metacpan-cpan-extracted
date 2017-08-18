#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    package Cariboo;
    use strict;
    use warnings;

    use BEGIN::Lift;

    sub import {
        my $caller = caller;

        BEGIN::Lift::install(
            ($caller, 'extends') => sub {
                no strict 'refs';
                @{$caller . '::ISA'} = @_;
            }
        );
    }
}

our $EXCEPTION;
BEGIN {
    eval q{
        package Bar;
        use strict; use warnings;

        package Foo;
        use strict; use warnings;
        BEGIN { Cariboo->import() }

        extends 'Bar';
        1;
    } or do {
        $EXCEPTION = "$@";
    };
    is($EXCEPTION, undef, '... got no error (as expected)');
    is_deeply(\@Foo::ISA, [ 'Bar' ], '... and Foo::ISA was altered as expected');
}

done_testing;

1;

