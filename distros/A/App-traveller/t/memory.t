#!/usr/bin/env perl

# Copyright (C) 2021 Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

use Modern::Perl;
use Test::More;
use Test::Memory::Cycle;
use Traveller::Util qw(flush);

require './script/traveller';

my $subsector = Traveller::Subsector->new()->init(32, 40, 'mgp', 0.5);
my $uwp = $subsector->str;

like($uwp, qr/^\w+\s+\d+\s+[A-EX][0-9A-F]{6}-(\d|1\d)\s+/, "UWP");

memory_cycle_ok($subsector, "No circular memory references");

done_testing();
