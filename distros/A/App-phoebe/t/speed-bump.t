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

our @config = qw(speed-bump.pl);
our $base;
our $port;
require './t/test.pl';

my $page = query_gemini("gemini://127.0.0.1:$port/do/speed-bump/reset");
like($page, qr(^20), "Speed bump reset");

my $page = query_gemini("$base/");
like($page, qr(^20), "Request 1");

$page = query_gemini("$base/");
like($page, qr(^20), "Request 2");

$page = query_gemini("$base/");
like($page, qr(^44 60), "Request 3 is blocked for 60s");

done_testing();
