#!/usr/bin/perl -w

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


use strict;
use warnings;
use Test::More tests => 1;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Suffix::MLC;

{
  my $symbol = 'FOO.MLC';
  my @handler_list = App::Chart::DownloadHandler->handlers_for_symbol ($symbol);
  is (scalar @handler_list, 1);
}

#------------------------------------------------------------------------------
# available_tdate

# foreach my $elem (['2005-01-06T12:00:00', '2005-01-04'],  # Thursday
#                   ['2005-01-07T12:00:00', '2005-01-05'],  # Friday
#                   ['2005-01-08T12:00:00', '2005-01-06'],  # Saturday
#                   ['2005-01-09T12:00:00', '2005-01-06'],  # Sunday
#                   ['2005-01-10T12:00:00', '2005-01-06'],  # Monday
#                   ['2005-01-11T12:00:00', '2005-01-07'],  # Tuesday
#                   ['2005-01-12T12:00:00', '2005-01-10'],  # Wednesday
#                  ) {
#   my ($current_time, $want_date) = @_;
#   $TZ = $sydney;
#   Test::MockTime::set_fixed_time ($current_time);
# 
#   is (App::Chart::Suffix::MLC::available_date(),
#       $want_date,
#       "available_date() at $current_time");
# }

exit 0;
