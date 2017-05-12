#!/usr/bin/perl -w

use Chart::Composite;
use strict;

print "1..1\n";

my $g = Chart::Composite->new;

$g->add_dataset( 1,   2,   3,   7,   5,   6 );
$g->add_dataset( 0.1, 0.2, 0.3, 0.2, 0.4, 0.1 );
$g->add_dataset( 0.3, 0.5, 0.2, 0.6, 0.7, 0.4 );
$g->add_dataset( 10,  11,  6,   7,   7,   8 );

$g->set(
    'title'          => 'Composite Chart',
    'composite_info' => [ [ 'Bars', [ 1, 2 ] ], [ 'LinesPoints', [3] ] ]
);
$g->set( 'include_zero'              => 'true' );
$g->set( 'legend'                    => 'top' );
$g->set( 'legend_example_height'     => 'true', );
$g->set( 'legend_example_height0..1' => '10' );
$g->set( 'legend_example_height2'    => '3' );
$g->set( 'f_y_tick'                  => \&multiply );
$g->set( 'f_x_tick'                  => \&int_quadrat );
$g->png("samples/composite_f.png");

print "ok 1\n";

exit(0);

sub multiply
{
    my $y = shift;

    return ( $y * 10 );
}

sub int_quadrat
{
    my $x = shift;
    return $x * $x;
}
