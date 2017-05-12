#!/usr/bin/perl -w

use Chart::Pie;
use strict;

print "1..1\n";

my $g = Chart::Pie->new( 450, 450 );
$g->add_dataset( 'HOST A', 'HOST B', 'HOST C', 'HOST D', 'HOST E', 'HOST F' );
$g->add_dataset( 5,        2,        1,        2,        9,        12 );

$g->set( 'title'               => 'Total Access Attempts' );
$g->set( 'label_values'        => 'value' );
$g->set( 'legend_label_values' => 'percent' );
$g->set( 'legend'              => 'bottom' );
$g->set( 'grey_background'     => 'true' );
$g->set( 'legend_lines'        => 'true' );

$g->png("samples/pie_11.png");
print "ok 1\n";

exit(0);

