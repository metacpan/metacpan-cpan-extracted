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

my $msg;
if (not $ENV{TEST_AUTHOR}) {
  $msg = 'Contributions are author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
} else {
  for my $module (qw(IO::Socket::IP)) {
    if (not eval { require $module }) {
      $msg = "You need to install the $module module for this test.";
      last;
    }
  }
}
plan skip_all => $msg if $msg;

our $host;
our $base;
our $dir;
our $port;
our @config = qw(gopher.pl);
our @pages = qw(Alex Berta Chris);

my $gopher_port = Mojo::IOLoop::Server->generate_port; # new port for Gopher
my $gophers_port = Mojo::IOLoop::Server->generate_port; # new port for Gophers

# make sure starting phoebe starts serving the gopher port, too
push(@config, <<"EOF");
\$gopher_port = $gopher_port;
\$gophers_port = $gophers_port;
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

mkdir("$dir/page");
write_text("$dir/page/2021-02-05.gmi", "yo");

my $page = query_gopher("");
like($page, qr/^iWelcome to Phoebe/m, "Main menu");
like($page, qr/^iBlog:/m, "Main menu (Blog section)");
like($page, qr/^12021-02-05\tpage\/2021-02-05\tlocalhost\t$gopher_port$/m, "Main menu (Blog link)");
like($page, qr(^0Index of all pages\tdo/index\tlocalhost\t$gopher_port$)m, "Page index link");

$page = query_gopher("", 1);
like($page, qr/^iWelcome to Phoebe/m, "Main menu via TLS");
like($page, qr/^iBlog:/m, "Main menu (Blog section) via TLS");
like($page, qr/^12021-02-05\tpage\/2021-02-05\tlocalhost\t$gophers_port$/m, "Main menu (Blog link) via TLS");
like($page, qr(^0Index of all pages\tdo/index\tlocalhost\t$gophers_port$)m, "Page index link via TLS");

like(query_gopher("page/2021-02-05"), qr(^yo$), "Page");
like(query_gopher("page/2021-02-05", 1), qr(^yo$), "Page via TLS");

like(query_gopher("do/index"), qr/^12021-02-05\tpage\/2021-02-05\tlocalhost\t$gopher_port$/m, "Index");
like(query_gopher("do/index", 1), qr/^12021-02-05\tpage\/2021-02-05\tlocalhost\t$gophers_port$/m, "Index via TLS");

done_testing();
