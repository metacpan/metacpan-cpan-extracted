# Copyright (C) 2020–2021  Alex Schroeder <alex@gnu.org>

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

do './t/test.pl';
my ($id, $port) = init();
save_opml('rss2sample.opml');

my $atom = <<'EOT';
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title type="text">dive into mark</title>
  <subtitle type="html">
    A &lt;em&gt;lot&lt;/em&gt; of effort
    went into making this effortless
  </subtitle>
  <updated>2005-07-31T12:29:29Z</updated>
  <id>tag:example.org,2003:3</id>
  <link rel="alternate" type="text/html"
   hreflang="en" href="http://example.org/"/>
  <link rel="self" type="application/atom+xml"
   href="http://example.org/feed.atom"/>
  <rights>Copyright (c) 2003, Mark Pilgrim</rights>
  <generator uri="http://www.example.com/" version="1.0">
    Example Toolkit
  </generator>
  <entry>
    <title>Atom draft-07 snapshot</title>
    <link rel="alternate" type="text/html"
     href="http://example.org/2005/04/02/atom"/>
    <link rel="enclosure" type="audio/mpeg" length="1337"
     href="http://example.org/audio/ph34r_my_podcast.mp3"/>
    <id>tag:example.org,2003:3.2397</id>
    <updated>2005-07-31T12:29:29Z</updated>
    <published>2003-12-13T08:29:29-04:00</published>
    <author>
      <name>Mark Pilgrim</name>
      <uri>http://example.org/</uri>
      <email>f8dy@example.com</email>
    </author>
    <contributor>
      <name>Sam Ruby</name>
    </contributor>
    <contributor>
      <name>Joe Gregorio</name>
    </contributor>
    <content type="xhtml" xml:lang="en"
     xml:base="http://diveintomark.org/">
      <div xmlns="http://www.w3.org/1999/xhtml">
	<p><i>[Update: The Atom draft is finished.]</i></p>
      </div>
    </content>
  </entry>
  <entry>
    <title>HTML Example</title>
    <link rel="alternate" type="text/html"
     href="http://example.org/test.html"/>
    <content type="html">&lt;p&gt;&lt;i&gt;Yeah!&lt;/i&gt;&lt;/p&gt;</content>
  </entry>
</feed>
EOT

start_daemon(encode_utf8 $atom);

Jupiter::update_cache("test-$id/rss2sample.opml");

stop_daemon();

Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml");

my $doc = XML::LibXML->load_html(location => "test-$id/rss2sample.html");
is($doc->findvalue('//h1'), "Planet", "HTML title");
is($doc->findvalue('//div[@class="post"][position()=1]/h3'), "dive into mark — Atom draft-07 snapshot", "Entry title");
is($doc->findvalue('//div[@class="post"][position()=1]/div[@class="content"]'), "[Update: The Atom draft is finished.]", "Entry content");

$doc = XML::LibXML->load_xml(location => "test-$id/rss2sample.xml");
is($doc->findvalue('//item[position()=1]/title'), "Atom draft-07 snapshot", "XHTML Item title");
my @nodes = $doc->findnodes('//item[position()=1]/description');
my $node = shift(@nodes);
like($node->toString, qr(&lt;p&gt;&lt;i&gt;\[Update: The Atom draft is finished\.\]&lt;/i&gt;&lt;/p&gt;),
     "XHTML Item description");

is($doc->findvalue('//item[position()=2]/title'), "HTML Example", "HTML Item title");
@nodes = $doc->findnodes('//item[position()=2]/description');
$node = shift(@nodes);
like($node->toString, qr(&lt;p&gt;&lt;i&gt;Yeah!&lt;/i&gt;&lt;/p&gt;),
     "HTML Item description");

done_testing();
