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
use App::news qw(wrap);

is(wrap("Short line"), "Short line\n", "short");

my $haiku = <<EOT;
A long line lingers
It trails off softly as I
Hear the children play
EOT

is(wrap($haiku), $haiku, "poems do not wrap");

my $long = "Short lines drum along and fret and shove and push me to just shut my mouth";

is(wrap($long), "Short lines drum along and fret and shove and push me to just shut my\nmouth\n", "wrap");

my $mail = <<EOT;
Alex wrote:
> I'm once again writing haikus for my unit tests. I'm unsure of I could
> add a season word to this one. Any suggestions?
>
> Short lines drum along
> and fret and shove and push me
> to just shut my mouth

Maybe the short lines push me "to just keep running"? example.poetry.slam is a site that looks interesting.
EOT

my $wrapped = <<EOT;
Alex wrote:
> I'm once again writing haikus for my unit tests. I'm unsure of I could
> add a season word to this one. Any suggestions?
>
> Short lines drum along
> and fret and shove and push me
> to just shut my mouth

Maybe the short lines push me "to just keep running"?
example.poetry.slam is a site that looks interesting.
EOT

is(wrap($mail), $wrapped, "mail with quotes");

done_testing;
