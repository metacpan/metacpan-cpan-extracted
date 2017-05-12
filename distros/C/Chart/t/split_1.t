#!/usr/bin/perl -w

use Chart::Split;
use strict;
print "1..1\n";

my ( $x, $y, @x, @y, %hash );
my $g = Chart::Split->new();

for ( my $i = 0 ; $i < 60 ; $i += .05 )
{
    $y = sin($i);
    $x = $i;
    push @x, $x;
    push @y, $y;
}

$g->add_dataset(@x);
$g->add_dataset(@y);

%hash = (
    'start'          => 0,
    'interval'       => 20,
    'interval_ticks' => 21,
    'brush_size'     => 1,
    'legend'         => 'none',
    'title'          => 'f(x) = sin x',
    'precision'      => 0,
    'y_grid_lines'   => 'true',

);
$g->set(%hash);

$g->png("samples/split_1.png");
print "ok 1\n";

exit(0);
