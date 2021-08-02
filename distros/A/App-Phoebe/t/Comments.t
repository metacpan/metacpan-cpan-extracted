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
use File::Slurper qw(write_text);
use utf8;

our @use = qw(Comments);

plan skip_all => 'Contributions are an author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};

require './t/test.pl';

# variables set by test.pl
our $base;
our $dir;

# test data
my $haiku = <<"EOT";
Construction machines
Growling and heaving outside
Sunshine after rain
EOT

# write a page which we will comment upon
mkdir("$dir/page");
write_text("$dir/page/Test.gmi", "```\n$haiku```\n");

my $page = query_gemini("$base/page/Test");
like($page, qr/^Construction machines/m, "Test page");
like($page, qr/^=> \/page\/Comments%20on%20Test Comments/m, "Link to comment page");

$page = query_gemini("$base/page/Comments%20on%20Test");
like($page, qr/^This page does not yet exist/m, "Comment page");
like($page, qr/^=> \/do\/comment\/Comments%20on%20Test Leave a short comment/m, "Link to comment action");

like(query_gemini("$base/do/comment/Comments%20on%20Test"),
     qr/^10 Access token/, "Token required");

like(query_gemini("$base/do/comment/Comments%20on%20Test?bork"),
     qr/^30 $base\/do\/comment\/Comments%20on%20Test\/bork/, "With token it redirects");

like(query_gemini("$base/do/comment/Comments%20on%20Test/bork"),
     qr/^10 Short comment/, "Ask for comment");

like(query_gemini("$base/do/comment/Comments%20on%20Test/bork?Lalala"),
     qr/^59 Your token is the wrong token/, "Wrong token is rejected");

like(query_gemini("$base/do/comment/Comments%20on%20Test/hello?Lalala"),
     qr/^30 $base\/page\/Comments%20on%20Test/, "Redirect after comment");

like(query_gemini("$base/page/Comments%20on%20Test"),
     qr/^🗨 Lalala/m, "First comment saved");

like(query_gemini("$base/do/comment/Comments%20on%20Test/hello?lol+lol"),
     qr/^30 $base\/page\/Comments%20on%20Test/, "Redirect after comment");

like(query_gemini("$base/page/Comments%20on%20Test"),
     qr/^🗨 lol lol/m, "Second Comment saved, plus handled");

done_testing;
