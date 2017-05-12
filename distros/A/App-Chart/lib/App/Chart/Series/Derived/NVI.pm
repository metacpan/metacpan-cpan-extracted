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

package App::Chart::Series::Derived::NVI;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::OBV;

# http://www.incrediblecharts.com/indicators/negative_volume_index.php
# http://www.incrediblecharts.com/indicators/positive_volume_index.php
#
# http://www.fosback.com/
#     Norman Fosback's web site (nothing on NVI).
#


sub longname  { __('NVI - Negative Volume Index') }
sub shortname { __('NVI') }
sub manual    { __p('manual-node','Negative Volume Index') }

use constant
  { type      => 'indicator',
    units     => 'NVI',
  };

sub new {
  my ($class, $parent) = @_;

  return $class->SUPER::new
    (parent => $parent,
     arrays => { values => [] },
     array_aliases => { },
     accumulate => 'multiply');
}

sub proc {
  my ($self) = @_;
  my $parent = $self->parent;
  my $pv = $parent->array('volumes') || [];
  sub {
    my ($i, $value, $prev_i, $prev_value) = @_;
    if ($prev_value == 0) { return 1; }
    my $volume = $pv->[$i] // 0;
    my $prev_volume = $pv->[$prev_i] // 0;
    if ($volume < $prev_volume) {
      return $value / $prev_value;
    } else {
      return 1;
    }
  };
}

*fill_part = \&App::Chart::Series::Derived::OBV::fill_part;

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::NVI -- negative volume indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->NVI;
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
