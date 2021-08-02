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

our $example = 1;

require './t/test.pl';

# variables set by test.pl
our $host;
our $port;

my $page = query_web("GET /page/Test HTTP/1.1\r\nhost: $host:$port");
like($page, qr/<p>This page does not yet exist/, "Regular request");
like($page, qr/<a href="\/do\/edit\/Test">Edit<\/a>/, "Edit link");

$page = query_web("GET /do/edit/Test HTTP/1.1\r\nhost: $host:$port", 0); # no certs
like($page, qr/^HTTP\/1.1 403 Not authorized/, "403 without a certificate");
like($page, qr/You need a client certificate to edit this wiki/, "Explanation");

$page = query_web("GET /do/edit/Test HTTP/1.1\r\nhost: $host:$port");
like($page, qr/<h1>Test<\/h1>/, "Edit page with cert");
like($page, qr/This page does not yet exist/, "Textarea");
unlike($page, qr/Token/, "No token");

my $haiku = <<EOT;
Fireworks outside
our national holiday
sounds like a war zone
EOT

my $content = "text=" . uri_escape_utf8("```\n$haiku```");
my $length = length($content);

$page = query_web("POST /do/edit/Test HTTP/1.0\r\n"
		  . "host: $host:$port\r\n"
		  . "content-type: application/x-www-form-urlencoded\r\n"
		  . "content-length: $length\r\n"
		  . "\r\n"
		  . $content);

like($page, qr/^HTTP\/1.1 302 Found/, "Redirect after save");
like(query_web("GET /page/Test HTTP/1.0\r\nhost: $host:$port"),
     qr/Fireworks outside/, "Page saved");

done_testing;
