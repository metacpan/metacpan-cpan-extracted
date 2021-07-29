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

my $page = query_gemini("$base/");
like($page, qr/^=> gemini:\/\/localhost\/do\/test Test$/m, "Footer in the main menu");

$page = query_web("GET / HTTP/1.0\r\nhost: $host:$port");
unlike($page, qr/Test/, "No changes in the footer for the web");

done_testing;
