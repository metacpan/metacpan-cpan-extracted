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

package App::Chart::Series::Derived::KVOforce;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::MFI;

use constant DEBUG => 0;


# http://www.traders.com/Documentation/FEEDbk_docs/Archive/1297/TradersTips/Tips9712.html
#     Traders Tips December 1997 formulas.
#
# http://trader.online.pl/ELZ/t-i-Klinger_Volume_Oscillator.html
#     Repeat of EasyChart section of traders tips above.
#
# http://www.prophet.net/learn/taglossary.jsp?index=K
#     Sample chart of intel (INTC) Nov02-Feb03, KVO and also histogram.
# http://www.prophet.net/analyze/popglossary.jsp?studyid=KVO
#     Same chart of INTC, but just the KVO not the histogram.


use constant
  { longname   => __('KVO volume force'),
    shortname  => __('KVO force'),
    manual     => __p('manual-node','Klinger Volume Oscillator'),
    priority   => -10,
    type       => 'indicator',
    units      => 'KVOforce',
    hlines     => [ 0 ],
    parameter_info => [ ],
  };

sub new {
  my ($class, $parent) = @_;
  if (DEBUG) { say "KVOforce new"; }

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ ],
     arrays     => { values => [] },
     array_aliases => { });
}
*fill_part = \&App::Chart::Series::Derived::MFI::fill_part;

sub proc {
  my ($class_or_self) = @_;

  my $prev_hlc;
  my $prev_trend = -100;
  my $prev_dm = 0;
  my $cm = 0;

  return sub {
    my ($high, $low, $close, $volume) = @_;
    $high //= $close;
    $low  //= $close;
    $volume //= 0;

    my $hlc = $high + $low + $close;
    my $dm = $high - $low;
    my $force;
    if (defined $prev_hlc) {
      my $trend = ($hlc > $prev_hlc ? 1 : -1);

      if ($trend == $prev_trend) {
        $cm += $dm;
      } else {
        $cm = $dm + $prev_dm;
      }
      $force = ($cm == 0 ? 0
                : $volume * $trend * abs (2*$dm/$cm - 1));

      $prev_trend = $trend;
    }
    $prev_hlc = $hlc;
    $prev_dm = $dm;

    return $force;
  };
}

sub warmup_count_for_position {
  my ($self, $lo) = @_;
  if (DEBUG) {
    say "KVOforce warmup_count_for_position $lo, parent=$self->{'parent'}"; }

  my $parent = $self->{'parent'};
  my $p = $parent->values_array;
  my $ph = $parent->array('highs') || $p;
  my $pl = $parent->array('lows')  || $p;

  my $p_lo = $lo + 1;  # fill initially
  my $chunk = 16;

  my $i = $lo;

  # looking back for a point where $trend changes
  my ($after_hlc, $after_trend);
  for ( ; $i >= 0; $i--) {
    if ($i < $p_lo) {
      my $new_p_lo = min ($i, $p_lo - $chunk);
      $chunk *= 2;
      $parent->fill ($new_p_lo, $i);
      $p_lo = $new_p_lo;
    }
    my $value = $p->[$i] // next;
    my $hlc = ($ph->[$i]//$value) + ($pl->[$i]//$value) + $value;
    if (defined $after_hlc) {
      my $trend = ($after_hlc > $hlc ? 1 : -1);
      if (defined $after_trend && $trend != $after_trend) {
        last;
      }
      $after_trend = $trend;
    }
    $after_hlc = $hlc;
  }

  # then one further close for the $prev_dm for $cm=$dm+$prev_dm
  $lo = $parent->find_before ($lo, 1);

  if (DEBUG) { say "KVOforce warmup_count_for_position for $lo==@{[$self->timebase->to_iso($lo)]} is @{[$lo-$i]}"; }
  return $lo - $i;
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::KVOforce -- KVO force amounts
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->KVOforce();
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
