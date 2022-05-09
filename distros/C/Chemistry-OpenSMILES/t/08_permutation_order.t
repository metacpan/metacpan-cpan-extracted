#!/usr/bin/perl

use strict;
use warnings;

use Chemistry::OpenSMILES::Writer;
use Test::More;

sub order
{
    return join '', Chemistry::OpenSMILES::Writer::_permutation_order( @_ );
}

my $random_cases = 20;
my @bad_cases = (
    [ 0..2 ],
    [ 0..4 ],
    [ 1..4 ],
    [ 0..2, undef ],
    [ 0, 1, 12, '' ],
);

plan tests => $random_cases + (2 * scalar @bad_cases);

for (1..$random_cases) {
    my @order = 0..3;
    for (0..9) {
        if( rand() < 0.5 ) {
            @order = ( @order[1..2], $order[0], $order[3] );
        } else {
            @order = ( $order[0], @order[2..3], $order[1] );
        }
    }
    is( order( @order ), '0123' );
}

for (@bad_cases) {
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };

    is( order( @$_ ), '0123' );
    ok( defined $warning && $warning =~ /unexpected input received/ );
}
