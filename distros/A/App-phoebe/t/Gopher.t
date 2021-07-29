# Copyright (C) 2017–2021  Alex Schroeder <alex@gnu.org>
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
use File::Slurper qw(write_text read_binary);
use IO::Socket::IP;
use IO::Socket::SSL;
use Mojo::IOLoop::Server;
use utf8; # tests contain UTF-8 characters and it matters

plan skip_all => 'Contributions are an author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};

our $host;
our @hosts = qw(localhost 127.0.0.1); # localhost must come first
our @spaces = qw(localhost/alex);
our $dir;
our $base;
our @use = qw(Gopher);

my $gopher_port = Mojo::IOLoop::Server->generate_port; # new port for Gopher
my $gophers_port = Mojo::IOLoop::Server->generate_port; # new port for Gophers

# make sure starting phoebe starts serving the gopher port, too
our @config = (<<"EOF");
package App::Phoebe::Gopher;
our \$gopher_port = $gopher_port;
our \$gophers_port = $gophers_port;
our \$gopher_host = "localhost";
EOF

require './t/test.pl';

sub query_gopher {
  my $query = shift;
  my $tls = shift;
  # create client
  my $socket;
  if ($tls) {
    $socket = IO::Socket::SSL->new(
      PeerHost => $host, PeerPort => $gophers_port,
      SSL_verify_mode => SSL_VERIFY_NONE)
	or die "Cannot construct client socket: $@";
  } else {
    $socket = IO::Socket::IP->new("$host:$gopher_port")
	or die "Cannot construct client socket: $@";
  }
  $socket->print("$query\r\n");
  undef $/; # slurp
  return <$socket>;
}

mkdir("$dir/localhost");
mkdir("$dir/localhost/page");
write_text("$dir/localhost/page/2021-02-05.gmi", "yo");
mkdir("$dir/localhost/alex");
mkdir("$dir/localhost/alex/page");
write_text("$dir/localhost/alex/page/2021-02-05.gmi", "lo");

my $page = query_gopher("");
like($page, qr/^iWelcome to Phoebe/m, "Main menu");
like($page, qr/^iPhlog:/m, "Main menu (Blog section)");
like($page, qr/^02021-02-05\tpage\/2021-02-05\tlocalhost\t$gopher_port$/m, "Main menu (Blog link)");
like($page, qr(^1Index of all pages\tdo/index\tlocalhost\t$gopher_port$)m, "Page index link");
unlike($page, qr(=>), "No Gemini link on the main menu");

$page = query_gopher("", 1);
like($page, qr/^iWelcome to Phoebe/m, "Main menu via TLS");
like($page, qr/^iPhlog:/m, "Main menu (Blog section) via TLS");
like($page, qr/^02021-02-05\tpage\/2021-02-05\tlocalhost\t$gophers_port$/m, "Main menu (Blog link) via TLS");
like($page, qr(^1Index of all pages\tdo/index\tlocalhost\t$gophers_port$)m, "Page index link via TLS");

$page = query_gopher("page/2021-02-05");
like($page, qr(^2021-02-05$)m, "Page Title");
like($page, qr(^==========$)m, "Page Title Unterline");
like($page, qr(^yo$)m, "Page Text");
like(query_gopher("page/2021-02-05", 1), qr(^yo$)m, "Page via TLS");

# finger compatibility: no page/ prefix!
$page = query_gopher("2021-02-05");
like($page, qr(^2021-02-05$)m, "Page Title");

# handling of ```
my $haiku = <<'EOT';
Through open windows
Hear the garbage truck's engine
Rattle in the heat
EOT
write_text("$dir/localhost/page/2021-06-28.gmi", "```\n$haiku```\n");
$page = query_gopher("2021-06-28");
# in the following regex the * makes the final \n in $haiku optional
like($page, qr(^2021-06-28\n==========\n$haiku*$), "No empty lines");

# spaces
$page = query_gopher("alex/page/2021-02-05");
like($page, qr(^lo$)m, "Different Page Text in a Space");
like(query_gopher("alex/page/2021-02-05", 1), qr(^lo$)m, "Different Page Text in a Space via TLS");

# page list
like(query_gopher("do/index"), qr/^02021-02-05\tpage\/2021-02-05\tlocalhost\t$gopher_port$/m, "Index");
like(query_gopher("do/index", 1), qr/^02021-02-05\tpage\/2021-02-05\tlocalhost\t$gophers_port$/m, "Index via TLS");

# match
like(query_gopher("do/match\t05"), qr/^02021-02-05\tpage\/2021-02-05\tlocalhost\t$gopher_port$/m, "Match");
like(query_gopher("do/match\t05", 1), qr/^02021-02-05\tpage\/2021-02-05\tlocalhost\t$gophers_port$/m, "Match via TLS");

# search
like(query_gopher("do/search\tyo"), qr/^02021-02-05\tpage\/2021-02-05\tlocalhost\t$gopher_port$/m, "Search");
like(query_gopher("do/search\tyo", 1), qr/^02021-02-05\tpage\/2021-02-05\tlocalhost\t$gophers_port$/m, "Search via TLS");

# verify that gemini still works
$page = query_gemini("$base/");
like($page, qr/Welcome to Phoebe/, "Main menu via Gemini");
like($page, qr/^Blog:/m, "Main menu (Blog section) via Gemini");
like($page, qr/^=> $base\/page\/2021-02-05 2021-02-05/m, "Main menu contains 2021-02-05 via Gemini");

done_testing();
