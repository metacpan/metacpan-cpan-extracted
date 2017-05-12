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

package App::Chart::Series::Derived::Ultimate;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;
use App::Chart::Series::Derived::WilliamsR;

# http://www.stockcharts.com/education/IndicatorAnalysis/indic_ultimate.html


sub longname  { __('Ultimate Oscillator') }
sub shortname { __('Ultimate') }
sub manual    { __p('manual-node','Ultimate Oscillator') }

use constant
  { type       => 'indicator',
    units      => 'percentage',
    minimum    => 0,
    maximum    => 100,
    hlines     => [ 30, 50, 70 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'williams_r_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 10 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "Ultimate bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}


use constant { N1 => 7,
               N2 => 14,
               N3 => 28 };
use constant warmup_count => N3;

sub proc {
  my ($class_or_self) = @_;
  my $prev_close;

  my $b1_proc = App::Chart::Series::Derived::SMA->proc (N1);
  my $t1_proc = App::Chart::Series::Derived::SMA->proc (N1);
  my $b2_proc = App::Chart::Series::Derived::SMA->proc (N2);
  my $t2_proc = App::Chart::Series::Derived::SMA->proc (N2);
  my $b3_proc = App::Chart::Series::Derived::SMA->proc (N3);
  my $t3_proc = App::Chart::Series::Derived::SMA->proc (N3);

  return sub {
    my ($high, $low, $close) = @_;
    $high //= $close;
    $low //= $close;

    # extend to true high/low
    if (defined $prev_close) {
      $high = max ($high, $prev_close);
      $low  = min ($low, $prev_close);
    }
    $prev_close = $close;

    my $bp = $close - $low; # buying pressure
    my $tr = $high - $low;  # true range

    my $b1 = $b1_proc->($bp);
    my $t1 = $t1_proc->($tr);
    my $b2 = $b2_proc->($bp);
    my $t2 = $t2_proc->($tr);
    my $b3 = $b3_proc->($bp);
    my $t3 = $t3_proc->($tr);

    if ($t1 == 0 || $t2 == 0 || $t3 == 0) { return undef; }

    return 100 * (4*$b1/$t1 + 2*$b2/$t2 + $b3/$t3) / 7;
  };
}
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Ultimate -- Larry Williams' ultimate oscillator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Ultimate($N);
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
