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
use File::Slurper qw(write_binary read_binary write_text);

do './t/test.pl';
my ($id, $port) = init();
save_opml('rss2sample.opml');

my $rss = <<'EOT';
<?xml version="1.0" encoding='UTF-8'?>
<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Duplicates</title>
    <item>
      <guid>the guid</guid>
      <title>just the guid</title>
      <pubDate>Sun, 19 Jan 2020 13:20:17 +0100</pubDate>
    </item>
    <item>
      <guid>the guid</guid>
      <title>same guid as before</title>
      <pubDate>Sun, 19 Jan 2020 13:20:16 +0100</pubDate>
    </item>
    <item>
      <link>the link</link>
      <title>just the link</title>
      <pubDate>Sun, 19 Jan 2020 13:20:15 +0100</pubDate>
    </item>
    <item>
      <link>the link</link>
      <title>same link as before</title>
      <pubDate>Sun, 19 Jan 2020 13:20:14 +0100</pubDate>
    </item>
    <item>
      <title>the title</title>
      <description>just the title</description>
      <pubDate>Sun, 19 Jan 2020 13:20:13 +0100</pubDate>
    </item>
    <item>
      <title>the title</title>
      <description>same title as before</description>
      <pubDate>Sun, 19 Jan 2020 13:20:12 +0100</pubDate>
    </item>
    <item>
      <!-- just the description -->
      <description>the description</description>
      <pubDate>Sun, 19 Jan 2020 13:20:11 +0100</pubDate>
    </item>
    <item>
      <!-- same description -->
      <description>the description</description>
      <pubDate>Sun, 19 Jan 2020 13:20:10 +0100</pubDate>
    </item>
  </channel>
</rss>
EOT

start_daemon(encode_utf8 $rss);

Jupiter::update_cache("test-$id/rss2sample.opml");

stop_daemon();

Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml");

ok(-f "test-$id/rss2sample.html", "HTML was generated");
my $doc = XML::LibXML->load_html(location => "test-$id/rss2sample.html");
is($doc->findnodes('//div[@class="post"]')->size(), 4, "All duplicates in the HTML are eliminated");
like($doc->findvalue('//div[@class="post"][position()=1]'), qr"just the guid", "GUID deduplicated");
like($doc->findvalue('//div[@class="post"][position()=2]'), qr"just the link", "Link deduplicated");
like($doc->findvalue('//div[@class="post"][position()=3]'), qr"just the title", "Title deduplicated");
like($doc->findvalue('//div[@class="post"][position()=4]'), qr"the description", "Description is there");

done_testing;
