# Copyright (C) 2021  Alex Schroeder <alex@gnu.org>
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

our @use = qw(PageHeadings);

require './t/test.pl';

# variables set by test.pl
our $base;
our $dir;
our $host;
our $port;

my $titan = "titan://$host:$port";

my $haiku = <<EOT;
# Hurt
When I type, it hurts
When I do not type, it hurts
My fingers, they hurt
EOT

# create a regular page, including updating the page index
like(query_gemini("$titan/raw/2021-07-16;size=80;mime=text/plain;token=hello", $haiku),
     qr/^30/, "Page redirect after save");
like(query_gemini("$base/page/2021-07-16"),
     qr/^20 text\/gemini; charset=UTF-8\r\n# Hurt\n/, "Page name not used as title");
like(query_gemini("$base/"),
     qr/^=> $base\/page\/2021-07-16 Hurt/m, "Date page listed");

done_testing;
