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

package App::Chart::Series::Derived::ChaikinMF;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::MFI;
use App::Chart::Series::Derived::RSI;

# http://www.incrediblecharts.com/technical/chaikin_money_flow.php
#

sub longname  { __('Chaikin Money Flow') }
sub shortname { __('Chaikin MF') }
sub manual    { __p('manual-node','Chaikin Money Flow') }

use constant
  { type       => 'indicator',
    minimum    => -1,
    maximum    => 1,
    units      => 'minus_one_to_plus_one',
    hlines     => [ 0 ],
    parameter_info => [ { name     => __('Days'),
                          key      => 'chaikin_mf_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 21 } ]
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "ChaikinMF bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::RSI::warmup_count; # EMA(W)+1
*fill_part = \&App::Chart::Series::Derived::MFI::fill_part;

sub proc {
  my ($class_or_self, $N) = @_;
  my $num_proc = App::Chart::Series::Calculation->sum ($N);
  my $den_proc = App::Chart::Series::Calculation->sum ($N);

  return sub {
    my ($high, $low, $close, $volume) = @_;
    $high //= $close;
    $low  //= $close;
    $volume //= 0;

    my $diff = $high - $low;
    my $clv = ($diff == 0 ? 0
               # volume times -1 to +1
               : $volume * (-1 + 2*($close-$low)/$diff));
    my $num = $num_proc->($clv);
    my $den = $den_proc->($volume);
    return ($den == 0 ? 0 : $num/$den);
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::ChaikinMF -- Chaikin money flow
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->ChaikinMF($N);
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
