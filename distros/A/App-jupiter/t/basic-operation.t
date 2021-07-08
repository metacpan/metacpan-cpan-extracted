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

use Modern::Perl;
use Test::More tests => 32;
use XML::LibXML;
use File::Slurper qw(read_binary write_binary);
use Mojo::JSON qw(decode_json encode_json);

do './t/test.pl';
my ($id, $port) = init();
save_opml('rss2sample.opml');

my $rss = read_binary("t/rss2sample.xml");

start_daemon($rss);

Jupiter::update_cache("test-$id/rss2sample.opml");

stop_daemon();

ok(-d "test-$id/rss2sample", "Cache was created");
ok(-f "test-$id/rss2sample/http127001$port", "Feed was cached");
is(read_binary("test-$id/rss2sample/http127001$port"), $rss, "Cached feed matches");
ok(-f "test-$id/rss2sample.json", "Messages were cached");

my $messages = decode_json read_binary "test-$id/rss2sample.json";
ok($messages->{"http://127.0.0.1:$port/"}, "Messages for this feed were cached");
is($messages->{"http://127.0.0.1:$port/"}->{code}, "200", "HTTP status code is 200");
is($messages->{"http://127.0.0.1:$port/"}->{message}, "OK", "HTTP status message is 'OK'");
is($messages->{"http://127.0.0.1:$port/"}->{title}, "Feed", "Title was taken from the OPML file");

Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml");

ok(-f "test-$id/rss2sample.html", "HTML was generated");
my $html = read_binary "test-$id/rss2sample.html";
unlike($html, qr/syntax error at template/, "No syntax errors in the HTML");
my $doc = XML::LibXML->load_html(string => $html);
ok($doc->findnodes('//a[@href="http://127.0.0.1:' . $port . '/"]'
		   . '/img[@src="feed.png"][@alt="(feed)"]'), "Sidebar feed link OK");
ok($doc->findnodes('//a[@class="message"][@title="No feed updates in 90 days"]'
		   . '[@href="http://liftoff.msfc.nasa.gov/"][text()="Liftoff News"]'),
   "Sidebar site link OK");

my $feed = XML::LibXML->load_xml(string => $rss);
my @items = $feed->findnodes('//item');
for my $item (@items) {
  my $title = $item->findvalue('title');
  my $found = $doc->findnodes('//h3/a[text()="' . ($title||"Untitled") . '"]');
  ok($found, "Found in the HTML: " . ($title||"Untitled"));
  my $category = $item->findvalue('category'); # assuming just one per item in the example
  if ($category) {
    $found = $doc->findnodes('//div[@class="post"][h3/a[text()="' . ($title||"Untitled") . '"]]/div[@class="categories"]/ul/li[text()="' . $category . '"]');
    ok($found, "Found in the HTML: $category");
  }
}

$messages = decode_json read_binary "test-$id/rss2sample.json";
is($messages->{"http://127.0.0.1:$port/"}->{code}, "206", "HTTP status code is 206");
is($messages->{"http://127.0.0.1:$port/"}->{message}, "No feed updates in 90 days",
   "HTTP status message says no updates in a long time");
is($messages->{"http://127.0.0.1:$port/"}->{title}, "Liftoff News", "Title was taken from the feed");

my $generated = XML::LibXML->load_xml(location => "test-$id/rss2sample.xml");
ok($generated, "A XML file was also generated");
for my $item (@items) {
  my $link = $item->findvalue('link');
  if ($link) {
    my $found = $generated->findnodes("//link[text()='$link']");
    ok($found, "Found in the feed: $link");
  }
  my $title = $item->findvalue('title');
  if ($title) {
    my $found = $generated->findnodes(qq(//title[text()="$title"]));
    ok($found, "Found in the feed: $title");
  }
  my $category = $item->findvalue('category'); # assuming just one per item in the example
  if ($category) {
    my $found = $generated->findnodes(qq(//item[title[text()="$title"]]/category[text()="$category"]));
    ok($found, "Found in the feed: $category");
  }
}

done_testing;
