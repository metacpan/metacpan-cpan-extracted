#!usr/bin/perl -w

use Chart::HorizontalBars;

print "1..1\n";

$g = Chart::HorizontalBars->new();
$g->add_dataset( 'Foo', 'bar', 'junk', 'ding', 'bat' );
$g->add_dataset( 4,     3,     4,      2,      8 );
$g->add_dataset( 2,     10,    3,      8,      3 );

%hash = (
    'title'        => 'Horizontal Bars Demo',
    'grid_lines'   => 'true',
    'x_label'      => 'x-axis',
    'y_label'      => 'y-axis',
    'include_zero' => 'true',
);

$g->set(%hash);
$g->png("samples/hbars_4.png");

print "ok 1\n";
exit(0);
