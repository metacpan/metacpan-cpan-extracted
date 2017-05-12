use strict;
use warnings;
use lib 'lib';
use Astro::SkyPlot qw/:all/;

foreach my $projection (qw/hammer sinusoidal miller/) {
  my $sp = Astro::SkyPlot->new(projection => $projection);
  $sp->write(file => "$projection.eps");
}

