# Copyright 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::TypicalPrice;
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

sub longname  { __('Typical Price (H+L+C)/3') }
sub shortname { __('Typ') }
sub manual    { __p('manual-node','Typical Price') }

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

*fill_part = \&App::Chart::Series::Derived::WilliamsR::fill_part;
use constant warmup_count => 0;

sub proc {
  my ($class_or_self) = @_;
  return \&typical_price;
}
sub typical_price {
  my ($high, $low, $close) = @_;
  return (($high//$close) + ($low//$close) + $close) / 3;
}

# sub fill_part {
#   my ($self, $lo, $hi) = @_;
#   my $parent = $self->{'parent'};
# 
#   $parent->fill ($lo, $hi);
#   my $closes = $parent->values_array;
#   my $highs  = $parent->array('highs') || $closes;
#   my $lows   = $parent->array('lows')  || $closes;
#   my $s = $self->values_array;
# 
#   $hi = min ($hi, $#$closes);
#   if ($#$s < $hi) { $#$s = $hi; }  # pre-extend
# 
#   foreach my $i ($lo .. $hi) {
#     my $close = $closes->[$i] // next;
# 
#     # mean (H+L+C)/3
#     $s->[$i] = (($lows->[$i]  // $close)
#                 + ($highs->[$i] // $close)
#                 + $close) / 3;
#   }
# }

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::TypicalPrice -- typical price (H+L+C)/3
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
