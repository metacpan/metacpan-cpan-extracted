use App::BookmarkFeed;
use Test::More;
use XML::RSS;
use utf8;

unlink('t/colon.rss');
unlink('t/colon.db');

App::BookmarkFeed::main('t/colon.md', 't/colon.rss');

my $rss = XML::RSS->new;
$rss->parsefile("t/colon.rss");

is(scalar(@{$rss->{"items"}}), 1);

# first
my $item = shift(@{$rss->{"items"}});
is($item->{link},
   "http://example.org/bookmark");
is($item->{title},
   "bm");
is($item->{description},
   "<p>This is a bookmark. – <a href=\"http://example.org/bookmark\">bm</a></p>\n");

done_testing();
