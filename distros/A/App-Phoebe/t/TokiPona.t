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
use File::Slurper qw(write_binary);

our $base;
our @use = qw(TokiPona);

plan skip_all => 'This is an author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};

require './t/test.pl';

# variables set by test.pl
our $dir;
our $host;
our $port;

# write fake font file
write_text("$dir/linja-pona-4.2.woff", "TEST");

like(query_web("GET / HTTP/1.0\r\nhost: $host:$port"),
     qr/^HTTP\/1.1 200 OK/, "Web is served");

like(query_web("GET /linja-pona-4.2.woff HTTP/1.0\r\nhost: $host:$port"),
     qr/^TEST/m, "Font is served");

like(query_web("GET /default.css HTTP/1.0\r\nhost: $host:$port"),
     qr/^pre.toki/m, "CSS is modified");

done_testing;
