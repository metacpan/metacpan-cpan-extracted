# Copyright 2006, 2007, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::FRAMA;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::KAMA;
use App::Chart::Series::Derived::FRAMAalpha;


# http://www.mesasoftware.com/technicalpapers.htm
# http://www.mesasoftware.com/Papers/FRAMA.pdf
#     John Ehler's paper on FRAMA.
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/102005/TradersTips/TradersTips.html
#     Traders Tips October 2005.
#
# http://trader.online.pl/MSZ/e-w-Moving_Average_Fractal_Adaptive_(FAMA).html
#
# http://www.tradingsolutions.com/download/tip0510.zip
#     Formulas.
#

sub longname   { __('FRAMA - Fractal Adaptive MA') }
sub shortname  { __('FRAMA') }
sub manual     { __p('manual-node','Fractal Adaptive Moving Average') }

use constant
  { type       => 'average',
    parameter_info => App::Chart::Series::Derived::FRAMAalpha::parameter_info(),
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}

sub warmup_count {
  my ($self_or_class, $N) = @_;
  # extreme worst case guess, ends up about $N+687
  return $N + App::Chart::Series::Derived::EMA->warmup_count
    (App::Chart::Series::Derived::EMA::alpha_to_N(0.01));
}
### FRAMA warmup_count(): __PACKAGE__->warmup_count(0)

sub warmup_count_for_position {
  my ($self, $lo) = @_;
  my $parent = $self->{'parent'};
  my $p = $parent->values_array;
  my $ph = $parent->array('highs') || $p;
  my $pl = $parent->array('lows') || $p;

  my $p_lo = $lo + 1; # initial fill
  my $chunk = 16;

  my $alpha_proc = App::Chart::Series::Derived::FRAMAalpha->proc(@{$self->{'parameters'}});
  my $alpha_warmup = App::Chart::Series::Derived::FRAMAalpha->warmup_count(@{$self->{'parameters'}});
  my $tail = 1;

  my $i = $lo;
  for ( ; $i >= 0; $i--) {
    if ($i < $p_lo) {
      my $new_p_lo = min ($i, $p_lo - $chunk);
      $chunk *= 2;
      $parent->fill ($new_p_lo, $i);
      $p_lo = $new_p_lo;
    }
    my $value = $p->[$i] // next;
    $alpha_proc->($ph->[$i], $pl->[$i], $value) // next;
    last if --$alpha_warmup <= 0;
  }
  for ( ; $i >= 0; $i--) {
    if ($i < $p_lo) {
      my $new_p_lo = min ($i, $p_lo - $chunk);
      $chunk *= 2;
      $parent->fill ($new_p_lo, $i);
      $p_lo = $new_p_lo;
    }
    my $value = $p->[$i] // next;
    my $alpha = $alpha_proc->($ph->[$i], $pl->[$i], $value) // next;
    $tail *= (1 - $alpha);
    if ($tail <= App::Chart::Series::Derived::EMA::WARMUP_OMITTED_FRACTION) {
      last;
    }
  }
  ### FRAMA warmup_count_for_position(): "for $lo is ".($lo-$i)
  return $lo - $i;
}

sub proc {
  my ($class, $N) = @_;
  my $alpha_proc = App::Chart::Series::Derived::FRAMAalpha->proc($N);
  my $ama_proc = App::Chart::Series::Derived::KAMA->adaptive_ema_proc();

  return sub {
    my ($high, $low, $close) = @_;
    my $alpha = $alpha_proc->(@_) // return undef;

    # ENHANCE-ME: pending configurable selection for this sort of thing ...
    # operate on John Ehlers preferred midpoint ...
    # my $value = (($high // $close) + ($low // $close)) / 2;

    return $ama_proc->($alpha, $close);
  };
}
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part; # HLC

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::FRAMA -- fractal adaptive moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->FRAMA($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::EMA>
# 
# =cut
