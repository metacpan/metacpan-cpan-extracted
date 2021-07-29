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
use File::Slurper qw(read_text write_text);

my $msg;
if (not $ENV{TEST_AUTHOR}) {
  $msg = 'Contributions are an author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
}
plan skip_all => $msg if $msg;
our $dir;
our $host;
our $base;
our $port;

# tricky: must know the directory before generating the random number in test.pl!
our @use = qw(MokuPona);
our @config = ("package App::Phoebe::MokuPona;\n"
	       . "use App::Phoebe qw(\$server);\n"
	       . "our \$dir = \"\$server->{wiki_dir}/moku-pona\";\n");
require './t/test.pl';
mkdir("$dir/moku-pona");
write_text("$dir/moku-pona/updates.txt", "A\n");

like(query_gemini("$base/do/moku-pona"), qr/^31/, "Redirected");
my $page = query_gemini("$base/do/moku-pona/updates.txt");
like($page, qr/^20/, "Updates");
like($page, qr/^A$/m, "File content");

done_testing();
