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

package App::Chart::Series::Derived::AdaptiveLaguerre;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::LaguerreFilter;
use App::Chart::Series::Derived::Median;
use App::Chart::Series::Derived::WilliamsR;


# http://www.mesasoftware.com/technicalpapers.htm
# http://www.mesasoftware.com/Papers/TIME%20WARP.pdf
#     Paper by John Elhers.
#
# http://www.mesasoftware.com/seminars.htm
# http://www.mesasoftware.com/Seminars/TradeStation%20World%2005.pdf
# http://www.mesasoftware.com/Seminars/Seminars/TSWorld05.ppt
#     (View the powerpoint with google.)
#     Powerpoint summary by John Ehlers of several of his and other averages.
#     View in google,
#     * A Laguerre filter warps time in the filter coefficients
#       - Enables extreme smoothing with just a few filter terms
#     * A NonLinear Laguerre filter measures the difference between the
#       current price and the last computed filter output.
#       - Objective is to drive this "error" to zero
#       - The "error", normalized to the error range over a selected period
#         is the alpha of the Laguerre filter
#


sub longname   { __('Adaptive Laguerre Filter') }
sub shortname  { __('Adaptive Laguerre') }
sub manual     { __p('manual-node','Adaptive Laguerre Filter') }

use constant
  { type       => 'average',
    parameter_info => [ { name     => __('Days'),
                          key      => 'adaptive_laguerre_filter_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N >= 1) || croak "Adaptive Laguerre Filter bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}

sub proc {
  my ($class, $N) = @_;
  my $proc_laguerre_and_alpha = $class->proc_laguerre_and_alpha($N);
  return sub {
    return ($proc_laguerre_and_alpha->(@_))[0];
  };
}
sub proc_laguerre_and_alpha {
  my ($class, $N) = @_;

  my $laguerre_proc
    = App::Chart::Series::Derived::LaguerreFilter->proc_for_alpha();
  my $williams_proc = App::Chart::Series::Derived::WilliamsR->proc($N);
  my $median_proc   = App::Chart::Series::Derived::Median->proc(5);
  my $alpha = 0.2;
  my $prev;

  return sub {
    my ($value) = @_;
    if (defined $prev) {
      my $w = $williams_proc->(undef, undef, abs ($value - $prev));
      $alpha = $median_proc->(0.01 * ($w + 100)); # 0 to 1
    }
    return (($prev = $laguerre_proc->($value, $alpha)),
            $alpha);
  };
}


# warmup_count() gives a fixed amount, based on the worst-case EMA alphas
# all the slowest possible.  It ends up being 1656 which is hugely more than
# needed in practice.
#
# warmup_count_for_position() calculates a value on actual data, working
# backwards.  In practice it's as little as about 100.
#
sub warmup_count {
  my ($self_or_class, $N) = @_;

  # FIXME: this is a big over-estimate
  return $N + App::Chart::Series::Derived::LaguerreFilter->warmup_count(0.01);
}

### AdaptiveLaguerre warmup_count(): __PACKAGE__->warmup_count(parameter_info()->[0]->{'default'})

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::AdaptiveLaguerre -- Laguerre Filter moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->AdaptiveLaguerre($alpha);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::LaguerreFilter>
# 
# =cut
