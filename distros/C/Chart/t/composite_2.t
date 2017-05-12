#!/usr/bin/perl -w

use strict;
use Chart::Composite;

print "1..1\n";

my ($g) = Chart::Composite->new( 788, 435 );

# 0 = X-Achse
$g->add_dataset( '0:00', '1:00', '2:00', '3:00', '4:00', '5:00', '6:00', '7:00', '8:00', '9:00', '10:00', '11:00' );

# 1 = BZ-Werte - linie
$g->add_dataset( 222, 211, 306, 175, 216, 216, 168, 161, 153, 170, 92, 134 );

# 2 = Basas - stacked bar
$g->add_dataset( 0.8, 0.8, 0.9, 1.1, 1.8, 2.1, 1.8, 1.4, 1.0, 1.0, 1.0, 1.0 );

# 3 = Bolus - stacked bar
$g->add_dataset( 4.4, 1.8, 6.5, 5.6, 2.4, 4.7, 6.0, 5.4, 8.9, 9.5, 8.7, 9.2 );

# 4 = KHE - stacked bar
$g->add_dataset( 3.0, 2.8, 2.5, 0.6, 2.4, 4.7, 5.0, 5.4, 1.9, 3.5, 4.7, 3.2 );

$g->set( 'composite_info' => [ [ 'StackedBars', [ 2, 3, 4 ] ], [ 'Lines', [1] ] ] );

$g->set(
    'legend_labels'       => [ 'BZ', 'KHE', 'Bolus', 'Basal' ],
    'legend'              => 'bottom',
    'title'               => '',
    'precision'           => 0,
    'spaced_bars'         => 'false',
    'include_zero'        => 'true',
    'legend_example_size' => 100,
    'skip_int_ticks'      => 3,
    'min_val2'            => 0,

    #'max_val2'       => 400,
    'legend_example_height'     => 'true',
    'legend_example_height0..2' => 10,                 # Reihenfolge durch composite info
    'legend_example_height3'    => 2,
    'y_label'                   => 'IE/KHE',
    'y_label2'                  => 'mg/dl (mmol/l)',
    'grey_background'           => 'false',
);

$g->set(
    'colors' => {
        'y_label'  => [ 51,  255, 0 ],
        'y_label2' => [ 255, 0,   0 ],
        'dataset2' => [ 0,   0,   244 ],               # Reihenfolge durch composite info!!!
        'dataset1' => [ 0,   204, 0 ],
        'dataset0' => [ 255, 255, 51 ],
        'dataset3' => [ 204, 0,   0 ],

    }
);

$g->set( 'f_y_tick' => sub { return ( $_[0] . '(' . sprintf( "%.1f", $_[0] / 18.0182 ) . ')' ) } );

$g->png("samples/composite_2.png");

print "ok 1\n";

exit 0;
