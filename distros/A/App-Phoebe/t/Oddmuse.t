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
use URI::Escape;
use Encode;
use Encode::Locale;
use File::Slurper qw(write_text);
use Test::More;
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
write_text("$oddmuse_dir/config", "\$SurgeProtection = 0;\n");

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

# Test Oddmuse, and create the Test page in the main namespace (with the text
# "Alex") and in the "Travels" namespace (with the text "Berta").
$res = $ua->get("http://localhost:$oddmuse_port/wiki?title=Test&text=Fnord")->result;
is($res->code, 302, "Oddmuse save page");
$res = $ua->get("http://localhost:$oddmuse_port/wiki?title=Test&text=Alex")->result;
is($res->code, 302, "Oddmuse updated page");
$res = $ua->get("http://localhost:$oddmuse_port/wiki?title=Test&text=Check%20out%20[[Bet]].&ns=Travels")->result;
is($res->code, 302, "Oddmuse save page in namespace");
$res = $ua->get("http://localhost:$oddmuse_port/wiki?title=Test&text=Bert&ns=Travels")->result;
is($res->code, 302, "Oddmuse save page in namespace");
$res = $ua->get("http://localhost:$oddmuse_port/wiki?title=Test&text=Berta&ns=Travels")->result;
is($res->code, 302, "Oddmuse updated page in namespace");
$res = $ua->get("http://localhost:$oddmuse_port/wiki/raw/Test")->result;
is($res->code, 200, "Oddmuse read page");
is($res->body, "Alex\n", "Oddmuse page content");
$res = $ua->get("http://localhost:$oddmuse_port/wiki/Travels/raw/Test")->result;
is($res->code, 200, "Oddmuse read page from namespace");
is($res->body, "Berta\n", "Oddmuse page content from namespace");

# Start Phoebe

our @use = qw(Oddmuse);
our @config = (<<"EOT");
package App::Phoebe::Oddmuse;
our \%oddmuse_wikis = ("localhost" => "http://localhost:$oddmuse_port/wiki");
our \%oddmuse_wiki_names = ("localhost" => "Test");
our \%oddmuse_wiki_dirs = ("localhost" => "$oddmuse_dir");
our \$server->{wiki_main_page} = "Welcome";
EOT
our $host = qw(localhost);
our $port;
our $base;
our $dir;

require './t/test.pl';

# Test Phoebe

like(query_gemini("$base/page"), qr(^31 $base/\r\n), "Reserved word");
like(query_gemini("$base/Travels/page"), qr(31 $base/Travels\r\n), "Reserved word (namespace)");

my $page = query_gemini("$base/page/Test");
like($page, qr(Alex), "Page");
like($page, qr(^=> $base/raw/Test Raw text$)m, "Raw link");
like($page, qr(^=> $base/html/Test HTML$)m, "HTML link");
like(query_gemini("$base/raw/Test"), qr(^Alex$)m, "Raw");
like(query_gemini("$base/html/Test"), qr(<p>Alex</p>), "HTML");

$page = query_gemini("$base/do/index");
like($page, qr(All Pages), "Index");
like($page, qr(^=> $base/page/Test Test$)m, "Page link");

$page = query_gemini("$base/do/changes");
like($page, qr(Changes), "Changes");
like($page, qr(^=> $base/page/Test Test \(current\)$)m, "Page link to current revision");
like($page, qr(^=> $base/history/Test History$)m, "History link");
like($page, qr(^=> $base/page/Test/1 Test \(1\)$)m, "Page link to revision 1");
like($page, qr(^=> $base/diff/Test/1 Differences$)m, "Diff link");

$page = query_gemini("$base/history/Test");
like($page, qr(^=> $base/page/Test Test \(current\)$)m, "Page link to current revision");
like($page, qr(^=> $base/page/Test/1 Test \(1\)$)m, "Page link to revision 1");
like($page, qr(^=> $base/diff/Test/1 Differences$)m, "Diff link");

