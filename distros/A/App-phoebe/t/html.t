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
use utf8; # tests contain UTF-8 characters and it matters

our $host;
our $port;
our $base;
our $dir;

require './t/test.pl';

# set up the main space with some test data

mkdir("$dir/page");
write_text("$dir/page/Alex.gmi", "Alex Schroeder\n=> /page/Berta Berta");
write_text("$dir/page/Berta.gmi", "```\nHello!\nYo!\n```\n");
write_text("$dir/page/Chris.gmi", "=> Alex\n");
mkdir("$dir/file");
write_binary("$dir/file/alex.jpg", read_binary("t/alex.jpg"));
mkdir("$dir/meta");
write_text("$dir/meta/alex.jpg", "content-type: image/jpeg");

# html

my $page = query_gemini("GET /robots.txt HTTP/1.0\r\nhost: $host:$port\r\n");
for (qw(raw/* html/* diff/* history/* do/changes* do/all/changes* do/rss do/atom do/new do/more do/match do/search)) {
  my $url = quotemeta;
  like($page, qr/^Disallow: $url/m, "Robots are disallowed from $url");
}

$page = query_gemini("GET / HTTP/1.0\r\nhost: $host:$port\r\n");
like($page, qr!<a href="https://$host:$port/page/Alex">Alex</a>!, "main menu contains Alex");

$page = query_gemini("GET /page/Alex HTTP/1.0\r\nhost: $host:$port\r\n");
like($page, qr!<p>Alex Schroeder!, "Alex content");
like($page, qr!<a href="/page/Berta">Berta</a>!, "Alex contains Berta link");

$page = query_gemini("GET /page/Berta HTTP/1.0\r\nhost: $host:$port\r\n");
like($page, qr!<pre class="default">\nHello\!\nYo\!\n</pre>!, "Berta contains pre block");

$page = query_gemini("GET /page/Chris HTTP/1.0\r\nhost: $host:$port\r\n");
like($page, qr!<a href="Alex">Alex</a>!, "Chris contains Alex link");

write_text("$dir/page/Berta.gmi", "```type=poetry\nHello!\nYo!\n```\n");
$page = query_gemini("GET /page/Berta HTTP/1.0\r\nhost: $host:$port\r\n");
like($page, qr!<pre class="poetry">\nHello\!\nYo\!\n</pre>!, "Class got passed");

done_testing();
