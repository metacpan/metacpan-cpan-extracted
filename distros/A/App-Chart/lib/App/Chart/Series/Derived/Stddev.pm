# Copyright 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::Stddev;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;

sub longname   { __('Standard Deviation') }
sub shortname  { __('Stddev') }
sub manual     { __p('manual-node','Standard Deviation') }

use constant
  { priority   => -10,
    type       => 'indicator',
    units      => 'price',
    hlines     => [ 0 ],
    minimum    => 0,
    parameter_info => [ { name    => __('Days'),
                          key     => 'stddev_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;
  ### Stddev new(): "@_"

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "Stddev bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count; # $N-1

#                / p1^2 + p2^2 + ... + pN^2   (p1 + p2 + ... + pN)^2 \
# Stddev = sqrt (  ------------------------ - ----------------------  )
#                \            N                         N^2          /
#
# rearranged to a single division,
#
#          sqrt ( (p1^2 + p2^2 + ... + pN^2) * N - (p1 + p2 + ... + pN)^2 )
#        = ----------------------------------------------------------------
#                                   N
#
sub proc {
  my ($class, $N) = @_;
  if ($N == 0) { die "Stddev N==0"; }
  $N = max (1, $N);

  my @array;
  my $count = 0;
  my $pos = $N - 1;  # initial extends

  my $total = 0;
  my $total_squares = 0;

  return sub {
    my ($value) = @_;

    # drop old
    if ($count >= $N) {
      my $old = $array[$pos];
      $total -= $old;
      $total_squares -= $old * $old;
    } else {
      $count++;
    }

    # add new
    $total += ($array[$pos] = $value);
    $total_squares += $value * $value;
    if (++$pos >= $N) { $pos = 0; }

    return sqrt(max (0, $total_squares*$count - $total*$total)) / $count;
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Stddev -- sliding window standard deviation
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Stddev($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::SMA>,
# L<App::Chart::Series::Derived::Bollinger>,
# L<App::Chart::Series::Derived::VIDYA>
# 
# =cut
