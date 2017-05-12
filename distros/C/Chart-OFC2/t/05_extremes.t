#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 5;
use Test::Differences;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    use_ok ( 'Chart::OFC2::Extremes' ) or exit;
}

exit main();

sub main {
    my $extremes = Chart::OFC2::Extremes->new();
    
    eq_or_diff(
        $extremes->TO_JSON,
        {
            'x_axis_max' => undef,
            'x_axis_min' => undef, 
            'y_axis_max' => undef,
            'y_axis_min' => undef,
            'other'      => undef,
        },
        'all undef in the beginning'
    );
    
    $extremes->reset('x' => [ 1, 2, 3, 4, 5, ]);
    $extremes->reset('y' => [ 3, ]);
    
    eq_or_diff(
        $extremes->TO_JSON,
        {
            'x_axis_max' => 5,
            'x_axis_min' => 1, 
            'y_axis_max' => 3,
            'y_axis_min' => 3,
            'other'      => undef,
        },
        'x/y now set'
    );

    $extremes->reset('x' => [ undef,undef,6,3,0, ]);
    $extremes->reset('y' => [ undef,undef,100,100.5, ]);

    eq_or_diff(
        $extremes->TO_JSON,
        {
            'x_axis_max' => 6,
            'x_axis_min' => 0, 
            'y_axis_max' => 100.5,
            'y_axis_min' => 100,
            'other'      => undef,
        },
        'x/y set again'
    );
    
    $extremes->reset('x' => [ undef,undef,[ 1,2,undef,5,-1,3 ],3,0, ]);
    $extremes->reset('y' => [ undef,undef,100,100.5, [ [ undef ], [ 99 ], [ 101 ] ], ]);

    eq_or_diff(
        $extremes->TO_JSON,
        {
            'x_axis_max' => 5,
            'x_axis_min' => -1, 
            'y_axis_max' => 101,
            'y_axis_min' => 99,
            'other'      => undef,
        },
        'x/y extremes in arrays of arrays'
    );
    
    return 0;
}
