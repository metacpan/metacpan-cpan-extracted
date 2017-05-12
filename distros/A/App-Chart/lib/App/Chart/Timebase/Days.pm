# Copyright 2007, 2008, 2009 Kevin Ryde

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


package App::Chart::Timebase::Days;
use strict;
use warnings;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use base 'App::Chart::Timebase';

sub new_from_ymd {
  my ($class, $year, $month, $day) = @_;
  return $class->SUPER::new
    (base => App::Chart::ymd_to_tdate_floor ($year, $month, $day));
}

sub to_ymd {
  my ($self, $t) = @_;
  return App::Chart::tdate_to_ymd ($t + $self->{'base'});
}

sub from_ymd_floor {
  my ($self, $year, $month, $day) = @_;
  return App::Chart::ymd_to_tdate_floor ($year, $month, $day)
    - $self->{'base'};
}

sub from_ymd_ceil {
  my ($self, $year, $month, $day) = @_;
  return App::Chart::ymd_to_tdate_ceil ($year, $month, $day)
    - $self->{'base'};
}

sub adjective { return __('Daily'); }

1;
