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

package App::Chart::Series::Derived::QStick;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;
use App::Chart::Series::Derived::IMI;

# http://trader.online.pl/MSZ/e-w-Chandes_QStick.html
#

sub longname   { __('QStick') }
*shortname = \&longname;
sub manual     { __p('manual-node','QStick') }

use constant
  { type       => 'indicator',
    units      => 'percentage',
    minimum    => 0,
    maximum    => 100,
    hlines     => [ 0 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'qstick_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 8 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "QStick bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}

# Return a procedure which calculates an intraday momentum index over an
# accumulated window of $N values.
#
# Each call $proc->($open, $close) enters a new point into the window, and
# the return is the intraday momentum index up to (and including) that
# point.  If there's no value the return is undef, which can happen if every
# day has $open==$close.
#
# To prime the window initially, call $proc with $N-1 many points preceding
# the first desired.
#
sub proc {
  my ($class_or_self, $N) = @_;
  my $sma_proc = App::Chart::Series::Derived::SMA->proc ($N);

  return sub {
    my ($open, $close) = @_;
    if (! defined $open) { return undef; }
    return $sma_proc->($close - $open);
  };
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count; # $N-1
*fill_part = \&App::Chart::Series::Derived::IMI::fill_part;

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::QStick -- QStick indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->QStick($N);
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
