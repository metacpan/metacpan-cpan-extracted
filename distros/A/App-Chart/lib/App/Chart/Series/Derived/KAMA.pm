# Copyright 2006, 2007, 2009 Kevin Ryde

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

package App::Chart::Series::Derived::KAMA;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::KAMAalpha;

use constant DEBUG => 0;


# http://www.traders.com/Documentation/FEEDbk_docs/Archive/0398/TradersTips/Tips9803.html
#    Traders tips March 1998: metastock and easylanguage code
#
# http://www.perrykaufman.com
#    Perry Kaufman's web site (no formulas).
# 
# http://www.tssupport.com/support/base/?action=article&id=1769
#    Short tradestation article, incl EFS code.
#
# Code uses close() to close(-period), so N differences and N+1 total
# points.
#


sub longname  { __('KAMA - Kaufmann Adaptive MA') }
sub shortname { __('KAMA') }
sub manual    { __p('manual-node','Kaufman Adaptive Moving Average') }

use constant
  { type       => 'average',
    parameter_info => App::Chart::Series::Derived::KAMAalpha::parameter_info(),
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "KAMA bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}

# warmup_count() gives a fixed amount, based on the worst-case EMA alphas
# all the slowest possible.  It ends up being 1656 which is hugely more than
# needed in practice.
#
# warmup_count_for_position() calculates a value on actual data, working
# backwards.  In practice it's as little as about 100.
#
use constant WORST_EMA_WARMUP =>
  App::Chart::Series::Derived::EMA->warmup_count
  (App::Chart::Series::Derived::EMA::alpha_to_N
   (App::Chart::Series::Derived::KAMAalpha->minimum));
if (DEBUG) {
  say "KAMA minimum alpha ",App::Chart::Series::Derived::KAMAalpha->minimum;
  say "     worst N       ",(App::Chart::Series::Derived::EMA::alpha_to_N
                             (App::Chart::Series::Derived::KAMAalpha->minimum));
  say "     WORST_EMA_WARMUP @{[WORST_EMA_WARMUP]}";
}
sub warmup_count {
  my ($self_or_class, $N) = @_;
  return (WORST_EMA_WARMUP
          + App::Chart::Series::Derived::KAMAalpha->warmup_count($N));
}

sub warmup_count_for_position {
  return warmup_count_for_position_alphaclass
    (@_, 'App::Chart::Series::Derived::KAMAalpha');
}

sub warmup_count_for_position_alphaclass {
  my ($self, $lo, $alpha_class) = @_;
  my $parent = $self->{'parent'};
  my $p = $parent->values_array;

  my $p_lo = $lo + 1; # initial fill
  my $chunk = 16;

  my $alpha_proc = $alpha_class->proc(@{$self->{'parameters'}});
  my $alpha_warmup = $alpha_class->warmup_count(@{$self->{'parameters'}});
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
    $alpha_proc->($value) // next;
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
    my $alpha = $alpha_proc->($value) // next;
    $tail *= (1 - $alpha);
    if ($tail <= App::Chart::Series::Derived::EMA::WARMUP_OMITTED_FRACTION) {
      last;
    }
  }
  if (DEBUG) {
    say "warmup_count_for_position($alpha_class) for $lo is @{[$lo-$i]}"; }
  return $lo - $i;
}

sub proc {
  my ($class, $N) = @_;
  my $alpha_proc = App::Chart::Series::Derived::KAMAalpha->proc($N);
  my $ama_proc = $class->adaptive_ema_proc();

  return sub {
    my ($value) = @_;
    my $alpha = $alpha_proc->($value) // return;
    return $ama_proc->($alpha, $value);
  };
}

sub adaptive_ema_proc {
  my ($class) = @_;

  my $sum    = 0;
  my $weight = 0;
  return sub {
    my ($alpha, $value) = @_;

    $sum = $sum*(1-$alpha) + $value*$alpha;

    # rearranged from
    #   w_next = w*(1-alpha) + 1*alpha
    #          = w - w*alpha + alpha
    #          = w + alpha*(1-w)
    $weight += $alpha*(1-$weight);

    # can have $weight==0 if first $alpha is 0
    return ($weight == 0 ? undef : $sum / $weight);
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::KAMA -- Kaufman Adaptive Moving Average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->KAMA($N);
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
