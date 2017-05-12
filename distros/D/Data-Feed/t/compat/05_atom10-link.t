use strict;
use Data::Feed;

use Test::More;
plan tests => 4;

my $feed = Data::Feed->parse("t/data/atom-10-example.xml");
is $feed->title, 'Example Feed';
is $feed->link, 'http://example.org/', "link without rel";

my $e = ($feed->entries)[0];
ok $e->link, 'entry link without rel';
ok $e->links, 'all links from the entry';
