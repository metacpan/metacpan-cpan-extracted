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
use Mojo::IOLoop;
use Encode;
use Encode::Locale;

our $host;
our @hosts;
if ($host and not grep { $_ eq $host } @hosts) {
  push(@hosts, $host);
} elsif (not $host and @hosts) {
  $host = $hosts[0];
} else {
  $host = '127.0.0.1';
  @hosts = ($host);
}
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
  my $hosts = host_regex();
  my $port = port($stream);
  if ($url =~ m!^gemini://($hosts):$port/do/test$!) {
    $stream->write("20 text/plain\r\n");
    $stream->write("Test\n");
    return 1;
  }
  return;
}
no warnings 'redefine';
sub get_ip_numbers {
  return '127.0.0.1';
}

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
    local $/ = undef;
    my $data = <DATA>;
    my $pos = index($data, "-----BEGIN PRIVATE KEY-----");
    write_text("t/cert.pem", substr($data, 0, $pos));
    write_text("t/key.pem", substr($data, $pos));
  }
  use Config;
  my $secure_perl_path = $Config{perlpath};
  my @args = ("blib/script/phoebe",
	      # The test files containing hostnames are UTF-8 encoded, thus
	      # $host and @host are unicode strings. Command line parsing
	      # expects them encoded in the current locale, however.
	      (map { "--host=" . encode(locale => $_) } @hosts),
	      "--port=$port",
	      "--log_level=warn", # set to debug if you are bug hunting?
	      "--cert_file=t/cert.pem",
	      "--key_file=t/key.pem",
	      "--wiki_dir=$dir",
	      "--wiki_mime_type=image/jpeg",
	      (map { "--wiki_page=" . encode(locale => $_) } @pages),
	      (map { "--wiki_space=" . encode(locale => $_) } @spaces));
  exec($secure_perl_path, @args) or die "Cannot exec: $!";
}

sub query_gemini {
  my $query = shift;
  my $text = shift;
  my ($header, $mimetype, $encoding, $buffer);

  # create client
  Mojo::IOLoop->client({
    address => "127.0.0.1",
    port => $port,
    tls => 1,
    tls_cert => "t/cert.pem",
    tls_key => "t/key.pem",
    tls_verify => 0x00, } => sub {
      my ($loop, $err, $stream) = @_;
      die "Client creation failed: $err\n" if $err;
      $stream->on(error => sub {
	my ($stream, $err) = @_;
	die "Stream error: $err\n" if $err });
      $stream->on(close => sub {
	my ($stream) = @_;
	diag "Closing stream\n" if $ENV{TEST_VERBOSE} });
      $stream->on(read => sub {
	my ($stream, $bytes) = @_;
	diag "Reading " . length($bytes) . " bytes\n" if $ENV{TEST_VERBOSE};
	if ($header and $encoding) {
	  $buffer .= decode($encoding, $bytes);
	} elsif ($header) {
	  $buffer .= $bytes;
	} else {
	  ($header) = $bytes =~ /^(.*?)\r\n/;
	  $header = decode_utf8 $header;
	  if ($header =~ /^2\d* (?:text\/\S+)?(?:; *charset=(\S+))?$/g) {
	    # empty, or text without charset defaults to UTF-8
	    $encoding = $1 || 'UTF-8';
	  }
	  $bytes =~ s/^(.*?)\r\n//;
	  if ($encoding) {
	    $buffer .= decode($encoding, $bytes);
	  } else {
	    $buffer .= $bytes;
	  }
	}});
      # Write request
      $stream->write("$query\r\n");
      $stream->write($text) if $text });
  # Start event loop if necessary
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

  # When we're done
  return "" unless $header;
  return "$header\r\n$buffer";
}

sub query_web {
  my $query = shift;
  return query_gemini("$query\r\n"); # add empty line
}

say "This is the client waiting 1s for the server to start on port $port...";
sleep 1; eval { query_gemini("gemini://$host:$port/") };
if ($@) { say "One more second..."; sleep 1; eval { query_gemini("gemini://$host:$port/") }}
if ($@) { say "Just one more second..."; sleep 1; eval { query_gemini("gemini://$host:$port/") }}
if ($@) { say "Another second..."; sleep 1; eval { query_gemini("gemini://$host:$port/") }}
if ($@) { say "One last second..."; sleep 1; eval { query_gemini("gemini://$host:$port/") }}
if ($@) { say "Still getting an error: $@" }

1;

