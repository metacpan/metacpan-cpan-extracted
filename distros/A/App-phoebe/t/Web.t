# Copyright (C) 2017–2021  Alex Schroeder <alex@gnu.org>
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
use utf8; # tests contain UTF-8 characters and it matters

our $host;
our $port;
our $base;
our $dir;
our @use = qw(Web);

require './t/test.pl';

# set up the main space with some test data

mkdir("$dir/page");
write_text("$dir/page/Alex.gmi", "Alex Schroeder\n=> /page/Berta Berta");
write_text("$dir/page/Berta.gmi", "```\nHello!\nYo!\n```\n");
write_text("$dir/page/Chris.gmi", "=> Alex\n");
my $ts = time;
my $changes = join("\x1f", $ts - 300, "Alex", 1, "1111\n")
    . join("\x1f", $ts - 200, "Berta", 1, "1111\n")
    . join("\x1f", $ts - 100, "Alex", 1, "1111\n");
write_text("$dir/changes.log", $changes);
mkdir("$dir/file");
write_binary("$dir/file/alex.jpg", read_binary("t/alex.jpg"));
mkdir("$dir/meta");
write_text("$dir/meta/alex.jpg", "content-type: image/jpeg");

# html

my $page = query_web("GET /robots.txt HTTP/1.0\r\nhost: $host:$port");
for (qw(/raw /html /diff /history /do/changes /do/all/changes /do/rss /do/atom /do/new /do/more /do/match /do/search)) {
  my $url = quotemeta;
  like($page, qr/^Disallow: $url/m, "Robots are disallowed from $url");
}

$page = query_web("GET / HTTP/1.0\r\nhost: $host:$port");
like($page, qr!<a href="https://$host:$port/page/Alex">Alex</a>!, "main menu contains Alex");

$page = query_web("GET /page/Alex HTTP/1.0\r\nhost: $host:$port");
like($page, qr!<p>Alex Schroeder!, "Alex content");
like($page, qr!<a href="/page/Berta">Berta</a>!, "Alex contains Berta link");

$page = query_web("GET /page/Berta HTTP/1.0\r\nhost: $host:$port");
like($page, qr!<pre class="default">\nHello\!\nYo\!\n</pre>!, "Berta contains pre block");

$page = query_web("GET /page/Chris HTTP/1.0\r\nhost: $host:$port");
like($page, qr!<a href="Alex">Alex</a>!, "Chris contains Alex link");

write_text("$dir/page/Berta.gmi", "```type=poetry\nHello!\nYo!\n```\n");
$page = query_web("GET /page/Berta HTTP/1.0\r\nhost: $host:$port");
like($page, qr!<pre class="poetry">\nHello\!\nYo\!\n</pre>!, "Class got passed");

$page = query_web("GET /history/Alex HTTP/1.0\r\nhost: $host:$port");
like($page, qr!History!, "History rendered");
like($page, qr!<a href="https://$host:$port/page/Alex">Alex \(current\)</a>!, "Change entry");

$page = query_web("GET /diff/Alex/1 HTTP/1.0\r\nhost: $host:$port");
like($page, qr!Differences for Alex!, "Diff rendered");

$page = query_web("GET /do/changes HTTP/1.0\r\nhost: $host:$port");
like($page, qr!Changes!, "Changes rendered");
like($page, qr!<a href="https://$host:$port/page/Alex">Alex \(current\)</a>!, "Change entry");

$page = query_web("GET /do/all/changes HTTP/1.0\r\nhost: $host:$port");
like($page, qr!<a href="https://$host:$port/do/all/latest/changes/100">Latest changes</a>!, "Link to latest changes");
like($page, qr!<a href="https://$host:$port/page/Alex">Alex \(current\)</a>!, "Change entry");

$page = query_web("GET /do/all/latest/changes HTTP/1.0\r\nhost: $host:$port");
like($page, qr!<a href="https://$host:$port/do/all/changes/100">All changes</a>!, "Link to all changes");
like($page, qr!<a href="https://$host:$port/page/Alex">Alex</a>!, "Change entry");

$page = query_web("GET /do/index HTTP/1.0\r\nhost: $host:$port");
like($page, qr!All Pages!, "All Pages");
like($page, qr!<a href="https://$host:$port/page/Alex">Alex</a>!, "Page entry");

$page = query_web("GET /do/spaces HTTP/1.0\r\nhost: $host:$port");
like($page, qr!All Spaces!, "All Spaces");

$page = query_web("GET /do/files HTTP/1.0\r\nhost: $host:$port");
like($page, qr!All Files!, "All files");

$page = query_web("GET /do/rss HTTP/1.0\r\nhost: $host:$port");
like($page, qr!<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">!, "RSS");
like($page, qr!<title>Alex</title>!, "RSS item title");

$page = query_web("GET /do/atom HTTP/1.0\r\nhost: $host:$port");
like($page, qr!<feed xmlns="http://www.w3.org/2005/Atom">!, "Atom");
like($page, qr!<title>Alex</title>!, "RSS item title");

$page = query_web("GET /do/all/atom HTTP/1.0\r\nhost: $host:$port");
like($page, qr!<feed xmlns="http://www.w3.org/2005/Atom">!, "Atom");

done_testing();
