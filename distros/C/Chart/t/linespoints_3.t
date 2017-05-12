#!/usr/bin/perl -w

use Chart::LinesPoints;
use strict;

print "1..1\n";

my ( @data1, @data2, @data4, @data3, @labels, %hash, $g, $hits );

@labels = qw(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17);
@data1  = qw (-7 -5 -6 -8 -9 -7 -5 -4 -3 -2 -4 -6 -3 -5 -3 -4 -6);
@data2  = qw (-1 -1 -1 -1 -2 -2 -3 -3 -4 -4 -6 -3 -2 -2 -2 -1 -1);
@data3  = qw (-4 -4 -3 -2 -1 -1 -1 -2 -1 -1 -3 -2 -4 -3 -4 -2 -2);
@data4  = qw (-6 -3 -2 -3 -3 -3 -2 -1 -2 -3 -1 -1 -1 -1 -1 -3 -3);

$g = Chart::LinesPoints->new( 600, 300 );
$g->add_dataset(@labels);
$g->add_dataset(@data1);
$g->add_dataset(@data2);
$g->add_dataset(@data3);
$g->add_dataset(@data4);

%hash = (
    'integer_ticks_only' => 'true',
    'title'              => 'Soccer Season 2002\n ',
    'legend_labels'      => [ 'NY Soccer Club', 'Denver Tigers', 'Houston Spacecats', 'Washington Presidents' ],
    'y_label'            => 'position in the table',
    'x_label'            => 'day of play',
    'grid_lines'         => 'true',
    'f_y_tick'           => \&formatter,
    'xy_plot'            => 'false',
);

$g->set(%hash);
$g->png("samples/linespoints_3.png");

#just a trick, to let the y scale start at the biggest point:
#initiate with negativ values, remove the minus sign!
sub formatter
{
    my $label = shift;
    $label = substr( $label, 1, 2 );
    return $label;
}
print "ok 1\n";

exit(0);

