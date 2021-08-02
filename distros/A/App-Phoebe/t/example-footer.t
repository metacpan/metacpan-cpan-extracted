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

like(query_gemini("$base/page/Test"),
     qr/^=> mailto:alex\@alexschroeder.ch Mail/m, "Footer is served (Gemini)");

like(query_web("GET /page/Test HTTP/1.0\r\nhost: $host:$port"),
     qr/^<li><a href="mailto:alex\@alexschroeder.ch">Mail<\/a>/m, "Footer is served (Web)");

done_testing;
