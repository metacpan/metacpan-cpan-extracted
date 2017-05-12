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


package App::Chart::Timebase::Quarters;
use strict;
use warnings;
use Locale::TextDomain ('App-Chart');
use POSIX ();

use base 'App::Chart::Timebase';
use App::Chart::Timebase::Months;

use constant MONTHS_PER_QUARTER => 3;

sub new_from_ymd {
  my ($class, $year, $month, $day) = @_;
  return $class->SUPER::new
    (base => ymd_to_qdate ($year, $month, $day));
}

sub to_ymd {
  my ($self, $t) = @_;
  return Date::Calc::Add_Delta_YM
    (1970,1,1, 0, MONTHS_PER_QUARTER * ($t + $self->{'base'}));
}

sub from_ymd_floor {
  my ($self, $year, $month, $day) = @_;
  return ymd_to_qdate ($year, $month, $day) - $self->{'base'};
}

sub adjective { return __('Quarterly'); }


#------------------------------------------------------------------------------
sub ymd_to_qdate {
  my ($year, $month, $day) = @_;
  return
    POSIX::floor (App::Chart::Timebase::Months::ymd_to_mdate($year,$month,$day)
                  / MONTHS_PER_QUARTER);
}


1;
