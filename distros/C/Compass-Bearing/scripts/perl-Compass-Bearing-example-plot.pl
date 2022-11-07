#!/usr/bin/perl
use strict;
use warnings;
use Compass::Bearing;
use GD::Graph::Polar;

=head1 NAME

perl-Compass-Bearing-example-plot.pl - Example for L<Compass::Bearing> with L<GD::Graph::Polar>

=cut

foreach my $digit (1 .. 3) {
  my $cb=Compass::Bearing->new($digit);
  my $count=scalar(@{$cb->data});
  my $gdgp=GD::Graph::Polar->new(size=>450, radius=>10, ticks=>1);

  foreach (1 .. $count) {
    my $angle=$_ * 360 / $count;
    $gdgp->addGeoLine(0=>$angle, 8=>$angle);
    $gdgp->addGeoPoint(8=>$angle);
    $gdgp->addGeoString(9=>$angle, $cb->bearing($angle));
  }

  open(IMG, ">Compass-Bearing-example-plot-$digit-digit.png");
  print IMG $gdgp->draw;
  close(IMG);
}
