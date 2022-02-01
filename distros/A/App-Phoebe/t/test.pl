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
use File::Slurper qw(write_text read_text read_dir);
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
our $example;

# Generating the config file for this test
our @config;
our @use;

mkdir($dir);
my $config = <<'EOT';
# package is App::Phoebe
use Modern::Perl;
no warnings 'redefine';
sub get_ip_numbers { '127.0.0.1' }
EOT
$config .= join("\n", @config) if @config;
$config .= join("", map { "use App::Phoebe::$_;\n" } @use) if @use;
if ($example) {
  my $found;
  for my $file ("blib/lib/App/Phoebe.pm", map { "blib/lib/App/Phoebe/$_" } grep /\.pm$/, read_dir("blib/lib/App/Phoebe")) {
    my $source = read_text($file);
    if ($source =~ /^(    # tested by $0\n(?:    .*\n|\t.*\n|\n)+)/m) {
      $example = $1;
      $example =~ s/\t/        /g;
      $example =~ s/^    //gm;
      $config .= $example;
      $found = 1;
      last;
    }
  }
  die "Did not find the sources for $0\n" unless $found;
  # test $example at the end
}
write_text("$dir/config", $config . "\n1;\n") if $config;

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
  my $cert = shift // 1; # suppress use of client certificate in the test
  my $cert_file = [undef, "t/cert.pem", "t/cert2.pem"]->[$cert];
  my $key_file = [undef, "t/key.pem", "t/key2.pem"]->[$cert];
  my ($header, $mimetype, $encoding, $buffer);
  # create client
  Mojo::IOLoop->client(
    {
      address => "localhost",
      port => $port,
      tls => 1,
      tls_cert => $cert_file,
      tls_key => $key_file,
      tls_options => { SSL_verify_mode => 0x00 },
    } => sub {
      my ($loop, $err, $stream) = @_;
      die "Client creation failed: $err\n" if $err;
      $stream->timeout(2);
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
      $stream->write($query);
      $stream->write("\r\n") unless $query =~ /^POST/; # GET and Gemini requests end in \r\n
      $stream->write($text) if $text });
  # Start event loop if necessary
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

  # When we're done
  return "" unless $header;
  return "$header\r\n$buffer";
}

sub query_web {
  my $query = shift;
  my $cert = shift // 1; # suppress use of client certificate in the test
  $query .= "\r\n" unless $query =~ /^POST/; # add empty line for GET requests
  my $response = query_gemini($query, undef, $cert);
  # fixup encoding for two trivial cases of encoding html
  my $header_end = index($response, "\r\n\r\n");
  if (substr($response, 0, $header_end + 2) =~ /content-type: text\/[a-z]+; charset=(\S+)/i
      or substr($response, $header_end + 4) =~ /<meta charset=\"(\S+)\">/i) {
    my $encoding = $1;
    $response = substr($response, 0, $header_end + 4)
	. decode($encoding, substr($response, $header_end + 4));
  }
  return $response;
}

my $total = 0;
my $ok = 0;

# What I'm seeing is that $@ is the empty string and $! is "Connection refused"
# even though I thought $@ would be set. Oh well.
say "This is the Phoebe client waiting for the server to start on port $port...";
# In order to avoid "skipped: Giving up after 5s" by CPAN tester gregor herrmann,
# make sure to wait more than that!
for (qw(1 1 1 1 1 2 3 5)) {
  if (not $total or $!) {
    $total += $_;
    sleep $_;
    eval { query_gemini("gemini://$host:$port/") };
  } else {
    $ok = 1;
    last;
  }
}

plan skip_all => "Giving up after ${total}s\n" unless $ok;

# We cannot test $example up above; we must run this test once we established
# that the plan is not to skil all. If we don't wait, we'll get the following
# error: "Parse errors: Bad plan. You planned 0 tests but ran 1."
like($example, qr/^# tested by $0\n/, "Example found") if $ok and $example;

1;
