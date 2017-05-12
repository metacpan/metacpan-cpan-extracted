#!/usr/bin/perl -w

use Chart::Pie;
use strict;

print "1..1\n";

my $g = Chart::Pie->new( 550, 500 );
$g->add_dataset( 'eins', 'zwei', 'drei', 'vier' );
$g->add_dataset( 0,      0,      0,      0 );

$g->set( 'title'               => 'Pie Demo Chart' );
$g->set( 'sub_title'           => 'Only a circle, as all values are zero' );
$g->set( 'label_values'        => 'percent' );
$g->set( 'legend_label_values' => 'value' );
$g->set( 'legend'              => 'bottom' );
$g->set( 'grey_background'     => 'false' );
$g->set( 'legend_lines'        => 'false' );

$g->png("samples/pie_9.png");
print "ok 1\n";

exit(0);

