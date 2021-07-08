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
use File::Slurper qw(write_binary read_binary write_text);

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

# with a filter that doesn't match
Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml", "/nothing/");

ok(-f "test-$id/rss2sample.html", "HTML was generated");
my $html = read_binary "test-$id/rss2sample.html";
unlike($html, qr/syntax error at template/, "No syntax errors in the HTML");
my $doc = XML::LibXML->load_html(string => $html);
like($doc->findvalue('//div[@id="body"]'), qr/^\s*$/, "Empty body");

# with a filter that matches
Jupiter::make_html("test-$id/rss2sample.html", "test-$id/rss2sample.xml", "test-$id/rss2sample.opml", "/127/");

$html = read_binary "test-$id/rss2sample.html";
$doc = XML::LibXML->load_html(string => $html);
like($doc->findvalue('//div[@id="body"]'), qr/Star City/, "Body contains entries from the feed");

done_testing;
