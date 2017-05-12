#!/usr/bin/perl -w

# Copyright 2010, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Smart::Comments;
use Hash::Util::FieldHash;
my $obj = [];

my @active = Hash::Util::FieldHash::_active_fields($obj);
### @active

my %h;
Hash::Util::FieldHash::fieldhashes (\%h);
$h{$obj} = 123;
### h: $h{$obj}

@active = Hash::Util::FieldHash::_active_fields($obj);
### @active
