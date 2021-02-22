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
our @hosts = qw(127.0.0.1 localhost);
our @spaces = qw(127.0.0.1/alex localhost/berta);
our @pages = qw(Alex);
our $port;
our $base;
our $dir;

require './t/test.pl';

# robots
my $page = query_gemini("$base/robots.txt");
my @urls = qw(/raw /html /diff /history /do/changes /do/all/changes /do/all/latest/changes /do/rss /do/atom /do/new /do/more /do/match /do/search);
for (map { ($_, "/alex$_", "/berta$_") } @urls) {
  my $url = quotemeta;
  like($page, qr/^Disallow: $url/m, "Robots are disallowed from $url");
}

my $titan = "titan://$host:$port";

# save haiku in the alex space

my $haiku = <<EOT;
Mad growl from the bowl
Back hurts, arms hurt, must go pee
Just one more to finish
EOT

$page = query_gemini("$titan/alex/raw/Haiku;size=83;mime=text/plain;token=hello", $haiku);
like($page, qr/^30 $base\/alex\/page\/Haiku\r$/, "Titan haiku");
ok(-d "$dir/127.0.0.1/alex", "alex subdirectory created");

$page = query_gemini("$base/alex/page/Haiku");
like($page, qr/Mad growl from the bowl/, "alex space has haiku");
like($page, qr/^=> $base\/alex\/raw\/Haiku Raw text/m, "Links work inside alex space");

# save haiku in the main space

$haiku = <<EOT;
Children shout and run.
Then silence. A distant plane.
And soft summer rain.
EOT

$page = query_gemini("titan://localhost:$port/raw/Haiku;size=77;mime=text/plain;token=hello", $haiku);
like($page, qr/^30 gemini:\/\/localhost:$port\/page\/Haiku\r$/, "Haiku saved for localhost");

$page = query_gemini("gemini://localhost:$port/page/Haiku");
like($page, qr/Children shout and run/, "Haiku for localhost namespace found");
like($page, qr/^=> gemini:\/\/localhost:$port\/raw\/Haiku Raw text/m, "Links work inside localhost space");

$page = query_gemini("$base/page/Haiku");
like($page, qr/This page does not yet exist/, "Haiku for 127.0.0.1 in the main space still does not exist");

ok(!-d "$dir/127.0.0.1/127.0.0.1", "no duplication of host subdirectory");

$page = query_gemini("gemini://localhost:$port/do/changes");
like($page, qr/^=> gemini:\/\/localhost:$port\/page\/Haiku Haiku \(current\)$/m,
     "localhost haiku listed");

# save haiku in the berta space

$haiku = <<EOT;
Spoons scrape over plates
The sink is full of dishes
I love tomato soup
EOT

$page = query_gemini("titan://localhost:$port/berta/raw/Haiku;size=72;mime=text/plain;token=hello", $haiku);
like($page, qr/^30 gemini:\/\/localhost:$port\/berta\/page\/Haiku\r$/, "Haiku saved for localhost/berta");

$page = query_gemini("$base/page/Haiku");
unlike($page, qr/Spoons scrape over plates/, "Haiku for 127.0.0.1 not found");

$page = query_gemini("gemini://localhost:$port/berta/page/Haiku");
like($page, qr/Spoons scrape over plates/, "Haiku for localhost/berta namespace found");
like($page, qr/^=> gemini:\/\/localhost:$port\/berta\/raw\/Haiku Raw text/m, "Links work inside localhost/berta space");

$page = query_gemini("gemini://$base/berta/page/Haiku");
unlike($page, qr/Spoons scrape over plates/, "Haiku for 127.0.0.1/berta namespace not found");

# save second haiku revision in the berta space

$haiku = <<EOT;
Metal in my ears
Dishes and plates in the sink
Where is the music?
EOT

