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
use File::Slurper qw(write_text);
use Mojo::IOLoop;
use File::Copy;
use Encode;
use Encode::Locale;

require './t/cert.pl';

our $host;
our @hosts;
if ($host and not grep { $_ eq $host } @hosts) {
  push(@hosts, $host);
} elsif (not $host and @hosts) {
  $host = $hosts[0];
} else {
  $host = "localhost";
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
our $speed_bump_requests = 2;
our $speed_bump_window = 5;
our @known_fingerprints = qw(
  sha256$0ba6ba61da1385890f611439590f2f0758760708d1375859b2184dcd8f855a00);
EOT

our @config;
if (@config) {
  mkdir("$dir/conf.d");
  my $i = 0;
  for my $config (@config) {
    if ($config =~ /\n/) {
      # make sure this is loaded at the very end
      write_text("$dir/conf.d/__$i.pl", $config);
      $i++;
    } else {
      copy("contrib/$config", "$dir/conf.d/$config") or die "Failed to install $config: $!";
    }
  }
}

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
  say "This is the Phoebe server listening on port $port...";
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
  Mojo::IOLoop->client(
    {
      address => "localhost",
      port => $port,
      tls => 1,
      tls_cert => "t/cert.pem",
      tls_key => "t/key.pem",
      tls_options => { SSL_verify_mode => 0x00 },
    } => sub {
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

my $total = 0;
my $ok = 0;

# What I'm seeing is that $@ is the empty string and $! is "Connection refused"
# even though I thought $@ would be set. Oh well.
say "This is the Phoebe client waiting for the server to start on port $port...";
for (qw(1 1 1 1 2 2 3 4 5)) {
  if (not $total or $!) {
    diag "$!: waiting ${_}s..." if $total > 0;
    $total += $_;
    sleep $_;
    eval { query_gemini("gemini://$host:$port/") };
  } else {
    $ok = 1;
    last;
  }
}

die "$!: giving up after ${total}s\n" unless $ok;

1;
