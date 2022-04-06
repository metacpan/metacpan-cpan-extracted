#!/usr/bin/perl -w

BEGIN { unshift @INC, 'lib', '../lib'}
use Chart::Pie;
use strict;
use File::Temp 0.19;
my $samples = File::Temp->newdir();

print "1..1\n";

my $g = Chart::Pie->new( 550, 500 );
$g->add_dataset( 'eins', 'zwei', 'drei', 'vier' );
$g->add_dataset( 25,     30,     250,    50 );

$g->set( 'title'               => 'Pie Demo Chart' );
$g->set( 'label_values'        => 'percent' );
$g->set( 'legend_label_values' => 'value' );
$g->set( 'legend'              => 'bottom' );
$g->set( 'grey_background'     => 'false' );
$g->set( 'x_label'             => '' );
$g->set(
    'colors' => {
        'misc'     => 'light_blue',
        'dataset1' => 'red',
        'dataset2' => 'blue',
        'dataset0' => 'yellow',
        'dataset3' => 'green'
    }
);

$g->png("$samples/pie_5.png");
print "ok 1\n";

exit(0);

