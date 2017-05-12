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

package App::Chart::Series::Derived::LinRegSlope;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::SMA;


sub longname  { __('Linear Regression Slope') }
sub shortname { __('Linreg Slope') }
sub manual    { __p('manual-node','Linear Regression Slope') }

use constant
  { type       => 'indicator',
    units      => 'price-slope',
    priority   => -10,
    hlines     => [ 0 ],
    minimum    => 0,
    parameter_info => [ { name    => __('Days'),
                          key     => 'linregslope_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "LinRegSlope bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count; # $N-1

sub proc {
  my ($class, $N) = @_;
  my $linreg_proc = App::Chart::Series::Calculation->linreg($N);
  return sub {
    my ($y) = @_;
    return ($linreg_proc->($y))[1];
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::LinRegSlope -- linear regression slope
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->LinRegSlope($N);
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
