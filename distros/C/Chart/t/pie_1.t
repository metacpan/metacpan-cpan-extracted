#!/usr/bin/perl -w

BEGIN { unshift @INC, 'lib', '../lib'}
use Chart::Pie;
use strict;
use File::Temp 0.19;
my $samples = File::Temp->newdir();

print "1..1\n";

my $g = Chart::Pie->new( 550, 500 );
$g->add_dataset( 'The Red', 'The Black', 'The Yellow', 'The Brown', 'The Green' );
$g->add_dataset( 430,       411,         50,           10,          100 );

$g->set( 'title'               => 'The Parlament' );
$g->set( 'label_values'        => 'percent' );
$g->set( 'legend_label_values' => 'value' );
$g->set( 'legend'              => 'top' );
$g->set( 'grey_background'     => 'false' );
$g->set( 'x_label'             => 'seats in the parlament' );
$g->set(
    'colors' => {
        'misc'       => 'light_blue',
        'background' => 'lavender',
        'dataset0'   => 'red',
        'dataset1'   => 'black',
        'dataset2'   => [ 210, 210, 0 ],
        'dataset3'   => 'DarkOrange',
        'dataset4'   => 'green'
    }
);
$g->set( 'legend_lines' => 'true' );

$g->png("$samples/pie_1.png");
print "ok 1\n";

exit(0);

