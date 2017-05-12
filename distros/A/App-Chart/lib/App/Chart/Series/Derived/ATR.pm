# Copyright 2003, 2004, 2005, 2006, 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::ATR;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::TrueRange;
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::WilliamsR;

# http://www.incrediblecharts.com/indicators/average_true_range.php
#
# http://www.trade2win.com/knowledge/articles/general_articles/average-true-range-indicator/
#     Sample S&P 500 Sep2005 to Feb2006, seems to be 14-day smoothing.


sub longname   { __('ATR - Average True Range') }
sub shortname  { __('ATR') }
sub manual     { __p('manual-node','Average True Range') }

use constant
  { type       => 'indicator',
    units      => 'price',
    minimum    => 0,
    parameter_info => [ { name    => __('Days'),
                          key     => 'atr_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 14 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "ATR bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub warmup_count {
  my ($self_or_class, $N) = @_;

  $N = App::Chart::Series::Derived::EMA::N_from_Wilder_N ($N);
  return (App::Chart::Series::Derived::TrueRange->warmup_count()
          + App::Chart::Series::Derived::EMA->warmup_count($N));
}
sub proc {
  my ($class_or_self, $N) = @_;
  $N = App::Chart::Series::Derived::EMA::N_from_Wilder_N ($N);
  my $tr_proc = App::Chart::Series::Derived::TrueRange->proc();
  my $ema_proc = App::Chart::Series::Derived::EMA->proc($N);
  return sub {
    my ($high, $low, $close) = @_;
    return $ema_proc->($tr_proc->($high, $low, $close));
  };
}
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::ATR -- average true range
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->ATR($N);
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
