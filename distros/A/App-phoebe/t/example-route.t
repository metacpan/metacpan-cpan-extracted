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

our $example = 1;

our @config = (<<'EOT');
use App::Phoebe qw(@extensions @main_menu port);
use Modern::Perl;
push(@main_menu, "=> gemini://localhost:1965/do/test Test");
push(@extensions, \&serve_test);
sub serve_test {
  my $stream = shift;
  my $url = shift;
  my $hosts = host_regex();
  my $port = port($stream);
  if ($url =~ m!^gemini://($hosts):$port/do/test$!) {
    $stream->write("20 text/plain\r\n");
    $stream->write("Test\n");
    return 1;
  }
  return;
}
EOT

require './t/test.pl';

# variables set by test.pl
our $base;

like(query_gemini("$base/"),
     qr/^=> gemini:\/\/localhost:1965\/do\/test Test\n/m, "Extension installed Test menu");

like(query_gemini("$base/do/test"),
     qr/^Test\n/m, "Extension runs");

done_testing;
