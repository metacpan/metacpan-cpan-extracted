#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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
use 5.010;
use App::Chart::IndicatorInfo;
use Data::Dumper;

foreach my $key ('SMA', 'GT_SMA', 'GT_BOL', 'TA_SMA', 'TA_BBANDS', 'TA_PPO') {
  say $key;
  my $info = App::Chart::IndicatorInfo->new ($key);
  print Data::Dumper->Dump([$info],['info']);

  my $module = $info->module;
  print Data::Dumper->Dump([$module],['module']);

  my $manual = $info->manual;
  print Data::Dumper->Dump([$manual],['manual']);

  my $params = $info->parameter_info;
  print Data::Dumper->Dump([$params],['params']);
}

exit 0;
