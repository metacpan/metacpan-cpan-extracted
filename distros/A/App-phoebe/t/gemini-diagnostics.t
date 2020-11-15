# Copyright (C) 2020  Alex Schroeder <alex@gnu.org>
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
use Encode qw(decode_utf8);
use utf8; # tests contain UTF-8 characters and it matters

our $host = 'localhost';
our $port;

require './t/test.pl';

 SKIP: {
   say "Running gemini-diagnostics $host $port";
   open(my $fh, "-|:utf8", "gemini-diagnostics $host $port")
       or skip "Cannot run gemini-diagnostics";
   diag "A lot of errors at the beginning are OK!";

   my $test;
   while (<$fh>) {
     $test = $1 if /\[(\w+)\]/;
     next unless m/^ *(x|✓)/;
     ok($1 eq "✓", $test);
   }
}

done_testing();
