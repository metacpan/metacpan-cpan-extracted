#!/usr/bin/perl -w

# 0-Test-CheckChanges.t -- run Test::CheckChanges if available

# Copyright 2009, 2011, 2014 Kevin Ryde

# 0-Test-CheckChanges.t is shared by several distributions.
#
# 0-Test-CheckChanges.t is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# 0-Test-CheckChanges.t is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Test::More;

# This is very much an author test, but might stop an undescribed version
# getting out.

# version 0.08 for "Version N"
eval 'use Test::CheckChanges 0.08; 1'
  or plan skip_all => "due to Test::CheckChanges 0.08 not available -- $@";

Test::CheckChanges::ok_changes();
exit 0;
