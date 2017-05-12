#!/usr/bin/perl -w

use Chart::Pie;
use GD;
use strict;

print "1..1\n";

my $g = Chart::Pie->new( 500, 450 );
$g->add_dataset( 'eins', 'zwei', 'drei', 'vier', 'fuenf', 'sechs', 'sieben', 'acht', 'neun', 'zehn' );
$g->add_dataset( 120,    50,     100,    80,     40,      45,      150,      60,     110,    50 );

$g->set( 'title'               => 'Pie\nDemo Chart' );
$g->set( 'sub_title'           => 'True Type Fonts' );
$g->set( 'label_values'        => 'percent' );
$g->set( 'legend_label_values' => 'value' );
$g->set( 'legend'              => 'bottom' );
$g->set( 'grey_background'     => 'false' );
$g->set( 'x_label'             => '' );
$g->set( 'legend_font'         => gdSmallFont );
$g->set( 'title_font'          => gdGiantFont );
$g->set( 'legend_lines'        => 'false' );

$g->png("samples/pie_4.png");
print "ok 1\n";

exit(0);

