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
use utf8; # tests contain UTF-8

my $msg;
if (not $ENV{TEST_AUTHOR}) {
  $msg = 'Contributions are an author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
}
plan skip_all => $msg if $msg;

our @use = qw(Ijirait);
our $base;
our $port;
our $dir;
require './t/test.pl';

my $page = query_gemini("$base/play/ijirait");
like($page, qr(^20), "Ijirait");
like($page, qr(Ijiraq said “Welcome!”), "Welcome");

$page = query_gemini("$base/play/ijirait/examine?Ijiraq");
like($page, qr(^# Ijiraq)m, "Heading");
like($page, qr(^A shape-shifter with red eyes\.)m, "Description");

$page = query_gemini("$base/play/ijirait/type?say Hello");
like($page, qr(said “Hello”), "Hello");

$page = query_gemini("$base/play/ijirait/go?out");
like($page, qr(^30), "Redirect after a move");

$page = query_gemini("$base/play/ijirait/look");
like($page, qr(^# Outside The Tent)m, "Outside");

$page = query_gemini("$base/play/ijirait/go?tent");
like($page, qr(^30), "Redirect after a move");

$page = query_gemini("$base/play/ijirait/look");
like($page, qr(^# The Tent)m, "Back inside");

$page = query_gemini("$base/play/ijirait/name?me%20Alex");
like($page, qr(^30)m, "Redirect after name");

$page = query_gemini("$base/play/ijirait/look");
like($page, qr(Alex \(you\))m, "Renamed");

# use the type command for a change
$page = query_gemini("$base/play/ijirait/type?describe%20me%20I%E2%80%99m%20cool%2E");
like($page, qr(^30)m, "Redirect after describe");

$page = query_gemini("$base/play/ijirait/examine?Alex");
like($page, qr(^# Alex$)m, "Name");
like($page, qr(^I’m cool\.)m, "Description");

$page = query_gemini("$base/play/ijirait/name?room%20Computer");
like($page, qr(^30)m, "Redirect after name");

$page = query_gemini("$base/play/ijirait/look");
like($page, qr(^# Computer)m, "Renamed");

$page = query_gemini("$base/play/ijirait/describe?room%20Rows%20and%20rows%20of%20transistors.");
like($page, qr(^30)m, "Redirect after describe");

$page = query_gemini("$base/play/ijirait/look");
like($page, qr(^Rows and rows of transistors\.)m, "Described");

$page = query_gemini("$base/play/ijirait/create?room");
like($page, qr(^30)m, "Redirect after room creation");

$page = query_gemini("$base/play/ijirait/look");
like($page, qr(A tunnel \(tunnel\))m, "Tunnel");

$page = query_gemini("$base/play/ijirait/name?tunnel%20A%20hole%20in%20the%20ground%20%28hole%29");
like($page, qr(^30)m, "Redirect after name");

$page = query_gemini("$base/play/ijirait/look");
like($page, qr(A hole in the ground \(hole\))m, "Hole");

$page = query_gemini("$base/play/ijirait/go?hole");
like($page, qr(^30), "Redirect after a move");

$page = query_gemini("$base/play/ijirait/look");
like($page, qr(^# Lost in fog)m, "New room name");
like($page, qr(^Dense fog surrounds you\.)m, "New room description");

$page = query_gemini("$base/play/ijirait/rooms");
like($page, qr(^\* Lost in fog)m, "Fog");
like($page, qr(^\* Computer)m, "Computer");

$page = query_gemini("$base/play/ijirait/who");
like($page, qr(^\* Ijiraq)m, "Ijiraq");
like($page, qr(^\* Alex)m, "Alex");

$page = query_gemini("$base/play/ijirait/create?thing");
like($page, qr(^30)m, "Redirect after thing creation");

$page = query_gemini("$base/play/ijirait/look");
like($page, qr(A small stone \(stone\))m, "Stone");

$page = query_gemini("$base/play/ijirait/name?stone%20Clay%20Tablet%20%28tablet%29");
like($page, qr(^30)m, "Redirect after name");

$page = query_gemini("$base/play/ijirait/look");
like($page, qr(^=> \S+ Clay Tablet \(tablet\))m, "Renamed");

$page = query_gemini("$base/play/ijirait/describe?tablet%20The%20cuneiform%20script%20is%20undecipherable.");
like($page, qr(^30)m, "Redirect after describe");

$page = query_gemini("$base/play/ijirait/examine?tablet");
like($page, qr(^The cuneiform script is undecipherable\.)m, "Described");

done_testing();
