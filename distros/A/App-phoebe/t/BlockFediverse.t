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

our @use = qw(BlockFediverse);

plan skip_all => 'Contributions are an author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};

require './t/test.pl';

# variables set by test.pl
our $host;
our $port;

like(query_web("GET / HTTP/1.0\r\nhost: $host:$port"),
     qr/^HTTP\/1.1 200 OK/, "Web is served");

like(query_web("GET / HTTP/1.0\r\nhost: $host:$port\r\nuser-agent: Mastodon"),
     qr/^HTTP\/1.1 400 Bad Request/, "Mastodon is blocked");

done_testing;
