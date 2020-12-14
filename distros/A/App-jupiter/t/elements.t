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
is($doc->findvalue('//li/a[position()=2]'), "Elements", "Elements feed title matches");
is($doc->findvalue('//div[@class="content"]'), "I love the fediverse!", "Encoded content extracted");

use DateTime;
my $now = DateTime->now;

my $atom = <<"EOT";
<?xml version="1.0" encoding='UTF-8'?>
<feed xmlns='http://www.w3.org/2005/Atom'>
<updated>$now</updated>
<title type='text'>Textual</title>
<entry>
<updated>$now</updated>
<title type='text'>Current</title>
<summary type='text'>
Snail is best.
</summary>
</entry>
</feed>
EOT

start_daemon(encode_utf8 $atom);

Jupiter::update_cache("test-$id/rss2sample.opml");

stop_daemon();

Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml");

ok(-f "test-$id/rss2sample.html", "HTML was generated, again");
$doc = XML::LibXML->load_html(location => "test-$id/rss2sample.html");
is($doc->findvalue('//div[@class="content"]'), "Snail is best.", "Text content extracted");
ok(!$doc->findvalue('//li/a[@class="message"]'), "Message is empty in the info list");

my $old = '2018-12-01T04:24:13.964-06:00';

$atom = <<"EOT";
<?xml version="1.0" encoding='UTF-8'?>
<feed xmlns='http://www.w3.org/2005/Atom'>
<updated>$old</updated>
<title type='text'>Textual</title>
<entry>
<updated>$now</updated>
<title type='text'>Current</title>
<summary type='text'>
Snail is best.
</summary>
</entry>
</feed>
EOT

start_daemon(encode_utf8 $atom);

Jupiter::update_cache("test-$id/rss2sample.opml");

stop_daemon();

Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml");

$doc = XML::LibXML->load_html(location => "test-$id/rss2sample.html");
is($doc->findvalue('//li/a[@class="message"]/@title'), "No feed updates in 90 days", "No feed updates in 90 days");

$atom = <<"EOT";
<?xml version="1.0" encoding='UTF-8'?>
<feed xmlns='http://www.w3.org/2005/Atom'>
<!-- no update given for the feed itself -->
<title type='text'>Textual</title>
<entry>
<updated>$old</updated>
<title type='text'>Current</title>
<summary type='text'>
Snail is best.
</summary>
</entry>
</feed>
EOT

start_daemon(encode_utf8 $atom);

Jupiter::update_cache("test-$id/rss2sample.opml");

stop_daemon();

Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml");

$doc = XML::LibXML->load_html(location => "test-$id/rss2sample.html");
is($doc->findvalue('//li/a[@class="message"]/@title'), "No entry newer than 90 days", "No entry newer than 90 days");

done_testing;
