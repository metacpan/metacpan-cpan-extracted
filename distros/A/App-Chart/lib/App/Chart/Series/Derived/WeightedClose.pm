# Copyright 2008, 2009, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::WeightedClose;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Scalar::Util;
use Locale::TextDomain ('App-Chart');

use App::Chart::Database;
use App::Chart::TZ;
use base 'App::Chart::Series::Indicator';


sub longname   { __('Weighted Close (H+L+2*C)/4') }
sub shortname  { __('WCL') }
sub manual     { __p('manual-node','Weighted Close') }

use constant
  { type       => 'selector',
  };

sub new {
  my ($class, $parent) = @_;
  if (! $parent->array('highs') && ! $parent->array('lows')) {
    return $parent;
  }
  return $class->SUPER::new
    (parent => $parent,
     arrays => { values => [] },
     array_aliases => { });
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  $parent->fill ($lo, $hi);
  my $closes = $parent->values_array;
  my $highs  = $parent->array('highs') || $closes;
  my $lows   = $parent->array('lows')  || $closes;
  my $s = $self->values_array;

  $hi = min ($hi, $#$closes);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  foreach my $i ($lo .. $hi) {
    my $close = $closes->[$i] // next;

    # mean (H+L+2*C)/4
    $s->[$i] = (($lows->[$i]  // $close)
                + ($highs->[$i] // $close)
                + 2 * $close) / 4;
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::WeightedClose -- weighted close (H+L+2*C)/4
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->typical;
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
