#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 24;
use Test::Differences;
use Test::Exception;

use JSON::XS;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    use_ok ( 'Chart::OFC2::Axis' ) or exit;
}

exit main();

sub main {
    my %x_axis_attributes = (
        stroke      => 10,
        colour      => 'red',
        tick_height => 3,
        grid_colour => 'black',
        offset      => 1,
        steps       => 11,
        is3d        => 1,
        labels      => [ qw( a b c d ) ],
    );
    my %y_axis_attributes = (
        stroke      => 10,
        color       => 'red',
        tick_length => 3,
        grid_colour => 'black',
        offset      => 1,
        steps       => 11,
        is3d        => 1,
        labels      => { 
            labels => [ qw( a b c d ) ],
        },
    );
    
    my $x_axis   = Chart::OFC2::XAxis->new(%x_axis_attributes);
    my $y_axis   = Chart::OFC2::YAxis->new(%y_axis_attributes);
    my $y_axis_r = Chart::OFC2::YAxisRight->new();
    isa_ok($x_axis, 'Chart::OFC2::Axis');
    isa_ok($y_axis, 'Chart::OFC2::Axis');
    isa_ok($y_axis_r, 'Chart::OFC2::Axis');
    isa_ok($x_axis, 'Chart::OFC2::XAxis');
    isa_ok($y_axis, 'Chart::OFC2::YAxis');
    isa_ok($y_axis_r, 'Chart::OFC2::YAxis');
    isa_ok($y_axis_r, 'Chart::OFC2::YAxisRight');
    
    is($x_axis->name, 'x_axis', 'check default name');
    is($y_axis->name, 'y_axis', 'check default name');
    is($y_axis_r->name, 'y_axis_right', 'check default name');
    is($x_axis->color, $x_axis_attributes{colour}, 'check color() accessor aliases colour() accessor');
    is($y_axis->grid_color, $y_axis_attributes{grid_colour}, 'check grid_color() accessor aliases grid_colour() accessor');
    is($y_axis->colour, $y_axis_attributes{color}, 'check color parameter to Chart::OFC2::Axis::new() can be used to initialize colour attribute.');

    $y_axis_attributes{colour} = delete $y_axis_attributes{color};

    eq_or_diff(
        $x_axis->TO_JSON,
        {
            map { $_ eq 'is3d' ? '3d' : $_ }
            %x_axis_attributes, labels => bless({ labels => [ qw( a b c d ) ] }, 'Chart::OFC2::Labels')
        },
        'x axis hash encoding'
    );
    
    eq_or_diff(
        $y_axis->TO_JSON,
        {
            map { $_ eq 'is3d' ? '3d' : $_ }
            %y_axis_attributes, labels => bless({ labels => [ qw( a b c d ) ] }, 'Chart::OFC2::Labels'),
        },
        'y axis hash encoding'
    );
    
    eq_or_diff(
        $y_axis->labels->TO_JSON,
        { labels => [ qw( a b c d ) ], },
        'y axis labels'
    );
    
    $y_axis->labels->rotate(45);
    eq_or_diff(
        $y_axis->labels->TO_JSON,
        { labels => [ qw( a b c d ) ], rotate => 45, },
        'y axis labels (rotated)'
    );

    $x_axis->color('blue');
    $y_axis->grid_color('orange');

    is($x_axis->colour, 'blue',        'check color() modifier aliases colour() modifier');
    is($y_axis->grid_colour, 'orange', 'check grid_color() modifier aliases grid_colour() modifier');
    
    # test steps constrain
    lives_ok { $y_axis->steps(5); } 'axis steps 5 is ok';
    dies_ok { $y_axis->steps(-5) }  'check that using steps() modifier to set steps to a negative value will fail';
    dies_ok { $y_axis->steps(0) }   'check that using steps() modifier to set steps to a zero will fail';
    dies_ok { $y_axis->steps(1.5) } 'check that using steps() modifier to set steps to a non-integer will fail';

    return 0;
}
