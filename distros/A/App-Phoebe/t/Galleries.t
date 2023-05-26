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

use open ':std', ':encoding(utf8)';

use Modern::Perl;
use Mojo::Util qw(url_escape);
use Encode qw(encode_utf8 decode_utf8);
use Test::More;
use File::Slurper qw(read_text write_text);
use utf8;

our @use = qw(Galleries);
our @config = (<<'EOF');
package App::Phoebe::Galleries;
use App::Phoebe qw($server);
our $galleries_dir = "$server->{wiki_dir}/galleries";
our $galleries_host = "localhost";
EOF

plan skip_all => 'This is an author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};

require './t/test.pl';

# variables set by test.pl
our $base;
our $dir;

# setup
mkdir("$dir/galleries");
mkdir("$dir/galleries/one");
write_text("$dir/galleries/one/data.json", <<EOT);
{"data":[{"blur":"blurs\/P3111203.jpg","caption":["Grapsus grapsus atop a marine iguana",""],"date":"2020-03-11 16:54","img":["imgs\/P3111203.jpg",[1600,1200]],"original":"P3111203.JPG","sha256":"0192dd7efd4b19e404cadbd3e797355836ee142cdb2eece87b5a239f15ccb6e8","stamp":1583945697,"thumb":["thumbs\/P3111203.jpg",[150,113]]},{"blur":"blurs\/hëad space.jpg","img":["imgs\/hëad space.jpg",[400,400]],"original":"hëad space.png","sha256":"5fd6d3ffb55ceb8c8574c1a935139812e8807b606d693c85db6668963710501e","stamp":1583945698,"thumb":["thumbs\/hëad space.jpg",[150,150]]}]}
EOT
mkdir("$dir/galleries/one/thumbs");
write_text("$dir/galleries/one/thumbs/P3111203.jpg", "TEST");
write_text("$dir/galleries/one/thumbs/hëad space.jpg", "TËST");

my $page = query_gemini("$base/do/gallery");
like($page, qr/^20/, "Galleries main page");
like($page, qr/^# Galleries/m, "Main title");
like($page, qr/^=> $base\/do\/gallery\/one One/m, "Link to album");

$page = query_gemini("$base/do/gallery/one");
like($page, qr/^20/, "Gallery page");
like($page, qr/^# One/m, "Gallery title");
like($page, qr/^Grapsus grapsus atop a marine iguana/m, "First image title");
like($page, qr/^=> $base\/do\/gallery\/one\/thumbs\/P3111203.jpg Thumbnail/m, "First thumbnail");
like($page, qr/^=> $base\/do\/gallery\/one\/imgs\/P3111203.jpg Image/m, "First image");

my $encoded_file = url_escape encode_utf8 "hëad space.jpg";

# the second image has no title
like($page, qr/^=> $base\/do\/gallery\/one\/imgs\/$encoded_file Image/m, "Second image");
like($page, qr/^=> $base\/do\/gallery\/one\/thumbs\/$encoded_file Thumbnail/m, "Second thumbnail");

$page = query_gemini("$base/do/gallery/one/thumbs/P3111203.jpg");
like($page, qr/^20 image\/jpeg/, "First image response served");
like($page, qr/^TEST/m, "First image data served");

$page = decode_utf8 query_gemini("$base/do/gallery/one/thumbs/$encoded_file");
like($page, qr/^20 image\/jpeg/, "Second image response served");
like($page, qr/^TËST/m, "Second image data served");

done_testing;
