# Copyright 2005, 2006, 2007, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::MFI;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::RSI;
use App::Chart::Series::Derived::TypicalPrice;


# http://www.linnsoft.com/tour/techind/mfi.htm
#     Formula, and sample Apple (AAPL) from 1999/2000 as 9-day MFI smoothed
#     by 7-day SMA.
#

# The MFI formula is sometimes written
#
#                      /       100       \
#                     |  ---------------  |
#         MFI = 100 - |      positive MF  |
#                     |  1 + -----------  |
#                      \     negative MF /
#
#
# but it's much easier to rearrange that to what's shown in the manual,
#
#                     positive MF
#         MFI = 100 * -----------
#                      pos+neg MF



sub longname  { __('MFI - Money Flow Index') }
sub shortname { __('MFI') }
sub manual    { __p('manual-node','Money Flow Index') }

use constant
  { type       => 'indicator',
    units      => 'percentage',
    minimum    => 0,
    maximum    => 100,
    hlines     => [ 20, 80 ],
    parameter_info => [ { name     => __('Days'),
                          key      => 'mfi_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 14 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "MFI bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub warmup_count {
  my ($self_or_class, $N) = @_;
  return $N;
}
sub proc {
  my ($class_or_self, $N) = @_;
  my $num_proc = App::Chart::Series::Calculation->sum ($N);
  my $den_proc = App::Chart::Series::Calculation->sum ($N);
  my $prev_tp;

  return sub {
    my ($high, $low, $close, $volume) = @_;

    my $tp = App::Chart::Series::Derived::TypicalPrice::typical_price
      ($high, $low, $close);
    $volume //= 0;

    my $mfi;
    if (defined $prev_tp) {
      # money flow is +tp*volume, -tp*volume, or 0
      my $mf = ($tp <=> $prev_tp) * $tp * $volume;
      $prev_tp = $tp;

      my $num = $num_proc->(max ($mf, 0));
      my $den = $den_proc->(abs ($mf));
      $mfi = ($den == 0 ? 0 : $num/$den);
    }
    $prev_tp = $tp;
    return $mfi;
  };
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  ### MFI fill_part(): "$lo $hi"
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
# App::Chart::Series::Derived::MFI -- money flow index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->MFI($N);
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