$page = query_gemini("$base/diff/Test/1");
like($page, qr(^# Differences for Test$)m, "Diff");
like($page, qr(^Showing the differences between revision 1 and the current revision\.$)m, "Intro");
like($page, qr(^Changed line 1 from:\n> ｢Fnord｣$)m, "From");
like($page, qr(^to:\n> ｢Alex｣$)m, "To");

$page = query_gemini("$base/Travels/page/Test");
like($page, qr(Berta), "Page (namespace)");
like($page, qr(^=> $base/Travels/raw/Test Raw text$)m, "Raw link (namespace)");
like($page, qr(^=> $base/Travels/html/Test HTML$)m, "HTML link (namespace)");
like(query_gemini("$base/Travels/raw/Test"), qr(^Berta$)m, "Raw (namespace)");
like(query_gemini("$base/Travels/html/Test"), qr(<p>Berta</p>), "HTML (namespace)");

$page = query_gemini("$base/Travels/do/index");
like($page, qr(All Pages), "Index");
like($page, qr(^=> $base/Travels/page/Test Test$)m, "Page link");

like(query_gemini("$base/Travels/do/match"), qr(^10), "Match");
like(query_gemini("$base/Travels/do/match?test"), qr(^=> $base/Travels/page/Test Test$)m, "Page link");

like(query_gemini("$base/Travels/do/search"), qr(^10), "Search");
like(query_gemini("$base/Travels/do/search?alex"), qr(^=> $base/Travels/page/Test Test$)m, "Page link");

$page = query_gemini("$base/do/all/changes");
like($page, qr(^=> $base/page/Test Test)m, "All changes");
like($page, qr(^=> $base/Travels/page/Test \[Travels\] Test)m, "All changes (namespace)");

$page = query_gemini("$base/Travels/history/Test");
like($page, qr(^=> $base/Travels/page/Test Test \(current\)$)m, "Page link to current revision");
like($page, qr(^=> $base/Travels/page/Test/2 Test \(2\)$)m, "Page link to revision 2");
like($page, qr(^=> $base/Travels/diff/Test/2 Differences$)m, "Diff link for revision 2");
like($page, qr(^=> $base/Travels/page/Test/1 Test \(1\)$)m, "Page link to revision 1");
like($page, qr(^=> $base/Travels/diff/Test/1 Differences$)m, "Diff link for revision 1");

$page = query_gemini("$base/Travels/diff/Test/2");
like($page, qr(^# Differences for Test$)m, "Diff");
like($page, qr(^Showing the differences between revision 2 and the current revision\.$)m, "Intro");
like($page, qr(^Changed line 1 from:\n> ｢Bert｣$)m, "From");
like($page, qr(^to:\n> ｢Berta｣$)m, "To");

$page = query_gemini("$base/Travels/page/Test/1");
like($page, qr(^Check out Bet\.$)m, "Revision 1");
like($page, qr(^=> $base/Travels/page/Bet Bet$)m, "Link");

like(query_gemini("$base/do/rss"), qr(Test.*Alex)s, "RSS");
like(query_gemini("$base/Travels/do/rss"), qr(Test.*Berta)s, "RSS (namespace)");

like(query_gemini("$base/do/atom"), qr(Test.*Alex)s, "Atom");
like(query_gemini("$base/Travels/do/atom"), qr(Test.*Berta)s, "Atom (namespace)");

my $titan = "titan://$host:$port";

my $haiku = <<EOT;
The soundtrack of my
mysterious, dangerous
life plays in this bar
EOT

$page = query_gemini("$titan/raw/Haiku;size=66;mime=text/plain;token=hello", $haiku);
like($page, qr/^30 $base\/page\/Haiku\r$/, "Titan Haiku");

like(query_gemini("$base/page/Haiku"), qr(soundtrack), "Gemini proxy for Oddmuse");

$haiku = <<EOT;
Rain drumming on my
window blinds, relentlessly
and into the snow
EOT

$page = query_gemini("$titan/Travels/raw/Haiku;size=66;mime=text/plain;token=hello", $haiku);
like($page, qr/^30 $base\/Travels\/page\/Haiku\r$/, "Titan Haiku");

like(query_gemini("$base/Travels/page/Haiku"), qr(drumming), "Gemini proxy for Oddmuse");

# Formatting the main page

$res = $ua->get("http://localhost:$oddmuse_port/wiki?title=Welcome&text=Hello")->result;
is($res->code, 302, "Oddmuse save Welcome page");
$res = $ua->get("http://localhost:$oddmuse_port/wiki?title=2021-06-28&text=Hoi")->result;
is($res->code, 302, "Oddmuse save blog page");
like(query_gemini("$base"), qr(^Hello\n\nBlog:\n)m, "Main page including Welcome");
like(query_gemini("$base/do/blog"), qr(2021-06-28)m, "Blog including 2021-06-28");

# Leaving a comment

like(query_gemini("$base/page/2021-06-28"),
     qr(=> $base/do/comment/2021-06-28 Leave a short comment)m,
     "2021-06-28 has link to comments");
like(query_gemini("$base/do/comment/2021-06-28", undef, 0), # no cert!
     qr(^60)m, "Client certificate required in order to comment");
like(query_gemini("$base/do/comment/2021-06-28"),
     qr(^10)m, "Token required");
like(query_gemini("$base/do/comment/2021-06-28?lalala"),
     qr(^59)m, "Wrong token");
like(query_gemini("$base/do/comment/2021-06-28?hello"),
     qr(^10)m, "Input required");
$haiku = <<EOT;
The+city cries but
Our metal worms dig deeper
Every day, alas.
EOT
like(query_gemini("$base/do/comment/2021-06-28?" . uri_escape($haiku)),
     qr(^30 $base/page/Comments_on_2021-06-28)m, "Redirect");
like(query_gemini("$base/page/Comments_on_2021-06-28"),
     qr(The city cries), "Comment saved, plusses handled");

# Unit testing of text formatting rules

ok(require App::Phoebe, "load phoebe");
ok(require App::Phoebe::Oddmuse, "load oddmuse.pl");

$page = App::Phoebe::Oddmuse::oddmuse_gemini_text(undef, $host, "", "Testing [Foo:Bar baz]");
like($page, qr(^Testing baz$)m, "Namespace link with text, text");
like($page, qr(^=> gemini://localhost:1965/Foo/page/Bar baz$)m, "Namespace link with text, link");

$page = App::Phoebe::Oddmuse::oddmuse_gemini_text(undef, $host, "", "e.g. &#x2605; is ★");
like($page, qr(^e.g. ★ is ★$)m, "HTML entities that look like hash tags");

$page = App::Phoebe::Oddmuse::oddmuse_gemini_text(undef, $host, "", "it has [Tau_Subsector:?action=index 39 pages]");
like($page, qr(^it has 39 pages$)m, "index link inline text");
like($page, qr(^=> gemini://localhost:1965/Tau_Subsector/do/index 39 pages$)m, "index link");

$page = App::Phoebe::Oddmuse::oddmuse_gemini_text(undef, $host, "", qq{
This is a table.

|hello|
|kitten|

And this is the end.});
like($page, qr(^This is a table\.\n\n```\n\|hello\|\n\|kitten\|\n```\n\nAnd this is the end\.$)m, "table");

$page = App::Phoebe::Oddmuse::oddmuse_gemini_text(undef, $host, "", qq{
This is a list.

* first
- second

And this is the end.});
like($page, qr(^This is a list\.\n\n\* first\n\* second\n\nAnd this is the end\.$)m, "list");

done_testing();
