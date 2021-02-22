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
use utf8; # tests contain UTF-8 characters and it matters

 SKIP: {

   unless (eval { require CGI }) {
     plan skip_all => 'Needs CGI module for Oddmuse tests';
   }

   unless (eval { require Mojolicious::Plugin::CGI }) {
     plan skip_all => 'Needs Mojolicious::Plugin::CGI module for Oddmuse tests';
   }

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

   # test Oddmuse
   $res = $ua->get("http://localhost:$oddmuse_port/wiki?title=Test&text=Alex")->result;
   is($res->code, 302, "Oddmuse save page");
   $res = $ua->get("http://localhost:$oddmuse_port/wiki?title=Test&text=Berta&ns=Travels")->result;
   is($res->code, 302, "Oddmuse save page");
   $res = $ua->get("http://localhost:$oddmuse_port/wiki/raw/Test")->result;
   is($res->code, 200, "Oddmuse read page");
   is($res->body, "Alex\n", "Oddmuse page content");
   $res = $ua->get("http://localhost:$oddmuse_port/wiki/Travels/raw/Test")->result;
   is($res->code, 200, "Oddmuse read page from namespace");
   is($res->body, "Berta\n", "Oddmuse page content from namespace");

   # Start Phoebe

   my $config = <<"EOT";
our %oddmuse_wikis = ("localhost" => "http://localhost:$oddmuse_port/wiki");
our %oddmuse_wiki_names = ("localhost" => "Test");
our %oddmuse_wiki_dirs = ("localhost" => "$oddmuse_dir");
EOT

   our @config = ('oddmuse.pl', $config);
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
   like($page, qr(^=> gemini://localhost:$port/raw/Test Raw text$)m, "Raw link");
   like($page, qr(^=> gemini://localhost:$port/html/Test HTML$)m, "HTML link");
   like(query_gemini("$base/raw/Test"), qr(^Alex$)m, "Raw");
   like(query_gemini("$base/html/Test"), qr(<p>Alex</p>), "HTML");

   $page = query_gemini("$base/Travels/page/Test");
   like($page, qr(Berta), "Page (namespace)");
   like($page, qr(^=> gemini://localhost:$port/raw/Test Raw text$)m, "Raw link (namespace)");
   like($page, qr(^=> gemini://localhost:$port/html/Test HTML$)m, "HTML link (namespace)");
   like(query_gemini("$base/Travels/raw/Test"), qr(^Berta$)m, "Raw (namespace)");
   like(query_gemini("$base/Travels/html/Test"), qr(<p>Berta</p>), "HTML (namespace)");

   $page = query_gemini("$base/do/all/changes");
   like($page, qr(^=> gemini://localhost:$port/page/Test Test)m, "All changes");
   like($page, qr(^=> gemini://localhost:$port/Travels/page/Test \[Travels\] Test)m, "All changes (namespace)");

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

}

done_testing();

1;
