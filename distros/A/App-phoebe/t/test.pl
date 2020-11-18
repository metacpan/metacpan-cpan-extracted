# Copyright (C) 2017–2020  Alex Schroeder <alex@gnu.org>
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
use IO::Socket::SSL;
use File::Slurper qw(write_text);

our $host //= "127.0.0.1";
our @hosts;
@hosts = ($host) unless @hosts;
our @pages;
our @spaces;
our $port = random_port();
our $base = "gemini://$host:$port";
our $dir = "./" . sprintf("test-%04d", int(rand(10000)));

sub random_port {
  use Errno qw(EADDRINUSE);
  use Socket;

  my $family = PF_INET;
  my $type   = SOCK_STREAM;
  my $proto  = getprotobyname('tcp')  or die "getprotobyname: $!";
  my $host   = INADDR_ANY;  # Use inet_aton for a specific interface

  for my $i (1..3) {
    my $port   = 1024 + int(rand(65535 - 1024));
    socket(my $sock, $family, $type, $proto) or die "socket: $!";
    my $name = sockaddr_in($port, $host)     or die "sockaddr_in: $!";
    setsockopt($sock, SOL_SOCKET, SO_REUSEADDR, 1);
    bind($sock, $name)
	and close($sock)
	and return $port;
    die "bind: $!" if $! != EADDRINUSE;
    print "Port $port in use, retrying...\n";
  }
  die "Tried 3 random ports and failed.\n"
}

our $pid = fork();

mkdir($dir);
write_text("$dir/config", <<'EOT');
package App::Phoebe;
use Modern::Perl;
our (@init, @extensions, @main_menu);
push(@main_menu, "=> gemini://localhost:1965/do/test Test");
push(@extensions, \&serve_test);
sub serve_test {
  my $self = shift;
  my $url = shift;
  my $host = $self->host_regex();
  my $port = $self->port();
  if ($url =~ m!^gemini://($host):$port/do/test$!) {
    say "20 text/plain\r";
    say "Test";
    return 1;
  }
  return;
}
1;
EOT

END {
  # kill server
  if ($pid) {
    kill 'KILL', $pid or warn "Could not kill server $pid";
  }
}

if (!defined $pid) {
  die "Cannot fork: $!";
} elsif ($pid == 0) {
  say "This is the server...";
  if (not -f "t/cert.pem" or not -f "t/key.pem") {
    my $version = qx(openssl version);
    if (not $version) {
      die "Cannot invoke openssl to create certificates\n";
    } elsif ($version =~ /^OpenSSL 1\.0\./) {
      my $cmd = qq(openssl req -new -x509 -newkey rsa -subj /CN=localhost )
	  . qq( -days 1825 -nodes -out t/cert.pem -keyout t/key.pem);
      system($cmd) == 0 or die "openssl failed to create t/cert.pem and t/key.pem: $?";
    } else {
      my $cmd = qq(openssl req -new -x509 -newkey ec -subj /CN=localhost )
	  . qq(-pkeyopt ec_paramgen_curve:prime256v1 -days 1825 -nodes -out t/cert.pem -keyout t/key.pem);
      system($cmd) == 0 or die "openssl failed to create t/cert.pem and t/key.pem: $?";
    }
  }
  use Config;
  my $secure_perl_path = $Config{perlpath};
  my @args = ("blib/script/phoebe",
	      (map { "--host=$_" } @hosts),
	      "--port=$port",
	      "--log_level=" . ($ENV{DEBUG}||0), # set to 4 for verbose logging
	      "--cert_file=t/cert.pem",
	      "--key_file=t/key.pem",
	      "--wiki_dir=$dir",
	      "--wiki_mime_type=image/jpeg",
	      (map { "--wiki_page=$_" } @pages),
	      (map { "--wiki_space=$_" } @spaces));
  exec($secure_perl_path, @args) or die "Cannot exec: $!";
}

sub query_gemini {
  my $query = shift;
  my $text = shift;

  # create client
  my $socket = IO::Socket::SSL->new(
    PeerHost => "127.0.0.1",
    PeerService => $port,
    SSL_verify_mode => SSL_VERIFY_NONE)
      or die "Cannot construct client socket: $@";

  print $socket "$query\r\n";
  print $socket $text if defined $text;

  undef $/; # slurp
  return <$socket>;
}

say "This is the client waiting for the server to start...";
sleep 1;

1;
