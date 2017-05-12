# Copyright 2006, 2007, 2009, 2010, 2014 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Series::Derived::PFE;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::EMA;


# http://transcripts.fxstreet.com/2005/09/polarized_fract.html
#     Presentation on use.
#
# http://trader.online.pl/MSZ/e-w-Polarized_Fractal_Efficiency.html
#     Mov(If(C, >, Ref(C,-9),
#     	    Sqr(Pwr(Roc(C,9,$),2) + Pwr(10,2))
#     	      / Sum(Sqr( Pwr(Roc(C,1,$),2) + 1), 9),
#          -Sqr(Pwr(Roc(C,9,$),2) + Pwr(10,2))
#            / Sum(Sqr( Pwr(Roc(C,1,$),2) + 1), 9))
#         *100, 5, E)
#
# http://www.traderslog.com/polarized-fractal-efficiency.htm
#     Sample chart of IBM from 2002.  Year not shown, but data is 2002.
#     Seems based on ROC as percentage, day step as 1 in hypot, and 5-day
#     EMA smooth.
#
# http://store.traders.com/-v12-c01-polariz-pdf.html
#     TASC article for sale.
#

sub longname   { __('PFE - Polarized Fractal Efficiency') }
sub shortname  { __('PFE') }
sub manual     { __p('manual-node','Polarized Fractal Efficiency') }

use constant
  { type       => 'indicator',
    units      => 'percentage_plus_or_minus_100',
    minimum    => -100,
    maximum    => 100,
    hlines     => [ 0 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'pfe_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 10 },
                        { name     => __('Smooth'),
                          key      => 'pfe_smooth_days',
                          type     => 'float',
                          minimum  => 0,
                          default  => 5,
                          decimals => 0,
                          step     => 1 }],
  };

sub new {
  my ($class, $parent, $N, $smooth_N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N >= 1) || croak "PFE bad N: $N";

  $smooth_N //= parameter_info()->[1]->{'default'};
  ($smooth_N >= 0) || croak "PFE bad smooth: $smooth_N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N, $smooth_N ],
     arrays     => { values => [] });
}
sub warmup_count {
  my ($class_or_self, $N, $smooth_N) = @_;
  return $N-1 + App::Chart::Series::Derived::EMA->warmup_count($N);
}

# hypot(r,e)
# h = sqrt(r^2 + e^2)
# d = sqrt(r^2 + e^2) - r
# d+r = sqrt(r^2 + e^2)
# d^2 + 2dr + r^2 = r^2 + e^2
# d^2 + 2dr = e^2
# d^2 + 2dr - e^2 = 0
# d = (-2r +/- sqrt(4r^2 + 4e^2) ) / 2
# d = -r +/- sqrt(r^2 + e^2)

sub proc {
  my ($class_or_self, $N, $smooth_N) = @_;

  # input is how many days, decrement to get how many differences ... is
  # that right?
  $N--;

  my @values; # previous $N many values
  my $sum_proc = App::Chart::Series::Calculation->sum($N);
  my $ema_proc = App::Chart::Series::Derived::EMA->proc($smooth_N);

  return sub {
    my ($value) = @_;
    my $pfe;

    if (@values) {
      my $prevN = $values[-1];
      my $rocN = ($prevN == 0 ? 0 : 100 * ($value - $prevN) / $prevN);

      my $prev1 = $values[0];
      my $roc1 = ($prev1 == 0 ? 0
                  : 100 * ($value - $prev1) / $prev1);
      my $sum = $sum_proc->(_hypot($roc1,1));

      my $raw = ($sum == 0 ? 0
                 : 100 * _hypot($rocN,scalar @values) / $sum);
      if ($rocN < 0) { $raw = -$raw; }
      $pfe = $ema_proc->($raw);
    }
    unshift @values, $value;
    if (@values > $N) { pop @values }

    return $pfe;
  };
}

# could use Math::Libm hypot() here for a touch more accuracy, but not sure
# how good its portability is on non-Unix systems
sub _hypot {
  my ($x,$y) = @_;
  return sqrt($x*$x + $y*$y);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::PFE -- polarized fractal efficiency (PFE) indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->PFE($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>
# 
# =cut
