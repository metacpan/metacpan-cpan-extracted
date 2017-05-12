package Alzabo::Display::SWF::Util;

use strict;
use warnings;
use base qw/Exporter/;

use SWF::Shape;
our $VERSION = '0.01';
our @EXPORT_OK = qw/rgb2ary button_shape get_coordinates/;

sub rgb2ary {
  local $_ = shift;
  my $h = '[0-9A-F]';
  /^x($h$h)($h$h)($h$h)$/ or die "Wrong RGB Color Specification $_!";
  my @r = map hex, $1, $2, $3;
  return @r;
}

sub button_shape {
  my $bs = new SWF::Shape;
  my $w = $_[0] + 2;
  $bs->setLeftFill($bs->addFill(@_[1..3]));
  $bs->movePenTo(0, 0);
  $bs->drawLine(0, 16);
  $bs->drawLine($w, 0);
  $bs->drawLine(0, -16);
  $bs->drawLine(-$w, 0);
  return $bs;
}

sub get_coordinates {
  my ($t, $x, $y) = @_;
  my (@p, $x0, $y0);
  my $min = 99;
  my $e = 3;
  for my $w ( 0 - $e .. $t->{width} + $e ) {
    push @p, [ $t->{dx} + $w, $t->{dy} - $e                ];
    push @p, [ $t->{dx} + $w, $t->{dy} + $t->{height} + $e ];
  }
  for my $h ( 1 - $e .. $t->{height} - 1 + $e ) {
    push @p, [ $t->{dx} - $e              , $t->{dy} + $h ];
    push @p, [ $t->{dx} + $t->{width} + $e, $t->{dy} + $h ];
  }
  for my $p ( @p ) {
    my $d = sqrt( ($p->[0] - $x)**2 + ($p->[1] - $y)**2 );
    if ( $d < $min ) {
      $x0 = $p->[0];
      $y0 = $p->[1];
      $min = $d;
    }
  }
  return ($x0, $y0);
}

1;
