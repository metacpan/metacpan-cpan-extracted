#!/usr/bin/env perl
use warnings;
use strict;

# Test that using the module doesn't break normal use of glob

use Test::More tests => 6;

use Acme::Globule qw( Range );

sub my_keys(\%) {
    my @hash = %{ $_[0] };
    return @hash[ glob("0,2..$#hash") ];
}

sub my_values(\%) {
    my @hash = %{ $_[0] };
    return @hash[ glob("1,3..$#hash") ];
}

my %hash = ( 1..20 );

is_deeply( [ my_keys %hash ], [ keys %hash ], 'my_keys works');
is_deeply( [ my_values %hash ], [ values %hash ], 'my_values works');

%hash = (1, 2);

is_deeply( [ my_keys %hash ], [ keys %hash ], 'my_keys works');
is_deeply( [ my_values %hash ], [ values %hash ], 'my_values works');

%hash = ();

is_deeply( [ my_keys %hash ], [ keys %hash ], 'my_keys works');
is_deeply( [ my_values %hash ], [ values %hash ], 'my_values works');

