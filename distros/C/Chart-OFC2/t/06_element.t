#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 3;
use Test::Differences;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    use_ok ( 'Chart::OFC2::Element' ) or exit;
}

exit main();

sub main {
    my $element = Chart::OFC2::Element->new(
        'type_name' => 'bar',
        'values'    => [ 3,2,1,4,5 ],
    );
    
    eq_or_diff(
        $element->TO_JSON,
        {
            'type'   => 'bar',
            'values' => [ 3,2,1,4,5 ],
        },
        'element create'
    );
    
    eq_or_diff(
        $element->extremes->TO_JSON,
        {
            'x_axis_max' => undef,
            'x_axis_min' => undef, 
            'y_axis_max' => 5,
            'y_axis_min' => 1,
            'other'      => undef,
        },
        'extremes set'
    );
    
    return 0;
}
