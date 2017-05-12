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

package App::Chart::Series::Derived::Ease;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::Stddev;
use App::Chart::Series::Derived::WilliamsR;


# http://www.incrediblecharts.com/technical/emv_construction.htm
#
# http://www.paritech.com.au/education/technical/indicators/strength/ease.asp
#
# http://www.linnsoft.com/tour/techind/arms.htm
#     Sample Apple (AAPL) from April 2000, but using SMA instead of EMA.
#
# http://kb.worden.com/default.asp?id=49&Lang=1&SID=
#     Sample Amazon (AMZN) from 2006, 14-day, maybe SMA instead of EMA.
#

sub longname   { __('Ease of Movement') }
sub shortname  { __('Ease') }
sub manual     { __p('manual-node','Ease of Movement') }

use constant
  { hlines     => [ 0 ],
    type       => 'indicator',
    units      => 'Ease',
    parameter_info => [ { name     => __('Days'),
                          key      => 'ease_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 14,
                          decimals => 0,
                          step     => 1 }],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "Ease bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}

sub warmup_count {
  my ($class_or_self, $N) = @_;
  return 1 + App::Chart::Series::Derived::EMA->warmup_count($N);
}

# Return a procedure which calculates a relative volatility index, using
# Dorsey's original 1993 definition, over an accumulated window.
#
sub proc {
  my ($class_or_self, $N) = @_;

  my $ema_proc = App::Chart::Series::Derived::EMA->proc ($N);
  my $prev_mid;

  return sub {
    my ($high, $low, $close, $volume) = @_;
    $high //= $close;
    $low //= $close;
    my $mid = ($high + $low) / 2;

    my $ease;
    if (defined $prev_mid) {
      $volume //= 0;
      $ease = ($mid - $prev_mid) * ($high - $low) * 1e6 / $volume;
      $ease = $ema_proc->($ease);
    }
    $prev_mid = $mid;
    return $ease;
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
  my $pv = $parent->array('volumes') || [];

  my $s = $self->values_array;
  $hi = min ($hi, $#$p);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $close = $p->[$i] // next;
    $proc->($ph->[$i], $pl->[$i], $close, $pv->[$i]);
  }
  foreach my $i ($lo .. $hi) {
    my $close = $p->[$i] // next;
    $s->[$i] = $proc->($ph->[$i], $pl->[$i], $close, $pv->[$i]);
  }
}
1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Ease -- ease of movement indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Ease($N);
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
