use strict;
use warnings;
use lib 'lib';
use Astro::SkyPlot qw/:all/;

my $sp = Astro::SkyPlot->new();

$sp->plot_lat_long(0, 0, size => .5);
$sp->plot_lat_long(0.1, 0, size => .5, marker => MARK_CIRCLE);
$sp->plot_lat_long(0.2, 0, size => .5, marker => MARK_BOX);
$sp->plot_lat_long(0.3, 0, size => .5, marker => MARK_BOX_FILLED);
$sp->plot_lat_long(0, 0.1, size => .5, marker => MARK_TRIANGLE);
$sp->plot_lat_long(0.1, 0.1, size => .5, marker => MARK_TRIANGLE_FILLED);
$sp->plot_lat_long(0.2, 0.1, size => .5, marker => MARK_DTRIANGLE);
$sp->plot_lat_long(0.3, 0.1, size => .5, marker => MARK_DTRIANGLE_FILLED);
$sp->plot_lat_long(0, 0.2, size => .5, marker => MARK_CROSS);
$sp->plot_lat_long(0.1, 0.2, size => .5, marker => MARK_DIAG_CROSS);
$sp->write(file => "markers.eps");

