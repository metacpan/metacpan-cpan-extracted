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

our @use = qw(StaticFiles);
our @config = (<<'EOT');
package App::Phoebe::StaticFiles;
use App::Phoebe qw($server);
use utf8;
our %routes = ('zürich' => $server->{wiki_dir} . '/static');
1;
EOT

require './t/test.pl';

# variables set by test.pl
our $base;
our $dir;

mkdir "$dir/static";
write_text("$dir/static/a.txt", "A\n");
write_text("$dir/static/.secret", "B\n");

my $page = query_gemini("$base/do/static");
like($page, qr/^20/, "Static extension installed");
like($page, qr/^=> \/do\/static\/z%C3%BCrich zürich/m, "Static routes");

like(query_gemini("$base/do/static/z%C3%BCrich"),
     qr/^=> \/do\/static\/z%C3%BCrich\/a\.txt a\.txt/m, "Static files");

like(query_gemini("$base/do/static/z%C3%BCrich/a.txt"),
     qr/^A/m, "Static file");

like(query_gemini("$base/do/static/z%C3%BCrich/.secret"),
     qr/^51/m, "No secret file");

like(query_gemini("$base/do/static/z%C3%BCrich/../config"),
     qr/^51/m, "No escaping");

like(query_gemini("$base/do/static/other"),
     qr/^40/m, "Just routes");

like(query_gemini("$base/do/static/other/a.txt"),
     qr/^40/m, "Just files for known routes");

done_testing;
