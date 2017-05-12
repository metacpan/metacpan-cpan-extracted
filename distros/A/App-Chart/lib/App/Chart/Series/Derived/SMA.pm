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

package App::Chart::Series::Derived::SMA;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';

# uncomment this to run the ### lines
#use Smart::Comments;


sub longname  { __('SMA - Simple MA') }
sub shortname { __('SMA') }
sub manual    { __p('manual-node','Simple Moving Average') }

use constant
  { priority   => 13,
    type       => 'average',
    parameter_info => [ { name    => __('Days'),
                          key     => 'sma_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;
  ### SMA new: \@_

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "SMA bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub warmup_count {
  my ($self_or_class, $N) = @_;
  return $N - 1;
}
sub proc {
  my ($class_or_self, $N) = @_;

  if ($N <= 1) {
    return \&App::Chart::Series::Calculation::identity;
  }

  my @array;
  my $pos = $N - 1;  # initial extends
  my $total = 0;
  my $count = 0;
  return sub {
    my ($value) = @_;

    # drop old
    if ($count >= $N) {
      $total -= $array[$pos];
    } else {
      $count++;
    }

    # add new
    $total += ($array[$pos] = $value);
    if (++$pos >= $N) { $pos = 0; }

    return $total / $count;
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::SMA -- simple moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->SMA($N);
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
