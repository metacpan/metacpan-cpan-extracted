#!/usr/bin/env perl
# Copyright (C) 2018–2020  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

use Modern::Perl;
use Mojo::IOLoop;
use IO::Socket::SSL;
use Test::More;
use Config;

my $port = Mojo::IOLoop::Server->generate_port;

my $pid = fork();

END {
  # kill server
  if ($pid) {
    kill 'KILL', $pid or warn "Could not kill server $pid";
  }
}

our $data_dir = 't';

if (!defined $pid) {
  die "Cannot fork: $!";
} elsif ($pid == 0) {
  say "This is the server...";
  if (not -f "t/cert.pem" or not -f "t/key.pem") {
    my $version = qx(openssl version)
	or die "Cannot invoke openssl to create certificates\n";
    print $version;
    if ($version =~ /^OpenSSL 1\.0\./) {
      my $cmd = qq(openssl req -new -x509 -newkey rsa -subj /CN=localhost )
	  . qq( -days 1825 -nodes -out t/cert.pem -keyout t/key.pem);
      system($cmd) == 0 or die "openssl failed to create t/cert.pem and t/key.pem: $?";
    } else {
      my $cmd = qq(openssl req -new -x509 -newkey ec -subj /CN=localhost )
	  . qq(-pkeyopt ec_paramgen_curve:prime256v1 -days 1825 -nodes -out t/cert.pem -keyout t/key.pem);
      system($cmd) == 0 or die "openssl failed to create t/cert.pem and t/key.pem: $?";
    }
  }
  chdir($data_dir);
  my $perl_path = $Config{perlpath};
  exec($perl_path, "../blib/script/lupa-pona", "--port=$port", "--log_level=warn")
      or die "Cannot exec: $!";
}

sub query_gemini {
  my $query = shift;
  my $socket = IO::Socket::SSL->new(
    PeerHost => "127.0.0.1",
    PeerService => $port,
    SSL_verify_mode => SSL_VERIFY_NONE)
      or die "Cannot construct client socket: $@";
  print $socket "$query\r\n";
  undef $/; # slurp
  return <$socket>;
}

say "This is the client waiting for the server to start...";
sleep 1;

my $page = query_gemini('gemini://localhost/');
like($page, qr"^20 text/gemini; charset=UTF-8\r\n", "Gemini header");
like($page, qr/Welcome to Lupa Pona!/, "Title");
like($page, qr/=> basic.t/, "one file shown");
is(scalar(() = $page =~ m/=>/g), 1, "exactly one link");

$page = query_gemini('gemini://localhost/basic.t');
like($page, qr"^20 text/gemini; charset=UTF-8\r\n", "File header");
like($page, qr"GNU General Public License", "File content");

$page = query_gemini('gemini://localhost/cert.pem');
like($page, qr"^50 ", "Do not serve cert.pem");

done_testing();
