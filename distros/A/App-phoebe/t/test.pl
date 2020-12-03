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
use Mojo::IOLoop::Server;

our $host //= "127.0.0.1";
our @hosts;
@hosts = ($host) unless @hosts;
our @pages;
our @spaces;
our $port = Mojo::IOLoop::Server->generate_port;
our $base = "gemini://$host:$port";
our $dir = "./" . sprintf("test-%04d", int(rand(10000)));

mkdir($dir);
write_text("$dir/config", <<'EOT');
package App::Phoebe;
use Modern::Perl;
our (@init, @extensions, @main_menu);
push(@main_menu, "=> gemini://localhost:1965/do/test Test");
push(@extensions, \&serve_test);
sub serve_test {
  my $stream = shift;
  my $url = shift;
  my $host = host_regex();
  my $port = port($stream);
  if ($url =~ m!^gemini://($host):$port/do/test$!) {
    $stream->write("20 text/plain\r\n");
    $stream->write("Test\n");
    return 1;
  }
  return;
}
1;
EOT

our $pid = fork();

END {
  # kill server
  if ($pid) {
    kill 'KILL', $pid or warn "Could not kill server $pid";
  }
}

if (!defined $pid) {
  die "Cannot fork: $!";
} elsif ($pid == 0) {
  say "This is the server listening on port $port...";
  if (not -f "t/cert.pem" or not -f "t/key.pem") {
    my $version = qx(openssl version)
	or die "Cannot invoke openssl to create certificates\n";
    diag "Creating certificates using $version";
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
  use Config;
  my $secure_perl_path = $Config{perlpath};
  my @args = ("blib/script/phoebe",
	      (map { "--host=$_" } @hosts),
	      "--port=$port",
	      "--log_level=warn", # set to debug if you are bug hunting?
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
      or die "Cannot construct client socket to $port: $@";

  print $socket "$query\r\n";
  print $socket $text if defined $text;

  undef $/; # slurp
  return <$socket>;
}

sub query_web {
  my $query = shift;
  return query_gemini("$query\r\n"); # add empty line
}

say "This is the client waiting for the server to start on port $port...";
sleep 1;

1;
