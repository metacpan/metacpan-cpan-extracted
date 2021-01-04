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

use DateTime;
my $now = DateTime->now;

my $atom = <<'EOT';
<?xml version='1.0' encoding='UTF-8'?>
<feed xmlns='http://www.w3.org/2005/Atom'>
<updated>$now</updated>
<title type='text'>Schröder’s Blog</title>
<author><name>Alex Schröder</name><email>noreply@blogger.com</email></author>
<entry>
<published>$now</published>
<updated>$now</updated>
<title type='text'>Fuß</title>
<content type='html'>Hello Schröder!</content>
</entry>
</feed>
EOT

start_daemon(encode_utf8 $atom);

Jupiter::update_cache("test-$id/rss2sample.opml");

stop_daemon();

Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml");

ok(-f "test-$id/rss2sample.html", "HTML was generated");
my $doc = XML::LibXML->load_html(location => "test-$id/rss2sample.html");
# no message means that this is just the list node text content
like($doc->findvalue('//li'), qr/Schröder’s Blog/, "Encoded feed title in the info list");
is($doc->findvalue('//h3/a[position()=1]'), "Schröder’s Blog", "Encoded feed title");
is($doc->findvalue('//h3/a[position()=2]'), "Fuß", "Encoded item title");
is($doc->findvalue('//div[@class="content"]'), "Hello Schröder!", "Encoded item content");

done_testing;
