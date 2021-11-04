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

our @use = qw(WebStaticFiles);
our @config = (<<'EOT');
package App::Phoebe::StaticFiles;
use App::Phoebe qw($server);
use utf8;
our %routes = ('zürich' => $server->{wiki_dir} . '/static');
1;
EOT

require './t/test.pl';

# variables set by test.pl
our $host;
our $port;
our $dir;

mkdir "$dir/static";
write_text("$dir/static/a.txt", "A\n");
write_text("$dir/static/.secret", "B\n");

like(query_web("GET / HTTP/1.0\r\nhost: $host:$port"),
     qr/Phoebe/m, "Web site is being served");

my $page = query_web("GET /do/static HTTP/1.0\r\nhost: $host:$port");
like($page, qr/^HTTP\/1.1 200 OK/, "Static extension installed");
like($page, qr/<a href="\/do\/static\/z%C3%BCrich">zürich<\/a>/, "Static routes");

like(query_web("GET /do/static/z%C3%BCrich HTTP/1.0\r\nhost: $host:$port"),
     qr/<a href="\/do\/static\/z%C3%BCrich\/a\.txt">a\.txt<\/a>/, "Static files");

like(query_web("GET /do/static/z%C3%BCrich/a.txt HTTP/1.0\r\nhost: $host:$port"),
     qr/^A/m, "Static file");

like(query_web("GET /do/static/z%C3%BCrich/.secret HTTP/1.0\r\nhost: $host:$port"),
     qr/^HTTP\/1.1 400 Bad Request/, "No secret file");

like(query_web("GET /do/static/z%C3%BCrich/../config HTTP/1.0\r\nhost: $host:$port"),
     qr/^HTTP\/1.1 400 Bad Request/, "No escaping");

like(query_web("GET /do/static/other HTTP/1.0\r\nhost: $host:$port"),
     qr/^HTTP\/1.1 400 Bad Request/, "Just routes");

like(query_web("GET /do/static/other/a.txt HTTP/1.0\r\nhost: $host:$port"),
     qr/^HTTP\/1.1 400 Bad Request/, "Just files for known routes");

done_testing;
