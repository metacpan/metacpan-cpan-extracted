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

my $filename = 'rss2sample.opml';
write_binary("test-$id/$filename", <<"EOT");
<opml version="2.0">
  <body>
    <outline title="Feed" xmlUrl="http://127.0.0.1:$port/" htmlUrl="https://alexschroeder.ch/"/>
  </body>
</opml>
EOT

my $rss = <<'EOT';
<?xml version="1.0" encoding='UTF-8'?>
<rss version="2.0">
  <channel>
    <title>Elements</title>
    <link>https://join.mastodon.org/</link>
    <pubDate>Thu, 16 Jan 2020 22:59:54 +0100</pubDate>
    <item>
      <title>Encoded Content</title>
      <description><![CDATA[I love the fediverse!]]></description>
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
is($doc->findvalue('//div[@id="sidebar"]/ul/li/a[@class="message"]/@href'),
   "https://alexschroeder.ch/", "Feed link matches");
is($doc->findvalue('//div[@class="content"]'), "I love the fediverse!", "Encoded content extracted");

done_testing;
