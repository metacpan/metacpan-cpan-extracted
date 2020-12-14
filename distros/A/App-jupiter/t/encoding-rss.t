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

write_text("test-$id/rss2sample.opml", <<"EOT");
<opml version="2.0">
  <body>
    <outline title="العربيّة"
             xmlUrl="http://127.0.0.1:$port/"/>
  </body>
</opml>
EOT

my $rss = <<'EOT';
<?xml version="1.0" encoding='UTF-8'?>
<rss version="2.0">
   <channel>
      <title>Foo &amp; Bar</title>
      <link>https://alexschroeder.ch/</link>
      <pubDate>Mon, 13 Jan 2020 23:16:01 +0100</pubDate>
      <item>
         <title>السّلام عليك</title>
         <link>http://hello/wiki?user=Alex&amp;lang=ar</link>
         <description>&lt;style&gt;some CSS, I guess&lt;/style&gt;&lt;em&gt;D&amp;D&lt;/em&gt; is not bad!&lt;br&gt;You'll like &lt;span class='p-name'&gt;Foo &amp; Bar&lt;/span&gt;.</description>
         <author>&lt;span class='p-author h-card'&gt;Alex Schroeder&lt;/span&gt;</author>
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
is($doc->findvalue('//h3/a[position()=2]'), "السّلام عليك", "Encoded item title matches");
is($doc->findvalue('//li/a[position()=2]'), "Foo & Bar", "Encoded feed title matches");
is($doc->findvalue('//h3/a[position()=1]'), "Foo & Bar", "Encoded feed title matches again");
is($doc->findvalue('//h3/a[position()=2]/@href'), "http://hello/wiki?user=Alex&lang=ar", "Encoded link matches");
is($doc->findvalue('//div[@class="content"]'), q(D&D is not bad!¶ You'll like Foo & Bar.), "Content value matches");
is($doc->findnodes('//div[@class="content"]')->get_node(1)->toString(),
   q(<div class="content">D&amp;D is not bad!<span class="paragraph">¶ </span>You'll like Foo &amp; Bar.</div>),
   "Content HTML matches");
like($doc->findnodes('//div[@class="permalink"]')->get_node(1)->toString(),
     qr(by Alex Schroeder),
     "Author HTML matches");
unlike($doc->findvalue('//div[@class="content"]'), qr/CSS/, "Style is stripped");

ok(-f "test-$id/rss2sample.xml", "RSS was generated");
$doc = XML::LibXML->load_xml(location => "test-$id/rss2sample.xml");
like($doc->findvalue('/rss/channel/item/description'),
     qr/<em>D&D<\/em> is not bad!<br>You'll like <span class='p-name'>Foo & Bar<\/span>\./,
     "Encoded content matches");

done_testing;
