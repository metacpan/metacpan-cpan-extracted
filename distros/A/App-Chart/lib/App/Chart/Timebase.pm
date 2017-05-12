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

package App::Chart::Timebase;
use 5.004;
use strict;
use warnings;
use Date::Calc;
use POSIX ();  # no exports avoids clash with new strftime below
use POSIX::Wide;
# use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::TZ;

sub new {
  my $class = shift;
  return bless { @_ }, $class;
}

sub new_from_iso {
  my ($class, $iso) = @_;
  my ($year, $month, $day) = App::Chart::iso_to_ymd ($iso);
  return $class->new_from_ymd ($year, $month, $day);
}

sub new_from_timebase {
  my ($class, $timebase) = @_;
  my ($year, $month, $day) = $timebase->to_ymd (0);
  return $class->new_from_ymd ($year, $month, $day);
}

sub to_iso {
  my ($self, $t) = @_;
  my ($year, $month, $day) = $self->to_ymd ($t);
  return App::Chart::ymd_to_iso ($year, $month, $day);
}

sub from_iso_floor {
  my ($self, $str) = @_;
  my ($year, $month, $day) = App::Chart::iso_to_ymd ($str);
  return $self->from_ymd_floor ($year, $month, $day);
}

sub from_iso_ceil {
  my ($self, $str) = @_;
  my ($year, $month, $day) = App::Chart::iso_to_ymd ($str);
  return $self->from_ymd_ceil ($year, $month, $day);
}

sub convert_from_floor {
  my ($self, $from_timebase, $from_t) = @_;
  my ($year, $month, $day) = $from_timebase->to_ymd ($from_t);
  return $self->from_ymd_floor ($year, $month, $day);
}

sub convert_from_ceil {
  my ($self, $from_timebase, $from_t) = @_;
  return $self->convert_from_floor ($from_timebase, $from_t + 1) - 1;
}

sub strftime {
  my ($self, $format, $date) = @_;
  return strftime_ymd ($format, $self->to_ymd ($date));
}

sub strftime_ymd {
  my ($format, $year, $month, $day) = @_;
  return POSIX::Wide::strftime
    ($format, 0,0,0,
     $day, $month-1, $year-1900,
     Date::Calc::Day_of_Week ($year,$month,$day) % 7,
     Date::Calc::Day_of_Year ($year,$month,$day),
     -1); # isdst
}

sub today {
  my ($self, $timezone) = @_;
  $timezone ||= App::Chart::TZ->loco;
  my ($year, $month, $day) = $timezone->ymd;
  return $self->from_ymd_floor ($year, $month, $day);
}

sub today_ceil {
  my ($self, $timezone) = @_;
  $timezone ||= App::Chart::TZ->loco;
  my ($year, $month, $day) = $timezone->ymd;
  return $self->from_ymd_ceil ($year, $month, $day);
}

1;
__END__

=for stopwords timebases ie internationalizations

=head1 NAME

App::Chart::Timebase -- timebases

=head1 SYNOPSIS

 use App::Chart::Timebase;

=head1 DESCRIPTION

A C<App::Chart::Timebase> object represents a date/time period and a starting
point.

Dates in a timebase are integers starting from 0 for the starting point.
For example a timebase might be weeks starting from 19 Nov 2007, in which
case that week is 0, the following week is 1, etc.  Methods on the timebase
objects allow conversion of year/month/day dates to or from such an index
number.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Timebase::Days->new_from_iso ($start) >>

=item C<< App::Chart::Timebase::Weeks->new_from_iso ($start) >>

=item C<< App::Chart::Timebase::Months->new_from_iso ($start) >>

=item C<< App::Chart::Timebase::Quarters->new_from_iso ($start) >>

=item C<< App::Chart::Timebase::Years->new_from_iso ($start) >>

=item C<< App::Chart::Timebase::Decades->new_from_iso ($start) >>

Create and return a new timebase object representing the given
days/weeks/etc type of period, and with a 0 at the given C<$start> date.
C<$start> is an ISO format string like "2007-12-31".

Days means weekdays, ie. trading days.  Weeks is calendar weeks starting
from each Monday, through to the following Sunday.  Months is calendar
months.  Quarters are calendar quarters like Jan/Feb/Mar then Apr/May/Jun,
etc.

=item C<< $timebase->to_iso ($t) >>

Return an ISO date string like "2007-12-31" for the given C<$t> timebase
index (an integer).  For example,

    my $timebase = App::Chart::Timebase::Days->new_from_iso ('2008-05-01');
    my $iso = $timebase->to_iso (5);
    # $iso is '2008-05-08'  (weekday 5 counting from 0 at 1 May)

=item C<< $timebase->from_ymd_floor ($year, $month, $day) >>

=item C<< $timebase->from_iso_floor ($str) >>

=item C<< $timebase->from_iso_ceil ($str) >>

Return a time value (an integer) in C<$timebase> which corresponds to the
given date, either as values C<$year>, C<$month> and C<$day>, or an ISO date
string C<$str> like "2007-12-31".

If the date is not representable in C<$timebase>, then for C<floor> the
return is the next earlier timebase value or for C<ceil> the next later.
This only arises on a C<Days> timebase when the date requested is a Saturday
or Sunday.  In that case C<floor> gives the preceding Friday or C<ceil> the
following Monday.

=item C<< $timebase->convert_from_floor ($from_timebase, $from_t) >>

=item C<< $timebase->convert_from_ceil ($from_timebase, $from_t) >>

Convert an time value in C<$from_timebase> to a value in C<$timebase>.  The
two timebases can have different starting points and different units, such
as converting a day number into a week number.

When the destination C<$timebase> is a higher resolution than
C<$from_timebase> the C<convert_from_floor> version gives the start of the
C<$from_t> period and the C<convert_from_ceil> version gives the end.  For
example if C<$from_timebase> is years but the destination C<$timebase> is
months then C<floor> gives the first month (ie. January) in the C<$from_t>
year and C<ceil> gives the last month (ie. December).

=item $timebase->strftime ($format, $t)

Return an C<strftime> formatted string which is timebase value C<$t> (an
integer) under C<$format>.  For example,

    $timebase->strftime ('%d %b %Y', $t)
    # gives say "31 December 2007"

=item $timebase->today ()

=item $timebase->today ($timezone)

Return today's date as an integer in C<$timebase>.  The optional
C<$timezone> is a C<App::Chart::TZ> object to use, or the default is
local time.

=item C<< $timebase->adjective() >>

Return a string which is an adjective for the C<$timebase>.  For example on
a years timebase the return would be C<"Yearly">.  The string is translated
through the usual Chart internationalizations if possible.

=back

=cut
