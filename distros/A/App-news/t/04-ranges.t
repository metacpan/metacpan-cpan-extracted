# Copyright (C) 2023  Alex Schroeder <alex@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Modern::Perl;
use Test::More;
use App::news qw(ranges sranges);

is(sranges(ranges(1)), "1", "one");
is(sranges(ranges(1,2)), "1-2", "two");
is(sranges(ranges(1,2,3,4)), "1-4", "four");
is(sranges(ranges(2,3,4)), "2-4", "two-four");
is(sranges(ranges(1,3,4)), "1,3-4", "missing two");
is(sranges(ranges(1,2,4)), "1-2,4", "missing three");
is(sranges(ranges(1,4)), "1,4", "missing two and three");
is(sranges(ranges(1,2,4,5,7)), "1-2,4-5,7", "various");

done_testing;
