# Copyright (C) 2021  Alex Schroeder <alex@gnu.org>

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
<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns='http://www.w3.org/2005/Atom'>
<updated>2021-12-20T10:04:41.088-07:00</updated>
<title>Simulacrum</title>
<entry>
<published>3000-12-16T16:17:00.130-07:00</published>
<updated>3000-12-19T23:50:29.172-07:00</updated>
<title>From the far future</title>
<author><name>Keith</name></author>
</entry>
<entry>
<published>2021-12-16T16:17:00.130-07:00</published>
<updated>2021-12-19T23:50:29.172-07:00</updated>
<title>Part V</title>
<author><name>Keith</name></author>
</entry>
<entry>
<published>2021-03-15T21:08:00.118-06:00</published>
<updated>2021-12-19T10:56:43.136-07:00</updated>
<title>Part IV</title>
<author><name>Keith</name></author>
</entry>
<entry>
<published>2021-02-27T01:40:00.043-07:00</published>
<updated>2021-07-09T21:51:10.001-06:00</updated>
<title>Part III</title>
<author><name>Keith</name></author>
</entry>
<entry>
<published>2021-02-13T02:09:00.042-07:00</published>
<updated>2021-12-19T01:29:30.953-07:00</updated>
<title>Part II</title>
<author><name>Keith</name></author>
</entry>
<entry>
<published>2021-02-05T14:09:00.104-07:00</published>
<updated>2021-06-24T19:26:08.179-06:00</updated>
<title>Part I</title>
<author><name>Keith</name></author>
</entry>
</feed>
EOT

start_daemon(encode_utf8 $rss);

Jupiter::update_cache("test-$id/rss2sample.opml");

stop_daemon();

Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml");

ok(-f "test-$id/rss2sample.html", "HTML was generated");
my $doc = XML::LibXML->load_html(location => "test-$id/rss2sample.html");

# The published date takes precedence! All the other posts are too old.
# The post from the far future is ignored.
is($doc->findvalue('//div[@class="post"][position()=1]/div/a/span'), "2021-12-16", "date");
is($doc->findvalue('//div[@class="post"][position()=1]/h3'), "Simulacrum — Part V", "title");

done_testing;
