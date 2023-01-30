#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde

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
use App::Chart::Series::Calculation;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $linreg_proc = App::Chart::Series::Calculation->linreg(5);
  ### $linreg_proc
  foreach my $i (1 .. 10) {
    my @ret = $linreg_proc->($i % 2);
    ### @ret
  }
  exit 0;
}
