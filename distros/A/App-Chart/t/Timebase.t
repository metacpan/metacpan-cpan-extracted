#!/usr/bin/perl -w

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

use strict;
use warnings;
use Test::More tests => 33;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

{
  require App::Chart::Timebase::Days;
  my $tb = App::Chart::Timebase::Days->new_from_ymd (1970, 1, 5);
  ok ($tb);
  is ($tb->from_iso_floor ('1970-01-05'), 0);
  is ($tb->to_iso (0), '1970-01-05');
  is ($tb->from_ymd_floor (1970,1,5), 0);
}

{
  require App::Chart::Timebase::Weeks;
  my $tb = App::Chart::Timebase::Weeks->new_from_ymd (1970, 1, 5);
  ok ($tb);
  is ($tb->from_iso_floor ('1970-01-05'), 0);
  is ($tb->to_iso (0), '1970-01-05');
  is ($tb->from_ymd_floor (1970,1,5), 0);
}

{
  require App::Chart::Timebase::Months;
  my $tb = App::Chart::Timebase::Months->new_from_ymd (1970, 1, 1);
  ok ($tb);
  is ($tb->from_iso_floor ('1970-01-01'), 0);
  is ($tb->to_iso (0), '1970-01-01');
  is ($tb->from_ymd_floor (1970,1,1), 0);
  is ($tb->from_ymd_floor (1970,4,1), 3);
}

is (App::Chart::Timebase::Months::ymd_to_mdate(1970,1,1), 0);
is (App::Chart::Timebase::Months::ymd_to_mdate(1970,2,1), 1);
is (App::Chart::Timebase::Months::ymd_to_mdate(1971,1,1), 12);


{
  require App::Chart::Timebase::Quarters;
  my $tb = App::Chart::Timebase::Quarters->new_from_ymd (1970, 1, 1);
  ok ($tb);
  is ($tb->from_iso_floor ('1970-01-01'), 0);
  is ($tb->to_iso (0), '1970-01-01');
  is ($tb->from_ymd_floor (1970,1,1), 0);
  is ($tb->from_ymd_floor (1970,4,1), 1);
}

{
  require App::Chart::Timebase::Years;
  my $tb = App::Chart::Timebase::Years->new_from_ymd (1970, 1, 1);
  ok ($tb);
  is ($tb->from_iso_floor ('1970-01-01'), 0);
  is ($tb->to_iso (0), '1970-01-01');
  is ($tb->from_ymd_floor (1970,1,1), 0);
  is ($tb->from_ymd_floor (1970,4,1), 0);
  is ($tb->from_ymd_floor (1971,1,1), 1);
}

{
  require App::Chart::Timebase::Decades;
  my $tb = App::Chart::Timebase::Decades->new_from_ymd (1970, 1, 1);
  ok ($tb);
  is ($tb->from_iso_floor ('1970-01-01'), 0);
  is ($tb->to_iso (0), '1970-01-01');
  is ($tb->from_ymd_floor (1970,1,1), 0);
  is ($tb->from_ymd_floor (1971,1,1), 0);
  is ($tb->from_ymd_floor (1980,1,1), 1);
}

exit 0;
