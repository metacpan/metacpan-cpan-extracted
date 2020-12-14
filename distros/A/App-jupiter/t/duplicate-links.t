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
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/css" href="https://idiomdrottning.org/feed.css"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Idiomdrottning</title>
  <subtitle type="xhtml">
    <div xmlns="http://www.w3.org/1999/xhtml">
      <ol><li><a href="/blog">/blog</a></li>
      <li><a href="/blog/en">/blog/en</a></li>
      <li><a href="/blog/rpg/">/blog/rpg/</a></li>
      <li>/blog/rpg/en/en</li>
</ol>
    </div>
  </subtitle>
  <link rel="self" href="https://idiomdrottning.org/blog/rpg/en/feed.xml"/>
  <updated>2020-09-29T01:07:03+02:00</updated>
  <id>https://idiomdrottning.org/blog/rpg/en/feed.xml</id>
  <entry>
    <link rel="self" href="https://idiomdrottning.org/converting-to-dnd/"/>
    <id>https://idiomdrottning.org/converting-to-dnd/</id>
    <title type="xhtml"><div xmlns="http://www.w3.org/1999/xhtml">Converting to D&amp;D</div></title>
    <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">
        stuff
      </div>
    </content>
    <updated>2020-09-29T00:18:12+02:00</updated>
    <link href="https://idiomdrottning.org/converting-to-dnd/"/>
    <author>
      <name>Idiomdrottning</name>
      <email>sandra.snan@idiomdrottning.org</email>
    </author>
    </entry>
</feed>
EOT

start_daemon(encode_utf8 $rss);

Jupiter::update_cache("test-$id/rss2sample.opml");

stop_daemon();

Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml");

ok(-f "test-$id/rss2sample.html", "HTML was generated");
my $doc = XML::LibXML->load_html(location => "test-$id/rss2sample.html");
is($doc->findvalue('//div[@class="post"]/h3[position()=1]/a[position()=2]/@href'),
   "https://idiomdrottning.org/converting-to-dnd/",
   "Link deduplicated");

done_testing;
