# Copyright 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::RVI;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::Stddev;
use App::Chart::Series::Derived::WilliamsR;


# http://www.fmlabs.com/reference/RVI.htm
#     Formula, some description.
#
# http://trader.online.pl/MSZ/e-w-Relative_Volatility_Index_RVI.html
#     Reproducing equis.com original 1993 version, adding sample of Kredyt
#     Bank (which is not in Yahoo, or only as .PK pink sheets).
# http://trader.online.pl/MSZ/e-w-Inertia.html
#     1995 revision.
#
# http://www.equis.com/customer/resources/formulas/formula.aspx?Id=52
#     Original 1993.
#
# http://store.traders.com/-v11-c06-therela-pdf.html
#     TASC 1993.
#
# http://store.traders.com/-v13-c09-refinin-pdf.html
#     TASC 1995, high/low combination, and introducing Inertia.
#
# http://store.traders.com/v1340tradtip.html
#     TASC traders tips for sale.
#

sub longname   { __('RVI - Relative Volatility Index') }
sub shortname  { __('RVI') }
sub manual     { __p('manual-node','Relative Volatility Index') }

use constant
  { hlines     => [ 40, 50, 60 ],
    type       => 'indicator',
    units      => 'percentage',
    minimum    => 0,
    maximum    => 100,
    parameter_info => [ { name     => __('Stddev Days'),
                          key      => 'rvi_stddev_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 10 },
                        { name     => __('Smooth Days'),
                          key      => 'rvi_smooth_days',
                          type     => 'float',
                          minimum  => 1,
                          default  => 14,
                          decimals => 0,
                          step     => 1 }],
  };

sub new {
  my ($class, $parent, $N_stddev, $N_smooth) = @_;

  $N_stddev //= parameter_info()->[0]->{'default'};
  ($N_stddev > 0) || croak "RVI bad N_stddev: $N_stddev";

  $N_smooth //= parameter_info()->[1]->{'default'};
  ($N_smooth > 0) || croak "RVI bad N_smooth: $N_smooth";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N_stddev, $N_smooth ],
     arrays     => { values => [] },
     array_aliases => { });
}
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;

sub warmup_count {
  my ($class_or_self, $N_stddev, $N_smooth) = @_;
  $N_smooth = App::Chart::Series::Derived::EMA::N_from_Wilder_N($N_smooth);
  return (App::Chart::Series::Derived::Stddev->warmup_count($N_stddev)
          + App::Chart::Series::Derived::EMA->warmup_count($N_smooth));
}

# Return a procedure which calculates a relative volatility index, using
# Dorsey's original 1993 definition, over an accumulated window.
#
sub proc_original {
  my ($class_or_self, $N_stddev, $N_smooth) = @_;
  $N_smooth = App::Chart::Series::Derived::EMA::N_from_Wilder_N($N_smooth);

  my $stddev_proc = App::Chart::Series::Derived::Stddev->proc ($N_stddev);
  my $num_proc = App::Chart::Series::Derived::EMA->proc ($N_smooth);
  my $den_proc = App::Chart::Series::Derived::EMA->proc ($N_smooth);
  my $prev;

  return sub {
    my ($value) = @_;
    my $stddev = $stddev_proc->($value);
    my $rvi;
    if (defined $prev) {
      my $num = $num_proc->($value > $prev ? $stddev : 0);
      my $den = $den_proc->($stddev);
      $rvi = ($den == 0 ? 50 : 100 * $num/$den);
    }
    $prev = $value;
    return $rvi;
  };
}

# Return a procedure which calculates a relative volatility index, using
# Dorsey's 1995 revised definition, over an accumulated window.
#
sub proc {
  my ($class_or_self, $N_stddev, $N_smooth) = @_;
  my $high_proc = $class_or_self->proc_original($N_stddev, $N_smooth);
  my $low_proc  = $class_or_self->proc_original($N_stddev, $N_smooth);

  return sub {
    my ($high, $low, $close) = @_;
    my $h_rvi = $high_proc->($high // $close);
    my $l_rvi = $low_proc-> ($low  // $close);
    return (defined $h_rvi ? ($h_rvi+$l_rvi)/2 : undef);
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::RVI -- relative volatility index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->RVI($N);
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
