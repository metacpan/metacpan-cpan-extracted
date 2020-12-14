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
    <title>Wiki</title>
    <link>https://join.mastodon.org/</link>
    <pubDate>Thu, 16 Jan 2020 22:59:54 +0100</pubDate>
    <dc:creator>Chris</dc:creator>
    <item>
      <title>Page</title>
      <description>Wikis are collaborative things.</description>
      <author>Alex</author>
      <author>Berta</author>
      <pubDate>Sun, 19 Jan 2020 13:48:14 +0100</pubDate>
    </item>
    <item>
      <title>Anonymous</title>
      <description>Nothing here.</description>
      <pubDate>Sun, 19 Jan 2020 13:48:13 +0100</pubDate>
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
is($doc->findvalue('//div[@class="post"][position()=1]/div[@class="content"]'), "Wikis are collaborative things.", "Content matches");
like($doc->findvalue('//div[@class="post"][position()=1]/div[@class="permalink"]'), qr/Alex, Berta/, "Both authors are listed");
is($doc->findvalue('//div[@class="post"][position()=2]/div[@class="content"]'), "Nothing here.", "Content matches");
like($doc->findvalue('//div[@class="post"][position()=2]/div[@class="permalink"]'), qr/Chris/, "Default author is listed");

ok(-f "test-$id/rss2sample.xml", "XML was generated");
$doc = XML::LibXML->load_xml(location => "test-$id/rss2sample.xml");
my $xpc = XML::LibXML::XPathContext->new($doc);
$xpc->registerNs('dc', 'http://purl.org/dc/elements/1.1/');
ok($xpc->findvalue('/rss/channel/item/dc:creator[text()="Alex"]'), "Alex was listed as an author");
ok($xpc->findvalue('/rss/channel/item/dc:creator[text()="Berta"]'), "Berta was listed as an author");
ok($xpc->findvalue('/rss/channel/item/dc:creator[text()="Chris"]'), "Chris was listed as an author");

done_testing;
