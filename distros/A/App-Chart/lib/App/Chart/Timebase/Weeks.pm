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


package App::Chart::Timebase::Weeks;
use strict;
use warnings;
use Date::Calc;
use Locale::TextDomain ('App-Chart');
use POSIX ();

use base 'App::Chart::Timebase';

sub new_from_ymd {
  my ($class, $year, $month, $day) = @_;
  return $class->SUPER::new
    (base => ymd_to_wdate_floor ($year, $month, $day));
}

sub to_ymd {
  my ($self, $t) = @_;
  return Date::Calc::Add_Delta_Days (1970,1,5, 7 * ($t + $self->{'base'}));
}

sub from_ymd_floor {
  my ($self, $year, $month, $day) = @_;
  return ymd_to_wdate_floor ($year, $month, $day) - $self->{'base'};
}
sub from_ymd_ceil {
  my ($self, $year, $month, $day) = @_;
  return ymd_to_wdate_ceil ($year, $month, $day) - $self->{'base'};
}

sub adjective { return __('Weekly'); }


#------------------------------------------------------------------------------

my $CDAYS_5Jan1970 = Date::Calc::Date_to_Days (1970, 1, 5);

sub ymd_to_wdate_floor {
  my ($year, $month, $day) = @_;
  return POSIX::floor
    ((Date::Calc::Date_to_Days ($year, $month, $day) - $CDAYS_5Jan1970) / 7);
}
sub ymd_to_wdate_ceil {
  my ($year, $month, $day) = @_;
  return POSIX::ceil
    ((Date::Calc::Date_to_Days ($year, $month, $day) - $CDAYS_5Jan1970) / 7);
}


1;
