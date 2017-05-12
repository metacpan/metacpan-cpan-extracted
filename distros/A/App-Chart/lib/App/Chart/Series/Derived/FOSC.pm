# Copyright 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::FOSC;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::SMA;

# http://store.traders.com/-v10-c05-forcast-pdf.html
#     Abstract of TASC May 1992 article, rest for sale.
#
# http://trader.online.pl/MSZ/e-w-Chandes_Forecast_Oscillator_I.html
#     Formula, text of TASC article.
#
# http://www.fmlabs.com/reference/ForecastOscillator.htm
#
# https://www.stockworm.com/do/community/manual;jsessionid=8F865CC4F15C7E055E0A62A865AF7415?chapter=forecast-oscillator
#     Sample Oracle (ORCL), year not marked but is 2003.
#
# http://www.prophet.net/analyze/popglossary.jsp?studyid=FOSC
#     Sample chart of Peoplesoft (symbol PSFT maybe, since taken over).
#
# http://www.paritech.com/paritech-site/education/technical/indicators/trend/forecast.asp
#     Sample chart of Dollar Sweets, Australia (delisted after a takeover a
#     long time ago ... what symbol was it?).
#
# http://trader.online.pl/MSZ/e-st-Forecast_Oscillator.html
#     Trading system by Steve Karnish.
#


sub longname  { __('Forecast Oscillator %F') }
sub shortname { __('FOSC') }
sub manual    { __p('manual-node','Forecast Oscillator') }

use constant
  { type       => 'indicator',
    units      => 'roc_percent',
    priority   => -10,
    hlines     => [ 0 ],
    minimum    => 0,
    parameter_info => [ { name    => __('Days'),
                          key     => 'forecastosc_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 5 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "FOSC bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count; # $N-1

sub proc {
  my ($class, $N) = @_;
  my $linreg_proc = App::Chart::Series::Calculation->linreg($N);
  my $prev;
  return sub {
    my ($value) = @_;
    my $fosc;
    if (defined $prev) {
      my ($a, $b) = $linreg_proc->($prev);
      if ($value != 0) {
        # $a is for prev point, $a+$b is forecast for today
        $fosc = 100.0 * ($value - ($a + $b)) / $value;
      }
    }
    $prev = $value;
    return $fosc;
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::FOSC -- forecast oscillator (FOSC)
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->FOSC($N);
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
