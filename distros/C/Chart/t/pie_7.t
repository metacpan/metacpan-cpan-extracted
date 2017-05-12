#!/usr/bin/perl -w

use Chart::Pie;
use GD;
use strict;

print "1..1\n";

my $g = Chart::Pie->new( 500, 450 );
$g->add_dataset( 'eins', 'zwei', 'drei', 'vier', 'fuenf', 'sechs', 'sieben', 'acht', 'neun', 'zehn' );
$g->add_dataset( 40,     1,      12,     37,     8,       50,      19,       23,     5,      90 );

$g->set( 'title'               => 'Pie\nDemo Chart' );
$g->set( 'sub_title'           => 'Ring_Pie' );
$g->set( 'label_values'        => 'value' );
$g->set( 'legend_label_values' => 'value' );
$g->set( 'legend'              => 'bottom' );
$g->set( 'x_label'             => '' );
$g->set( 'ring'                => 0.1 );
$g->set( 'colors'              => { 'background' => 'grey' } );

$g->png("samples/pie_7.png");
print "ok 1\n";

exit(0);

