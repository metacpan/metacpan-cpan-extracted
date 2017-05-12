#!/usr/bin/perl -w

# Difference to composite_7.t is:
# set(xy_plot => 1
# You will the difference in the plots!
#
use Chart::Composite;
use Chart::Lines;
use Chart::Points;
use Chart::LinesPoints;
use strict;

print "1..1\n";

my @y = qw( 2.6593 2.0832 2.0519 2.2257 2.4355 2.4183 3.4088 2.2899 2.4914
  2.3217 2.0684 2.1328 1.8168 1.7662 1.7592 1.8624 1.2614 );
my @x = qw(4757 14055 23004 29698 32172 31038 33068 33383 33941 32451 25235
  17035 12122 9868 6647 4024 944);
my @x2 = qw(1.706 1.756 1.807 1.858 1.909 1.959 2.010 2.061 2.112 2.162 2.213
  2.264 2.315 2.365 2.416 2.467 2.518);
my %hash = qw(precision 2 title red text blue include_zero true graph_border 0
  y_grid_lines true legend bottom y_axes both skip_x_ticks 1 brush_size 4
  brush_size1 4 brush_size2 3 no_cache true *xy_plot true*);
$hash{title} = "my title";
my $c = 0;
$hash{colors} = {
    'dataset0' => [ 255, 0,   0 ],
    'dataset1' => [ 0,   0,   255 ],
    'dataset2' => [ 173, 170, 61 ],
    'dataset3' => [ 242, 2,   249 ],
    'dataset4' => [ 254, 177, 192 ],
    'y_label'  => [ 0,   0,   0 ],
    'y_label2' => [ 173, 170, 61 ],
};
$hash{brushStyle1} = 'fatPlus';
$hash{brushStyle2} = 'hollowSquare';

my $g;
if (0)
{
    $g = Chart::Lines->new( 1000, 400 );
}
else
{
    $g = Chart::Composite->new( 1000, 400 );
    $g->set( 'composite_info' => [ [ 'Points', [1] ], [ 'LinesPoints', [2] ] ] );
}
my @s = sort { $x[$a] <=> $x[$b]; } 0 .. $#x;
$g->add_dataset( @x[@s] );
$g->add_dataset( @y[@s] );
$g->add_dataset(@x2);
$g->set(%hash);
$g->set( xy_plot => 1 );
$g->jpeg("samples/composite_8.jpg");

print "ok 1\n";

exit(0);

