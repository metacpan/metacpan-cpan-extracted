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

package App::Chart::Series::Derived::Inertia;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::RVI;
use App::Chart::Series::Derived::EPMA;
use App::Chart::Series::Derived::WilliamsR;


# http://trader.online.pl/MSZ/e-w-Inertia.html
#     
# http://www.fmlabs.com/reference/Inertia.htm
#     Formula, some description.
#
# http://www.prophet.net/analyze/popglossary.jsp?studyid=INERT
#     Sample DELL from 2001/2.
#
# http://store.traders.com/-v13-c09-refinin-pdf.html
#     Dorsey TASC 1995 for sale.
#

sub longname   { __('Inertia (smoothed RVI)') }
sub shortname  { __('Inertia') }
sub manual     { __p('manual-node','Inertia') }

use constant
  { hlines     => [ 40, 50, 60 ],
    type       => 'indicator',
    units      => 'percentage',
    minimum    => 0,
    maximum    => 100,
    parameter_info => [ { name     => __('Stddev Days'),
                          key      => 'rvi_stddev_days', # per RVI.pm
                          type     => 'integer',
                          minimum  => 1,
                          default  => 10 },
                        { name     => __('Smooth Days'),
                          key      => 'rvi_smooth_days', # per RVI.pm
                          type     => 'float',
                          minimum  => 1,
                          default  => 14,
                          decimals => 0,
                          step     => 1 },
                        { name     => __('LSQMA Days'),
                          key      => 'inertia_lsqma_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 20 },
                      ],
  };

sub new {
  my ($class, $parent, $N_stddev, $N_smooth, $N_lsqma) = @_;

  $N_stddev //= parameter_info()->[0]->{'default'};
  ($N_stddev > 0) || croak "Inertia bad N_stddev: $N_stddev";

  $N_smooth //= parameter_info()->[1]->{'default'};
  ($N_smooth > 0) || croak "Inertia bad N_smooth: $N_smooth";

  $N_lsqma //= parameter_info()->[1]->{'default'};
  ($N_lsqma > 0) || croak "Inertia bad N_lsqma: $N_lsqma";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N_stddev, $N_smooth, $N_lsqma ],
     arrays     => { values => [] },
     array_aliases => { });
}
*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;

sub warmup_count {
  my ($class_or_self, $N_stddev, $N_smooth, $N_lsqma) = @_;
  return (App::Chart::Series::Derived::RVI->warmup_count($N_stddev, $N_smooth)
          + App::Chart::Series::Derived::EPMA->warmup_count($N_lsqma));
}

sub proc {
  my ($class_or_self, $N_stddev, $N_smooth, $N_lsqma) = @_;
  my $rvi_proc = App::Chart::Series::Derived::RVI->proc($N_stddev, $N_smooth);
  my $lsqma_proc = App::Chart::Series::Derived::EPMA->proc($N_lsqma);
  return sub {
    my $rvi = $rvi_proc->(@_) // return;
    return $lsqma_proc->($rvi);
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Inertia -- relative volatility index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Inertia($N);
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
