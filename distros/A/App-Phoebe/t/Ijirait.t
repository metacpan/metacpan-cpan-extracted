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
use List::Util qw(any);
use File::Slurper qw(read_binary);
use Mojo::JSON qw(decode_json);
use utf8; # tests contain UTF-8

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

like(query_gemini("$base/play/ijirait/type?say Hello"),
     qr(said “Hello”), "Hello");

like(query_gemini("$base/play/ijirait/go?out"),
     qr(^30), "Redirect after a move");

like(query_gemini("$base/play/ijirait/look"),
     qr(^# Outside The Tent)m, "Outside");

like(query_gemini("$base/play/ijirait/go?tent"),
     qr(^30), "Redirect after a move");

like(query_gemini("$base/play/ijirait/look"),
     qr(^# The Tent)m, "Back inside");

like(query_gemini("$base/play/ijirait/name?me%20Alex"),
     qr(^30)m, "Redirect after name");

like(query_gemini("$base/play/ijirait/look"),
     qr(Alex \(you\))m, "Renamed");

# use the type command for a change
like(query_gemini("$base/play/ijirait/type?describe%20me%20I%E2%80%99m%20cool%2E"),
     qr(^30)m, "Redirect after describe");

$page = query_gemini("$base/play/ijirait/examine?Alex");
like($page, qr(^# Alex$)m, "Name");
like($page, qr(^I’m cool\.)m, "Description");

like(query_gemini("$base/play/ijirait/name?room%20Computer"),
     qr(^30)m, "Redirect after name");

like(query_gemini("$base/play/ijirait/look"),
     qr(^# Computer)m, "Renamed");

like(query_gemini("$base/play/ijirait/describe?room%20Rows%20and%20rows%20of%20transistors."),
     qr(^30)m, "Redirect after describe");

like(query_gemini("$base/play/ijirait/look"),
     qr(^Rows and rows of transistors\.)m, "Described");

like(query_gemini("$base/play/ijirait/create?room"),
     qr(^30)m, "Redirect after room creation");

like(query_gemini("$base/play/ijirait/look"),
     qr(A tunnel \(tunnel\))m, "Tunnel");

like(query_gemini("$base/play/ijirait/name?tunnel%20A%20hole%20in%20the%20ground%20%28hole%29"),
     qr(^30)m, "Redirect after name");

like(query_gemini("$base/play/ijirait/look"),
     qr(A hole in the ground \(hole\))m, "Hole");

like(query_gemini("$base/play/ijirait/go?hole"),
     qr(^30), "Redirect after a move");

$page = query_gemini("$base/play/ijirait/look");
like($page, qr(^# Lost in fog)m, "New room name");
like($page, qr(^Dense fog surrounds you\.)m, "New room description");

$page = query_gemini("$base/play/ijirait/rooms");
like($page, qr(^\* Lost in fog)m, "Fog");
like($page, qr(^\* Computer)m, "Computer");

$page = query_gemini("$base/play/ijirait/who");
like($page, qr(^\* Ijiraq)m, "Ijiraq");
like($page, qr(^\* Alex)m, "Alex");

like(query_gemini("$base/play/ijirait/create?thing"),
     qr(^30)m, "Redirect after thing creation");

like(query_gemini("$base/play/ijirait/look"),
     qr(A small stone \(stone\))m, "Stone");

like(query_gemini("$base/play/ijirait/name?stone%20Clay%20Tablet%20%28tablet%29"),
     qr(^30)m, "Redirect after name");

like(query_gemini("$base/play/ijirait/look"),
     qr(^=> \S+ Clay Tablet \(tablet\))m, "Renamed");

like(query_gemini("$base/play/ijirait/describe?tablet%20The%20cuneiform%20script%20is%20undecipherable."),
     qr(^30)m, "Redirect after describe");

like(query_gemini("$base/play/ijirait/examine?tablet"),
     qr(^The cuneiform script is undecipherable\.)m, "Described");

$page = query_gemini("$base/play/ijirait/id?tablet");
my ($thing) = $page =~ /^(\d+)$/m;
ok($thing, "Id thing");

# do it again, so we can check the seen array for duplicates later
query_gemini("$base/play/ijirait/examine?tablet");

$page = query_gemini("$base/play/ijirait/id?room");
my ($room) = $page =~ /^(\d+)$/m;
ok($room, "Id room");

$page = query_gemini("$base/play/ijirait/save");
like($page, qr(^Data was saved)m, "Save");

my $bytes = read_binary("$dir/ijirait.json");
my $data = decode_json $bytes;
is(scalar(@{$data->{people}}), 2, "Number of people");
my $found = any { $_ eq $room } @{$data->{people}->[1]->{seen}};
ok($found, "Seen room $room");

my @found = grep { $_ eq $thing } @{$data->{people}->[1]->{seen}};
is(scalar(@found), 1, "Seen tablet $thing once");

like(query_gemini("$base/play/ijirait/hide?tablet"),
     qr(^30 )m, "Hide tablet");

unlike(query_gemini("$base/play/ijirait/look"),
       qr(tablet), "Invisible tablet");

like(query_gemini("$base/play/ijirait/reveal?xxx"),
     qr(I don’t know what to reveal), "Unknown object");

like(query_gemini("$base/play/ijirait/reveal?tablet"),
     qr(^30 )m, "Reveal tablet");

like(query_gemini("$base/play/ijirait/look"),
     qr(tablet), "Visible tablet");

query_gemini("$base/play/ijirait/hide?tablet");

like(query_gemini("$base/play/ijirait/reveal?tablet%20to%20666"),
     qr(I don’t know how to reveal “to” something), "Wrong keyword");

like(query_gemini("$base/play/ijirait/reveal?tablet%20for%20666"),
     qr(666 does not refer to a known room or thing), "Wrong id");

like(query_gemini("$base/play/ijirait/reveal?tablet%20for%202"),
     qr(^30 ), "Revealed for id 2 (The Tent)");

like(query_gemini("$base/play/ijirait/look"),
     qr(tablet), "Revealed tablet");

like(query_gemini("$base/play/ijirait/forget?2"),
     qr(Computer \(2\)), "Forget 2");

unlike(query_gemini("$base/play/ijirait/forget"),
     qr(Computer), "Remains forgotten");

unlike(query_gemini("$base/play/ijirait/look"),
     qr(tablet), "Tablet is hidden again");

# debug
query_gemini("$base/play/ijirait/save");

done_testing();
