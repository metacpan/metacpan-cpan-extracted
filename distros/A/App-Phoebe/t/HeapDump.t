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
use utf8;

plan skip_all => 'This is an author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};

our @use = qw(HeapDump);

our @config = (<<'EOT');
package App::Phoebe;
our @known_fingerprints = qw(
    sha256$0ba6ba61da1385890f611439590f2f0758760708d1375859b2184dcd8f855a00);
EOT

require './t/test.pl';

# variables set by test.pl
our $base;
our $dir;

# no client cert
my $page = query_gemini("$base/do/heap-dump", undef, 0);
like($page, qr/^60/, "Client certificate required");
$page = query_gemini("$base/do/heap-dump");
like($page, qr/^20/, "Heap dump saved");
ok(-f "$dir/phoebe.pmat", "File exists");

done_testing;