$page = query_gemini("titan://localhost:$port/berta/raw/Haiku;size=67;mime=text/plain;token=hello", $haiku);
like($page, qr/^30 gemini:\/\/localhost:$port\/berta\/page\/Haiku\r$/, "Haiku saved for localhost, again/berta");

# List of all spaces

$page = query_gemini("$base/do/spaces");
like($page, qr/^=> gemini:\/\/localhost:$port\/berta\/ localhost\/berta$/m, "berta space listed");
like($page, qr/^=> gemini:\/\/localhost:$port\/ localhost$/m, "localhost space listed");
like($page, qr/^=> $base\/alex\/ 127\.0\.0\.1\/alex$/m, "alex space listed");
like($page, qr/^=> $base\/ 127\.0\.0\.1$/m, "127.0.0.1 space listed");

# All changes ("unified changes")

$page = query_gemini("$base/do/all/changes");
like($page, qr/^=> gemini:\/\/localhost:$port\/berta\/page\/Haiku \[localhost\/berta\] Haiku \(current\)$/m,
     "berta haiku listed");
like($page, qr/^=> gemini:\/\/localhost:$port\/berta\/page\/Haiku\/1 \[localhost\/berta\] Haiku \(1\)$/m,
     "berta haiku first revision listed");
like($page, qr/^=> $base\/alex\/page\/Haiku \[127\.0\.0\.1\/alex\] Haiku \(current\)$/m,
     "alex haiku listed");
like($page, qr/^=> gemini:\/\/localhost:$port\/page\/Haiku \[localhost\] Haiku \(current\)$/m,
     "localhost haiku listed");

# Latest all changes

$page = query_gemini("$base/do/all/latest/changes");
like($page, qr/^=> gemini:\/\/localhost:$port\/berta\/page\/Haiku \[localhost\/berta\] Haiku$/m,
     "berta haiku listed");
unlike($page, qr/^=> gemini:\/\/localhost:$port\/berta\/page\/Haiku\/1 \[localhost\/berta\] Haiku \(1\)$/m,
     "berta haiku first revision not listed");
like($page, qr/^=> $base\/alex\/page\/Haiku \[127\.0\.0\.1\/alex\] Haiku$/m,
     "alex haiku listed");
like($page, qr/^=> gemini:\/\/localhost:$port\/page\/Haiku \[localhost\] Haiku$/m,
     "localhost haiku listed");

# Handling files with the same name in unified changes

my $data = read_binary("t/alex.jpg");
my $size = length($data);
$page = query_gemini("titan://127.0.0.1:$port/raw/Alex;size=$size;mime=image/jpeg;token=hello", $data);
like($page, qr/^30 $base\/file\/Alex\r/, "Upload image to one host");
$page = query_gemini("titan://localhost:$port/raw/Alex;size=$size;mime=image/jpeg;token=hello", $data);
like($page, qr/^30 gemini:\/\/localhost:$port\/file\/Alex\r/, "Upload image to the other host");

$page = query_gemini("$base/do/all/changes");
like($page, qr/^=> $base\/file\/Alex \[127\.0\.0\.1\] Alex \(file\)$/m,
     "first image listed in Atom feed");
like($page, qr/^=> gemini:\/\/localhost:$port\/file\/Alex \[localhost\] Alex \(file\)$/m,
     "second image listed in Atom feed");

$page = query_gemini("titan://127.0.0.1:$port/raw/Alex;size=0;mime=image/jpeg;token=hello", "");

$page = query_gemini("$base/do/all/changes");
like($page, qr/^\[127\.0\.0\.1\] Alex \(deleted file\)$/m,
     "first image listed as deleted in Atom feed");
like($page, qr/^\[127\.0\.0\.1\] Alex \(file\)$/m,
     "first image listed as created in Atom feed (unlinked)");
like($page, qr/^=> gemini:\/\/localhost:$port\/file\/Alex \[localhost\] Alex \(file\)$/m,
     "second image listed in Atom feed");

done_testing();
