# Copyright 2007, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::MedianAverage;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use POSIX ();
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::TMA;


# http://www.mesasoftware.com/technicalpapers.htm
# http://www.mesasoftware.com/Papers/What's%20the%20Difference.exe
# http://web.archive.org/web/20070720222047/http://www.mesasoftware.com/Papers/What%27s+the+Difference.exe
#     Original gone, use archive.org.
#     John Ehler's paper.  Sample chart of something unspecified.
#

sub longname   { __('Median-Average Adaptive') }
sub shortname  { __('Median-Average') }
sub manual     { __p('manual-node','Median-Average Adaptive Filter') }

use constant
  { type       => 'average',
    parameter_info => [ ],
  };

sub new {
  my ($class, $parent) = @_;

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ ],
     arrays     => { values => [] },
     array_aliases => { });
}
use constant warmup_count =>
  (App::Chart::Series::Derived::TMA->warmup_count(4)
   + 39  # lookback for median
   + App::Chart::Series::Derived::EMA->warmup_count(39)); # slowest smoothing
### MedianAverage warmup_count(): warmup_count()

sub proc {
  my ($class) = @_;
  my $proc_average_and_alpha = $class->proc_average_and_alpha;
  return sub {
    return ($proc_average_and_alpha->(@_))[0];
  };
}

my @alpha_array
  = map {App::Chart::Series::Derived::EMA::N_to_alpha($_)} (0 .. 39);
use constant THRESHOLD => 0.002;

sub proc_average_and_alpha {
  my ($class) = @_;
  my $smooth_proc = App::Chart::Series::Derived::TMA->proc (4);

  # last 39 smoothed input values
  my @values;

  # $prev is the previous median-average value calculated.  $prev is
  # initialized to the first SMOOTHed input.  Ehler's code and some
  # of the Trader's tips show an initial zero, which makes the filter rise
  # up from zero at the start of the data.  Since each alpha determined
  # depends on the previous value there's no way to chop off an infinite
  # sequence like an ordinary EMA.  Using the first smoothed should be
  # reasonable, it won't take too long for the medians to start moving and
  # the average tracking towards that.
  #
  my $prev;

  return sub {
    my ($value) = @_;
    my $alpha;

    my $smooth = $smooth_proc->($value);
    $prev //= $smooth;  # initial

    unshift @values, $smooth;
    if (@values > 39) { pop @values; }

    my $len = round_down_odd (scalar @values);
    for (;;) {
      my @sorted = sort @values[0 .. $len-1];
      my $median = $sorted[$len/2];

      $alpha = $alpha_array[$len];
      my $average = $smooth * $alpha + $prev * (1 - $alpha);

      my $ratio = ($median == 0 ? 0 : abs($median-$average) / $median);
      if ($ratio <= THRESHOLD || $len <= 3) {
        $prev = $average;
        return ($average, $alpha);
      }

      $len -= 2;
    }
  };
}

sub round_down_odd {
  my ($x) = @_;
  return 2 * POSIX::floor (($x-1) / 2) + 1;
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::MedianAverage -- Median-Average Adaptive Filter
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->MedianAverage();
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
