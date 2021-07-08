# Copyright (C) 2020  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

use utf8;
use Encode;
use Modern::Perl;
use Test::More;
use File::Slurper qw(read_binary write_text);
use Mojo::JSON qw(decode_json encode_json);

do './t/test.pl';
my ($id, $port) = init();

write_text("test-$id/rss2sample.opml", <<"EOT");
<opml version="2.0">
  <body>
    <outline title="H&amp;H" xmlUrl="http://127.0.0.1:$port/"/>
  </body>
</opml>
EOT

my $rss = <<'EOT';
<?xml version="1.0" encoding='UTF-8'?>
<rss version="2.0">
   <channel>
      <title>Alex's Halberds &amp; Helmets</title>
      <link>https://alexschroeder.ch/</link>
      <pubDate>Mon, 13 Jan 2020 23:16:01 +0100</pubDate>
      <item>
         <title>Talking &amp; Fighting</title>
         <link>https://alexschroeder.ch/wiki/2018-12-19_Episode_01</link>
         <description>D&amp;D as an oral tradition: keep what you like, add what you need, drop what you keep forgetting.</description>
         <pubDate>Mon, 13 Jan 2020 23:16:01 +0100</pubDate>
      </item>
   </channel>
</rss>
EOT

start_daemon(encode_utf8 $rss);

Jupiter::update_cache("test-$id/rss2sample.opml");

stop_daemon();

my $messages = decode_json read_binary "test-$id/rss2sample.json";
is($messages->{"http://127.0.0.1:$port/"}->{title}, "H&amp;H", "Title was taken from the OPML file");

Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml");

$messages = decode_json read_binary "test-$id/rss2sample.json";
is($messages->{"http://127.0.0.1:$port/"}->{title}, "Alex&#39;s Halberds &amp; Helmets", "Title was taken from the feed");

ok(-f "test-$id/rss2sample.html", "HTML was generated");
my $doc = XML::LibXML->load_html(location => "test-$id/rss2sample.html");
is($doc->findvalue('//h3/a[position()=1]'), "Alex's Halberds & Helmets", "Encoded feed title matches again");
is($doc->findvalue('//h3/a[position()=2]'), "Talking & Fighting", "Encoded item title matches");
like($doc->findvalue('//div[@class="content"]'), qr(D&D as an oral tradition), "Content value matches");
like($doc->findvalue('//li'), qr(Alex's Halberds & Helmets), "Sidebar site link OK");

# Now repeat but with an empty feed

$rss = <<'EOT';
<?xml version="1.0" encoding='UTF-8'?>
<rss version="2.0">
   <channel>
      <title>Alex's Halberds &amp; Helmets</title>
      <link>https://alexschroeder.ch/</link>
      <pubDate>Mon, 13 Jan 2020 23:16:01 +0100</pubDate>
   </channel>
</rss>
EOT

start_daemon(encode_utf8 $rss);

Jupiter::update_cache("test-$id/rss2sample.opml");

stop_daemon();

Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml");

$messages = decode_json read_binary "test-$id/rss2sample.json";
is($messages->{"http://127.0.0.1:$port/"}->{message}, "Empty feed", "Message is correct");
is($messages->{"http://127.0.0.1:$port/"}->{title}, "Alex&#39;s Halberds &amp; Helmets", "Title from the feed was kept");

$doc = XML::LibXML->load_html(location => "test-$id/rss2sample.html");
like($doc->findvalue('//li'), qr(Alex's Halberds & Helmets), "Sidebar site link OK");
is($doc->findvalue('//li/a[@class="message"]/@title'), "Empty feed", "Sidebar message title matches");

done_testing;
