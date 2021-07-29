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
use Mojo::IOLoop::Server;
use utf8; # tests contain UTF-8 characters and it matters

plan skip_all => 'Contributions are an author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};

our $host;
our @hosts = qw(localhost 127.0.0.1); # localhost must come first
our @spaces = qw(localhost/alex);
our $port;
our $dir;
our $base;
our @use = qw(Spartan);

my $spartan_port = Mojo::IOLoop::Server->generate_port; # new port for Spartan

# make sure starting phoebe starts serving the spartan port, too
our @config = (<<"EOF");
package App::Phoebe::Spartan;
our \$spartan_port = $spartan_port;
EOF

require './t/test.pl';

sub query_spartan {
  my $query = shift;
  my $host = shift || $hosts[0];
  my $buffer = shift || "";
  my $length = length($buffer);
  # create client
  my $socket;
  $socket = IO::Socket::IP->new("$host:$spartan_port")
      or die "Cannot construct client socket: $@";
  $socket->print("$host $query $length\r\n$buffer");
  undef $/; # slurp
  return <$socket>;
}

mkdir("$dir/localhost");
mkdir("$dir/localhost/page");
write_text("$dir/localhost/page/2021-02-05.gmi", "yo");
mkdir("$dir/localhost/alex");
mkdir("$dir/localhost/alex/page");
write_text("$dir/localhost/alex/page/2021-02-05.gmi", "lo");

# verify we get single digit errors
like(query_spartan(""), qr/^4 /, "No empty path");

my $page = query_spartan("/");
like($page, qr/^# Welcome to Phoebe/m, "Main menu");
like($page, qr/^Blog:/m, "Main menu (Blog section)");

like($page, qr(^=> spartan://localhost:$spartan_port/page/2021-02-05 2021-02-05$)m, "Main menu (Blog link)");
like($page, qr(^=> spartan://localhost:$spartan_port/do/index Index of all pages$)m, "Page index link");

$page = query_spartan("/page/2021-02-05");
like($page, qr(^# 2021-02-05$)m, "Page Title");
like($page, qr(^yo$)m, "Page Text");

# handling of ```
my $haiku = <<'EOT';
Through open windows
Hear the garbage truck's engine
Rattle in the heat
EOT
query_spartan("/page/2021-06-28", "localhost", "```\n$haiku```\n");
$page = query_spartan("/page/2021-06-28");
like($page, qr(^2 text/gemini; charset=UTF-8\r\n# 2021-06-28\n```\n$haiku```\n), "No empty lines");

$haiku = <<'EOT';
Outside the muted
Endless city noise of cars
And a shy sparrow
EOT
query_spartan("/page/2021-06-28", "localhost", "```\n$haiku```\n");
$page = query_spartan("/page/2021-06-28");
like($page, qr(^2 text/gemini; charset=UTF-8\r\n# 2021-06-28\n```\n$haiku```\n), "Change!");

# history
$page = query_spartan("/history/2021-06-28");
like($page, qr(^# Page history for 2021-06-28$)m, "History title");
like($page, qr(^=> spartan://localhost:$spartan_port/page/2021-06-28 2021-06-28 \(current\)$)m, "Current revision link");
like($page, qr(^=> spartan://localhost:$spartan_port/page/2021-06-28/1 2021-06-28 \(1\)$)m, "First revision link");
like($page, qr(^=> spartan://localhost:$spartan_port/diff/2021-06-28/1 Differences$)m, "Diff link");

$page = query_spartan("/page/2021-06-28/1");
like($page, qr(^Through open windows)m, "First revision text");

$page = query_spartan("/diff/2021-06-28/1");
like($page, qr(^Showing the differences between revision 1 and the current revision.)m, "Diff");
like(decode_utf8($page), qr(^Changed lines 2–4)m, "Diff lines");

# spaces
$page = query_spartan("/alex/page/2021-02-05");
like($page, qr(^lo$)m, "Different Page Text in a Space (gemini)");
$page = query_spartan("/alex/raw/2021-02-05");
like($page, qr(^lo$)m, "Different Page Text in a Space (raw)");
$page = query_spartan("/alex/html/2021-02-05");
like($page, qr(^<p>lo$)m, "Different Page Text in a Space (html)");

# page list
like(query_spartan("/do/index"),
     qr(^=> spartan://localhost:$spartan_port/page/2021-02-05 2021-02-05$)m, "Index");

# verify that gemini still works
$page = query_gemini("$base/");
like($page, qr/Welcome to Phoebe/, "Main menu via Gemini");
like($page, qr/^Blog:/m, "Main menu (Blog section) via Gemini");
like($page, qr/^=> $base\/page\/2021-02-05 2021-02-05/m, "Main menu contains 2021-02-05 via Gemini");

done_testing();
