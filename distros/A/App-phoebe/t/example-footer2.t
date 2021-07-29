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

our $example = 1;

require './t/test.pl';

# variables set by test.pl
our $base;
our $host;
our $port;

my $page = query_gemini("$base/page/Test");
like($page, qr/^——————————$/m, "Horizontal line");
like($page, qr/^=> mailto:alex\@alexschroeder.ch Mail$/m, "Footer (Gemini)");

$page = query_web("GET /page/Test HTTP/1.0\r\nhost: $host:$port");
like($page, qr/^<li><a href="https:\/\/alexschroeder.ch\/wiki\/Contact">Contact<\/a>/m, "Different footer (web)");
unlike($page, qr/Mail/, "No mail in footer (Web)");

done_testing;
