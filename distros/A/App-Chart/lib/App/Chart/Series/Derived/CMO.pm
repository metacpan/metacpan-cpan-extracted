# Copyright 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::CMO;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::MFI;
use App::Chart::Series::Derived::SMA;


# http://www.equis.com/customer/resources/formulas/formula.aspx?Id=8
#     Metastock formulas.
#
# http://trader.online.pl/MSZ/e-w-Chandes_Momentum_Oscillator.html
#     Formulas and text from equis.com.
#


sub longname   { __('CMO - Chande Momentum Oscillator') }
sub shortname  { __('CMO') }
sub manual     { __p('manual-node','Chande Momentum Oscillator') }

use constant
  { hlines     => [ -50, 50 ],
    type       => 'indicator',
    units      => 'percentage_plus_or_minus_100',
    minimum    => -100,
    maximum    => 100,
    parameter_info => [ { name     => __('Days'),
                          key      => 'cmo_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 14 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "CMO bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::MFI::warmup_count; # $N

sub proc {
  my ($class_or_self, $N) = @_;
  my $num_proc = App::Chart::Series::Calculation->sum ($N);
  my $den_proc = App::Chart::Series::Calculation->sum ($N);
  my $prev;
  return sub {
    my ($value) = @_;
    my $ret;
    if (defined $prev) {
      my $diff = $value - $prev;
      my $num = $num_proc->($diff);
      my $den = $den_proc->(abs $diff);
      $ret = ($den == 0 ? 0 : 100 * $num / $den);
    }
    $prev = $value;
    return $ret;
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::CMO -- relative strength index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->CMO($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::SMA>
# 
# =cut
