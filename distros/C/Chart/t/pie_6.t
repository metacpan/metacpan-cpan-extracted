#!/usr/bin/perl -w
use Chart::Pie;

print "1..1\n";

$g = Chart::Pie->new( 500, 400 );

#$g = Chart::Pie->new;

$g->add_dataset( 'Free', 'Reserved', 'Deactivated', 'Leased', 'Unavailable' );
$g->add_dataset( 90,     0,          1,             216,      0 );

%opt = (
    'label_values'        => 'none',
    'legend_label_values' => 'both',
    'legend'              => 'right',
    'text_space'          => 10,
    'png_border'          => 1,
    'graph_border'        => 0,
    'grey_background'     => 'false',
    'x_label'             => 'Total IPs In Scope 253',
);

$g->set(%opt);

$g->png("samples/pie_6.png");

print "ok 1\n";
exit(0);
