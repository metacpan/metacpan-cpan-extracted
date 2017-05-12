# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::Volume;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');
use base 'App::Chart::Series::Indicator';

use constant DEBUG => 0;

sub longname  { __('Volume') }
*shortname = \&longname;
# FIXME
# sub manual    { __p('manual-node','Volume and Open Interest') }

use constant
  { type       => 'indicator',
    units      => 'volume',
    priority   => 10,
    minimum    => 0,
    decimals   => 0,  # no decimals normally
    default_linestyle => 'Bars',
  };

sub new {
  my ($class, $parent) = @_;

  my $p = $parent->array('volumes')
    || croak "No volumes in series '",$parent->name,"'";
  return $class->SUPER::new (parent => $parent,
                             arrays => { values => $p });
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};
  $parent->fill_part ($lo, $hi);
}

# Return (LOWER UPPER) which is a suggested initial Y-axis page range to
# show for dates LO to HI.  This is for use with trading volumes and also
# open-interest.
#
# The page size is meant to keep average to high volume days visible in the
# window, but leave abnormally high days off the top of the screen so as not
# to make the average ones come out tiny.
#
# The rule is to look for the 98% fractile, meaning a level which covers 98%
# of the values in the LO to HI range, then an extra 1.5x that much.  Making
# UPPER just the 0.98 fractile alone would guarantee two or three points off
# the top of the window even if they're only modestly bigger than the
# average, hence going up to 1.5x that point.
#
#
# ENHANCE-ME: If LO to HI is small then maybe the 98% should be reduced a
# bit.  If the width is less than 50 (or is it 25?) dates then 98% ends up
# meaning every data point.
#
sub initial_range {
  my ($self, $lo, $hi) = @_;
  if (DEBUG) { print "Volume initial range\n"; }
  $lo = max ($lo, 0);
  $hi = max ($hi, 0);

  $self->fill ($lo, $hi);
  my $values = $self->values_array;
  my @v = grep{defined} @{$values}[$lo..$hi];

  if (defined (my $symbol = $self->symbol)) {
    my $latest = App::Chart::Latest->get($symbol);
    my $timebase = $self->timebase;
    if (defined $latest->{'volume'}
        && defined (my $last_iso = $latest->{'last_date'})) {
      my $last_t = $timebase->from_iso_floor ($last_iso);
      if ($last_t >= $lo && $last_t <= $hi) {
        push @v, $latest->{'volume'};
      }
    }
  }

  if (! @v) {
    return; # no non-undef values at all
  }

  # ENHANCE-ME: the top few values can probably be found without a full sort
  my $lastval = $v[-1];
  @v = sort {$a <=> $b} @v;

  return (0, max (0,
                  $lastval,        # always fit last value
                  $v[$#v * 0.98],  # fractile
                  1.5 * List::Util::sum (@v) / scalar @v)); # 1.5*mean
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Volume -- trading volume series
# 
# =head1 SYNOPSIS
# 
#  my $vol = $series->Volume;
# 
# =head1 CLASS HIERARCHY
# 
#     App::Chart::Series
#       App::Chart::Series::Derived::Volume
# 
# =head1 DESCRIPTION
# 
# A C<App::Chart::Series::Derived::Volume> series picks out just the volumes
# from a series.  Usually this will be a database series
# (C<App::Chart::Series::Database>), but anything with a C<volumes> array can
# be used.  A Volumes series allows those volume values to be passed into
# other series calculations or displays.
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Database>
# 
# =cut
