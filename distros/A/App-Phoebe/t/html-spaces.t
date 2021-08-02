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
our @use = qw(Web);
our $host;
our @hosts = qw(127.0.0.1 localhost);
our @spaces = qw(127.0.0.1/alex localhost/berta);
our @pages = qw(Alex);
our $port;
our $base;
our $dir;

require './t/test.pl';

my $page = query_gemini("GET /alex HTTP/1.0\r\nhost: $host:$port\r\n");
like($page, qr!<a href="https://$host:$port/alex/page/Alex">Alex</a>!, "main menu of alex space contains Alex");

done_testing();
