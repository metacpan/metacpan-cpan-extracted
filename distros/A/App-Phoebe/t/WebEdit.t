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
use URI::Escape;

our $base;
our @use = qw(WebEdit);

require './t/test.pl';

# variables set by test.pl
our $dir;
our $host;
our $port;

my $page = query_web("GET /page/Hello HTTP/1.0\r\n"
		     . "host: $host:$port");
like($page, qr/^HTTP\/1.1 200 OK/, "Page served via HTTP");
like($page, qr/This page does not yet exist/, "Empty page");

$page = query_web("GET /do/edit/Hello HTTP/1.0\r\n"
		  . "host: $host:$port");
like($page, qr/^HTTP\/1.1 200 OK/, "Edit page served via HTTP");

my $haiku = <<EOT;
The laptop streaming
videos of floods and rain
but I hear sparrows
EOT

my $content = "text=" . uri_escape_utf8("```\n$haiku```");
my $length = length($content);

$page = query_web("POST /do/edit/Hello HTTP/1.0\r\n"
		  . "host: $host:$port\r\n"
		  . "content-type: application/x-www-form-urlencoded\r\n"
		  . "content-length: $length\r\n"
		  . "\r\n"
		  . $content);
like($page, qr/^HTTP\/1.1 400 Bad Request/, "Token required");
like($page, qr/^Token required/m, "Token required error");

$content = "text=" . uri_escape_utf8("```\n$haiku```") . "&token=lalala";
$length = length($content);

$page = query_web("POST /do/edit/Hello HTTP/1.0\r\n"
		  . "host: $host:$port\r\n"
		  . "content-type: application/x-www-form-urlencoded\r\n"
		  . "content-length: $length\r\n"
		  . "\r\n"
		  . $content);

like($page, qr/^HTTP\/1.1 400 Bad Request/, "Wrong Token");
like($page, qr/^Wrong token/m, "Wrong token error");

$content = "text=" . uri_escape_utf8("```\n$haiku```") . "&token=hello";
$length = length($content);

$page = query_web("POST /do/edit/Hello HTTP/1.0\r\n"
		  . "host: $host:$port\r\n"
		  . "content-type: application/x-www-form-urlencoded\r\n"
		  . "content-length: $length\r\n"
		  . "\r\n"
		  . $content);

like($page, qr/^HTTP\/1.1 302 Found/, "Redirect after save");
like(query_web("GET /page/Hello HTTP/1.0\r\nhost: $host:$port"),
     qr/The laptop streaming/, "Page saved");

done_testing;
