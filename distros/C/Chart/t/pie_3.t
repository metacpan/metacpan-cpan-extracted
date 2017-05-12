#!/usr/bin/perl -w

use Chart::Pie;

print "1..1\n";

$g = Chart::Pie->new( 500, 500 );

$g->add_dataset( 'Har', 'Sug', 'Ert', 'Her', 'Tar', 'Kure' );
$g->add_dataset( 12000, 20000, 13000, 15000, 9000,  11000 );

%opt = (
    'title'        => 'Another Pie Demo Chart',
    'label_values' => 'both',
    'legend'       => 'none',
    'text_space'   => 10,
    'png_border'   => 1,
    'graph_border' => 0,
    'colors'       => {
        'x_label'    => 'red',
        'misc'       => 'plum',
        'background' => 'grey',
        'dataset0'   => [ 120, 0, 255 ],
        'dataset1'   => [ 120, 100, 255 ],
        'dataset2'   => [ 120, 200, 255 ],
        'dataset3'   => [ 255, 100, 0 ],
        'dataset4'   => [ 255, 50, 0 ],
        'dataset5'   => [ 255, 0, 0 ],
    },
    'x_label' => 'The Winner is Team Blue!',
);

$g->set(%opt);

$g->png("samples/pie_3.png");

print "ok 1\n";
exit(0);
