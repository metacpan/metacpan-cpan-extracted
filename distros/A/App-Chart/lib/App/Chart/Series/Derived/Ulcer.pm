# Copyright 2006, 2007, 2009, 2010, 2015 Kevin Ryde

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

package App::Chart::Series::Derived::Ulcer;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::SMA;


# http://www.tangotools.com/ui/ui.htm
#     Description by creator Peter Martin.
#
# http://www.tangotools.com/misc/index.html
#     Peter Martin's home page.
#
# http://www.investopedia.com/articles/technical/03/030403.asp
#     Sample chart of XOM.
#
# http://trader.online.pl/MSZ/e-w-Ulcer_Index.html
#     Believe HHV described is not right, want highest up to each point in
#     the calculation, not of whole period.
#


sub longname   { __('Ulcer Index') }
sub shortname  { __('Ulcer') }
sub manual     { __p('manual-node','Ulcer Index') }

use constant
  { type       => 'indicator',
    units      => 'percentage',
    minimum    => 0,
    parameter_info => [ { name     => __('Days'),
                          key      => 'ulcer_days',
                          type     => 'integer',
                          minimum  => 1,
                          # don't know a good default, this is arbitrary
                          default  => 60 }],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "Ulcer bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count;  # $N-1

sub ulcer_on_aref {
  my ($aref) = @_;
  if (@$aref <= 1) { return 0; }
  my $high = $aref->[-1];
  my $sumsq = 0;
  for (my $i = $#$aref - 1; $i >= 0; $i--) {
    my $value = $aref->[$i];
    if ($value >= $high) {
      $high = $value;
    } elsif ($high != 0) {
      # percent decline
      $sumsq += (100 * ($high - $value) / $high) ** 2;
    }
  }
  return sqrt ($sumsq / scalar @$aref);
}

sub proc {
  my ($class_or_self, $N) = @_;
  my @array;

  return sub {
    my ($value) = @_;
    unshift @array, $value;
    if (@array > $N) { pop @array; }
    return ulcer_on_aref(\@array);
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Ulcer -- ulcer index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Ulcer($N);
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
