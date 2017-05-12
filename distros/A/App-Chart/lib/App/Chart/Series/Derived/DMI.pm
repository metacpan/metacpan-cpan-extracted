# Copyright 2006, 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::DMI;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::ATR;
use App::Chart::Series::Derived::EMA;

# http://www.incrediblecharts.com/indicators/directional_movement.php
#

sub longname  { __('DMI - Directional Movement Index') }
sub shortname { __('DMI') }
sub manual    { __p('manual-node','Directional Movement Index') }

use constant
  { type       => 'indicator',
    units      => 'dmi',
    minimum    => 0,
    parameter_info => [ { name     => __('Days'),
                          key      => 'dmi_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 14,
                          decimals => 0,
                          step     => 1 } ],
    line_colours => { plus  => App::Chart::UP_COLOUR(),
                      minus => App::Chart::DOWN_COLOUR() },
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "DMI bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { plus  => [],
                     minus => [] },
     array_aliases => { values => 'plus' });
}
*warmup_count = \&App::Chart::Series::Derived::ATR::warmup_count;  # EMA(W)+1

sub proc {
  my ($class_or_self, $N) = @_;
  my $W = App::Chart::Series::Derived::EMA::N_from_Wilder_N ($N);
  my $dm_proc = dm_proc();
  my $ema_plus_proc  = App::Chart::Series::Derived::EMA->proc($W);
  my $ema_minus_proc = App::Chart::Series::Derived::EMA->proc($W);
  my $atr_proc = App::Chart::Series::Derived::ATR->proc($N);

  return sub {
    my ($high, $low, $close) = @_;
    $high //= $close;
    $low //= $close;

    my $atr = $atr_proc->($high, $low, $close);
    my ($dm_plus, $dm_minus) = $dm_proc->($high, $low);

    if (! defined $dm_plus) { return; }
    my $di_plus  = $ema_plus_proc->($dm_plus);
    my $di_minus = $ema_minus_proc->($dm_minus);

    if ($atr == 0) { return; }
    return (100 * $di_plus / $atr,
            100 * $di_minus / $atr);
  };
}
sub dm_proc {
  my ($class_or_self) = @_;
  my ($prev_high, $prev_low);

  return sub {
    my ($high, $low) = @_;

    my ($dm_plus, $dm_minus);
    if (defined $prev_high) {
      $dm_plus  = max (0, $high - $prev_high);
      $dm_minus = max (0, $prev_low - $low);

      # zap the smaller of the two, or if equal zap both
      if ($dm_plus > $dm_minus) {
        $dm_minus = 0;
      } elsif ($dm_plus < $dm_minus) {
        $dm_plus = 0;
      } else {
        $dm_plus = $dm_minus = 0;
      }
    }
    $prev_high = $high;
    $prev_low = $low;
    return ($dm_plus, $dm_minus);
  };
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($lo, $hi);
  my $p = $parent->values_array;
  my $ph = $parent->array('highs') || $p;
  my $pl = $parent->array('lows')  || $p;

  my $s_plus = $self->array('plus');
  my $s_minus = $self->array('minus');
  $hi = min ($hi, $#$p);
  if ($#$s_plus  < $hi) { $#$s_plus  = $hi; }  # pre-extend
  if ($#$s_minus < $hi) { $#$s_minus = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $value = $p->[$i] // next;
    $proc->($ph->[$i], $pl->[$i], $value);
  }
  foreach my $i ($lo .. $hi) {
    my $value = $p->[$i] // next;
    ($s_plus->[$i], $s_minus->[$i]) = $proc->($ph->[$i], $pl->[$i], $value);
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::DMI -- directional movement index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->DMI($N);
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