__DATA__
-----BEGIN CERTIFICATE-----
MIIDCzCCAfOgAwIBAgIUW+gNk6Z1w3dPB0WtWtCNInwtW/kwDQYJKoZIhvcNAQEL
BQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MCAXDTIwMTIwMzE5NTg1M1oYDzIyOTQw
OTE4MTk1ODUzWjAUMRIwEAYDVQQDDAlsb2NhbGhvc3QwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQCslQ7E/XcCZHoWkKhu7xs7RHy/JpuQJpbf/pbAoubo
AiyUhRMf1utmsFUDWgi81lynuQk57cizzzlqds8RJY5B1of/7uOtnmhbP/+nsBOA
TTR7/foE3hmR/15jEecsStBnJKJ7+yWEYXPk3oEffeKwKDx3C2cjPcUYBRhUZb6s
aiVMfDLKrj4UcnzlvIWdIYhLUglskpFFMsqmyEx9+cXI17F394RVZXGKPf2OoCob
G4j8AOF+cZkzIv/YyOvE2xFI8CeGHcnMG6UBnE/BY4ieAJLYKb+cjjA5BUbmbCsX
Qy3GJMYENMkYdK+xEzJy86WZ/mS9MyT2Dcpm1OHIpatNAgMBAAGjUzBRMB0GA1Ud
DgQWBBSN6uSoe6rY21xZHUbouckiwO5aoDAfBgNVHSMEGDAWgBSN6uSoe6rY21xZ
HUbouckiwO5aoDAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQBZ
Q9d9TChIWfgnKpjAWVU/b2pqIf55C3OSAQij9NDHQbztUrWvH06dTtocsjdPDv+m
vx6Jqe/Ts9XdV1c+QkhPgpM310WvdzN0Y+yz9cgAPXVco1sDQwGYcqROIgz5IN3t
voxAVGWFU+Ykobp2Ag/Hjg4zGkq0KOBm8F0cPMJhYvC9LuFXNu1sDOqcPkxhA/KX
eW/XY1x+tAkTBCAotJYt0wqPo0rTK5KJZExTf4mV2lCZEJvi9vFP9Ouncui16Vke
fUypocmDBk+DKikiSfYwyTwISM/6HbnxsaIJDe+Wq5W4c5GPeYPU5+q5pwW6C4t5
xnkyAbNZ5n/obWzmAZXg
-----END CERTIFICATE-----
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCslQ7E/XcCZHoW
kKhu7xs7RHy/JpuQJpbf/pbAouboAiyUhRMf1utmsFUDWgi81lynuQk57cizzzlq
ds8RJY5B1of/7uOtnmhbP/+nsBOATTR7/foE3hmR/15jEecsStBnJKJ7+yWEYXPk
3oEffeKwKDx3C2cjPcUYBRhUZb6saiVMfDLKrj4UcnzlvIWdIYhLUglskpFFMsqm
yEx9+cXI17F394RVZXGKPf2OoCobG4j8AOF+cZkzIv/YyOvE2xFI8CeGHcnMG6UB
nE/BY4ieAJLYKb+cjjA5BUbmbCsXQy3GJMYENMkYdK+xEzJy86WZ/mS9MyT2Dcpm
1OHIpatNAgMBAAECggEAOhmIOlsWKJEI5PXYLliCs2YwFO37awECw+/icoGk+LBa
r7lJIevpnc15IUK7NE96K+DIMV9StO3rZ2MN/LjG9nUxncCfl4B/o1CdUaeeORBE
vgVXmTHoK9VrwjBxweCB3mdf6Bs5myJvsLoTgDWSDjnNeUo2c4/E/Xwhn7ANC9+2
T/Oimm+Z6tp4DRUUPDTt9ITZT1Jecd7UPgY55LSozXOWq45Kdmn+WUqa0oJexkiX
sCOGbY84jqBzxaRdA+IPa8QG4QaWmGPz4kACpb3mBudeYkaCFSedH6gx7raiq7Yo
v5fIKTiI7gOSwQNvTuOAeFEoJw2ULjNHDLtAYwQAJQKBgQDgfoPqG+2ADxP12UzH
Qr6OMNUAxsUf4xj8AP2qCCFWhabgi5dhT569bpSqVhsJfUP6qMAug1HvT0iqzHvl
/xKQtz/lZKafxzNg8d81y1gs7C31209YVgeY9i3g+fXq/M9tm21sqyqCAdTHApQT
kJLlRON410cr5EknOT8J8QhJUwKBgQDEzXuu2PCFFzjUfj0RqQfg/TRRpBm/ckLD
1c+9rpz5aHqHiCXpfGywbTJ8BB43RRjS7RKynso9b/LzDvfQJtHCDDBxOiy8ApSO
wpc07f8/R+ShK0FdkUzE6pKYp1Xfibprhlz8lKkcfKUq9qp3Wr1OK9lG7xRrM062
OvXSqgWE3wKBgHTV41moB0cqkbzVxvu9ZOcjyveIe3dI/evJqDsh2BfrnxomDDb8
9SSptH2iKpgZtZNy1/JdLftaS/t4SNM+mS7v8DU22PE2/yppNz4MAmv+zzyxUu4q
d/HHzcDU1oPh5yKoTZ7Mxma7BT49vUshZxIjdC+j+sqBGQFs7b4Cz8k5AoGBALfS
84dDLY4zPasF60b2qtxVxivH6yDuujwwF6YmVouEMocr/bWUufUlWjWKpyqbCO/j
70YWmfM/ASBVR9YOnHjzZ8ArRaOriVW7nv8amwNhxMViIOEkGiAItzuNeeGdxRow
W+S1eyyXpLN3yYxInnBI9t+R63GicBA5DGpk01jjAoGAKSMCDIm/x2U8Supe2bcn
UiubRcnZAt4VVi5mftjLd8ah0ykqJaHcgzmHP426ldJW1quNhkUTuEyH4778tUkY
QDfnz/a4tmi+ZK5P5oe0ECCLnvCRZNlpiJGCJT+b1qZvowrEDy+sBtbAl65JIwON
FTn8pVaxxN55fnLqWQjM2eE=
-----END PRIVATE KEY-----
