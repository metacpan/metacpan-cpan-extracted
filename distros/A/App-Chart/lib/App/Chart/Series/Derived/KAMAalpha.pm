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

package App::Chart::Series::Derived::KAMAalpha;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::SMA;
use App::Chart::Series::Derived::EMA;

use constant
  { FASTEST_ALPHA => App::Chart::Series::Derived::EMA::N_to_alpha(2),
    SLOWEST_ALPHA => App::Chart::Series::Derived::EMA::N_to_alpha(30) };

sub longname  { __('KAMA - Alpha') }
sub shortname { __('KAMA alpha') }
sub manual    { __p('manual-node','Kaufman Adaptive Moving Average') }

use constant
  { type       => 'indicator',
    priority   => -10,
    units      => 'ema_alpha',
    minimum    => SLOWEST_ALPHA ** 2,
    maximum    => FASTEST_ALPHA ** 2,
    parameter_info => [ { name     => __('Days'),
                          key      => 'kama_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 10 } ],
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
sub warmup_count {
  my ($self_or_class, $N) = @_;
  return $N;
}
sub proc {
  my ($class, $N) = @_;
  my $sum_proc = App::Chart::Series::Calculation->sum ($N);
  my @values;
  return sub {
    my ($value) = @_;
    my $alpha;
    if (@values) {
      my $prev = $values[0];
      my $this_absmove = abs ($value - $prev);
      my $total_absmove = $sum_proc->($this_absmove);

      my $prevnth = $values[-1]; # $N days ago
      my $net_move = abs ($value - $prevnth);

      my $ef_ratio = ($total_absmove == 0
                      ? 1   # would be 0/0
                      : $net_move / $total_absmove);
      $alpha
        = (SLOWEST_ALPHA + $ef_ratio * (FASTEST_ALPHA - SLOWEST_ALPHA)) ** 2;
      # print "  value=$value prev=$prev prevnth=$prevnth net_move=$net_move total_absmove=$total_absmove  EF=$ef_ratio alpha=$alpha\n";
    }
    unshift @values, $value;
    if (@values > $N) { # keep $N many
      pop @values;
    }
    return $alpha;
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::KAMAalpha -- alpha factor for Kaufman Adaptive Moving Average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->KAMAalpha($N);
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
