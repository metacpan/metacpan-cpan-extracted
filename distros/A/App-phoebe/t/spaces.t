# Copyright (C) 2017–2020  Alex Schroeder <alex@gnu.org>
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
use File::Slurper qw(write_text write_binary read_binary);

our $host;
our @spaces = qw(alex berta);
our @pages = qw(Alex);
our $port;
our $base;
our $dir;
our $pid;

require './t/test.pl';

# set up the main space with some test data

mkdir("$dir/page");
write_text("$dir/page/Alex.gmi", "Alex Schroeder");
mkdir("$dir/file");
write_binary("$dir/file/alex.jpg", read_binary("t/alex.jpg"));
mkdir("$dir/meta");
write_text("$dir/meta/alex.jpg", "content-type: image/jpeg");
write_text("$dir/index", join("\n", "Haiku", "Alex", ""));
write_text("$dir/changes.log",
	   join("\n",
		join("\x1f", 1593600755, "Alex", 1, 1441),
		join("\x1f", 1593610755, "alex.jpg", 0, 1441),
		join("\x1f", 1593620755, "Haiku", 1, 1441),
		""));

# test the main space

my $page = query_gemini("$base/");
like($page, qr/^=> $base\/page\/Alex Alex/m, "main menu contains Alex");
$page = query_gemini("$base/page/Alex");
like($page, qr/^Alex Schroeder/m, "Alex page was created");
$page = query_gemini("$base/file/alex.jpg");
like($page, qr/^20 image\/jpeg\r\n/, "alex.jpg file was created");

# verify that the alex space has different page content

$page = query_gemini("$base/alex");
like($page, qr/^=> $base\/alex\/page\/Alex Alex/m, "main menu contains Alex");
$page = query_gemini("$base/alex/page/Alex");
like($page, qr/^This page does not yet exist/m, "Alex page is empty in the alex space");

# redirect of reserved word
$page = query_gemini("$base/alex/do");
is($page, "31 $base/alex\r\n", "Redirect reserved word");

# upload

my $titan = "titan://$host:$port";

my $haiku = <<EOT;
Outside children shout
Everybody is running
Recess is the best
EOT

$page = query_gemini("$titan/alex/raw/Haiku;size=63;mime=text/plain;token=hello", $haiku);
like($page, qr/^30 $base\/alex\/page\/Haiku\r$/, "Titan Haiku");

$page = query_gemini("$base/alex/page/Haiku");
like($page, qr/^20 text\/gemini; charset=UTF-8\r\n# Haiku\n$haiku/, "Haiku saved");

$page = query_gemini("$base/page/Haiku");
like($page, qr/^This page does not yet exist/m, "Haiku page is empty in the main space");

ok(-f "$dir/alex/page/Haiku.gmi", "alex/page/Haiku.gmi exists");
ok(-f "$dir/alex/changes.log", "alex/changes.log exists");
ok(-f "$dir/alex/index", "alex/index exists");

$page = query_gemini("$base/alex/do/match?Haiku");
like($page, qr/^=> $base\/alex\/page\/Haiku Haiku/m, "Haiku found by name match");

$page = query_gemini("$base/alex/do/search?Schroeder");
like($page, qr/Search term not found/, "Alex not found in the alex space");
$page = query_gemini("$base/alex/do/search?Everybody");
like($page, qr/^=> $base\/alex\/page\/Haiku Haiku/m, "Haiku found in the alex space");

$page = query_gemini("$base/do/search?Schroeder");
like($page, qr/^=> $base\/page\/Alex Alex/m, "Alex found in the main space");

$page = query_gemini("$base/alex/history/Haiku");
like($page, qr/^=> $base\/alex\/page\/Haiku Haiku \(current\)/m, "Current version of Haiku found in the alex space history");

$page = query_gemini("$base/alex/do/changes");
like($page, qr/^=> $base\/alex\/page\/Haiku Haiku/m, "Haiku found in the alex space changes");

$page = query_gemini("$base/alex/do/rss");
like($page, qr/<link>$base\/alex\/page\/Haiku<\/link>/, "Haiku found in the alex space RSS feed");

$page = query_gemini("$base/alex/do/atom");
like($page, qr/<link href="$base\/alex\/page\/Haiku"\/>/, "Haiku found in the alex space Atom feed");

$page = query_gemini("$base/do/all/changes");
like($page, qr/^=> $base\/page\/Alex Alex/m, "Alex found in unified changes");
like($page, qr/^=> $base\/alex\/page\/Haiku/m, "Haiku found in unified changes");

$page = query_gemini("$base/do/spaces");
like($page, qr/^=> $base\/alex\/ alex/m, "Space alex found");

# add a special token to the alex space via config file

open(my $config, ">>", "$dir/config");
say $config 'push(@init, sub{ my $self = shift; $self->{server}->{wiki_token} = []; $self->{server}->{wiki_space_token}->{alex} = ["*secret*"]});';
close($config);
is(kill('HUP', $pid), 1, "Restarted server");
sleep 1;

$haiku = <<EOT;
Rattling keys and quiet
Fingers hover in the air
Outside, a full moon
EOT

$page = query_gemini("$titan/alex/raw/Haiku;size=70;mime=text/plain;token=hello", $haiku);
# in this situation the client simply returns undef!?
# like($page, /^59 Your token is the wrong token\r$/, "Can no longer save");
$page = query_gemini("$base/alex/page/Haiku");
like($page, qr/Outside children shout/, "Save with old token failed");

$page = query_gemini("$titan/alex/raw/Haiku;size=70;mime=text/plain;token=*secret*", $haiku);
like($page, qr/^30 $base\/alex\/page\/Haiku\r$/, "Titan Haiku");

done_testing();
