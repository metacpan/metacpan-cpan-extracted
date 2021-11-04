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
use Mojo::IOLoop;
use Mojo::UserAgent;
use Encode;
use Encode::Locale;
use Test::More;
use URI::Escape;
use utf8; # tests contain UTF-8 characters and it matters

my $msg;
if (not $ENV{TEST_AUTHOR}) {
  $msg = 'This is an author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
} else {
  for my $module (qw(CGI Mojolicious::Plugin::CGI DateTime::Format::ISO8601)) {
    if (not defined eval "require $module") {
      $msg = "You need to install the $module module for this test: $@";
      last;
    }
  }
}
plan skip_all => $msg if $msg;

# Start the Oddmuse server

my $oddmuse_port = Mojo::IOLoop::Server->generate_port;
my $oddmuse_dir = "./" . sprintf("test-%04d", int(rand(10000)));
mkdir $oddmuse_dir; # required so that the server can write the error log
mkdir "$oddmuse_dir/modules";
link "./t/oddmuse-namespaces.pl", "$oddmuse_dir/modules/namespaces.pl";

my $oddmuse_pid = fork();

END {
  # kill server
  if ($oddmuse_pid) {
    kill 'KILL', $oddmuse_pid or warn "Could not kill server $oddmuse_pid";
  }
}

if (!defined $oddmuse_pid) {
  die "Cannot fork Oddmuse: $!";
} elsif ($oddmuse_pid == 0) {
  say "This is the Oddmuse server listening on port $oddmuse_port...";
  $ENV{WikiDataDir} = $oddmuse_dir;
  no warnings "once";
  $OddMuse::RunCGI = 0;
  @ARGV = ("daemon", "-m", "production", "-l", "http://*:$oddmuse_port");
  # oddmuse-wiki.pl is a copy of Oddmuse's wiki.pl
  # oddmuse-server.pl is similar to Oddmuse's server.pl
  for my $file (qw(./t/oddmuse-wiki.pl ./t/oddmuse-server.pl)) {
    unless (my $return = do $file) {
      warn "couldn't parse $file: $@" if $@;
      warn "couldn't do $file: $!"    unless defined $return;
      warn "couldn't run $file"       unless $return;
    }
  }
  say "Oddmuse server done";
  exit;
}

my $ua = Mojo::UserAgent->new;
my $res;
my $total = 0;
my $ok = 0;

# What I'm seeing is that $@ is the empty string and $! is "Connection refused"
# even though I thought $@ would be set. Oh well.
say "This is the client waiting for the Oddmuse server to start on port $oddmuse_port...";
for (qw(1 1 1 1 2 2 3 4 5)) {
  if (not $total or not $res) {
    diag "$!: waiting ${_}s..." if $total > 0;
    $total += $_;
    sleep $_;
    $res = $ua->get("http://localhost:$oddmuse_port/wiki")->result;
  } else {
    $ok = 1;
    last;
  }
}

die "$!: giving up after ${total}s\n" unless $ok;

# Test Oddmuse, and create the Test page in the main namespace.
my $haiku = <<EOT;
The street is still dark
but up in the trees I hear
a blackbird singing
EOT

$res = $ua->get("http://localhost:$oddmuse_port/wiki?title=Haiku&text="
		. uri_escape("```\n$haiku```"))->result;
is($res->code, 302, "Oddmuse save page");
$res = $ua->get("http://localhost:$oddmuse_port/wiki/raw/Haiku")->result;
is($res->code, 200, "Oddmuse update");
like($res->body, qr/$haiku/, "Oddmuse saved the page");

# Start Phoebe

my $gopher_port = Mojo::IOLoop::Server->generate_port; # new port for Gopher
my $gophers_port = Mojo::IOLoop::Server->generate_port; # new port for Gophers

our @config = (<<"EOT");
package App::Phoebe::Oddmuse;
our \%oddmuse_wikis = ("localhost" => "http://localhost:$oddmuse_port/wiki");
our \%oddmuse_wiki_names = ("localhost" => "Test");
our \%oddmuse_wiki_dirs = ("localhost" => "$oddmuse_dir");

package App::Phoebe::Gopher;
our \$gopher_port = $gopher_port;
EOT

our @use = qw(Oddmuse Gopher); # the order is impotant!
our $host = qw(localhost);
our $port;
our $base;
our $dir;

require './t/test.pl';

# Test Phoebe

my $page = query_gemini("$base/page/Haiku");
like($page, qr($haiku), "Page retrieved via Gemini");

# Test Gopher (no TLS)

sub query_gopher {
  my $query = shift;
  # create client
  my $socket;
  $socket = IO::Socket::IP->new("$host:$gopher_port")
      or die "Cannot construct client socket: $@";
  $socket->print("$query\r\n");
  undef $/; # slurp
  return <$socket>;
}

my $titan = "titan://$host:$port";

my $gopher = $base;
$gopher =~ s/^gemini/gopher/;

$page = query_gopher("page/Haiku");
like($page, qr($haiku), "Page retrieved via Gopher");

# index
$page = query_gopher("do/index");
like($page, qr/Haiku/m, "index contains Haiku");

# blog page

$haiku = <<EOT;
Quickly type the words
Double check and read again
The flat so silent
EOT

$page = query_gemini("$titan/raw/2021-06-26%20Haiku;size=78;mime=text/plain;token=hello", "```\n$haiku```\n");
like($page, qr/^30 $base\/page\/2021-06-26%20Haiku\r$/, "Titan Haiku");

$page = query_gopher("page/2021-06-26%20Haiku");
like($page, qr/$haiku/, "Gemini Haiku");

$page = query_gopher("page/2021-06-26%20Haiku");
like($page, qr/$haiku/, "Gopher Haiku");

$page = query_gopher("");
like($page, qr/^02021-06-26 Haiku\tpage\/2021-06-26 Haiku\t$host\t$gopher_port/m, "Blog link in the main menu");

done_testing();
