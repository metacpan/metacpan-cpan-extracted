use App::BookmarkFeed;
use Test::More;
use XML::RSS;
use utf8;

unlink('t/feed.rss');
unlink('t/feed.db');

# No arguments is wrong.
eval { App::BookmarkFeed::main() };
like($@, qr/^Usage:/);

# One argument is still wrong.
eval { App::BookmarkFeed::main('t/feed.rss') };
like($@, qr/^Usage:/);

# Two arguments is fine.
App::BookmarkFeed::main('t/2016-11-14_Trump.md', 't/feed.rss');

ok(-f "t/feed.rss", "Feed was written");

my $rss = XML::RSS->new;
$rss->parsefile("t/feed.rss");

is($rss->channel("title"), "Bookmarks");
is(scalar(@{$rss->{"items"}}), 37);

is($rss->channel("title"), "Bookmarks");

# first
my $item = shift(@{$rss->{"items"}});
is($item->{link},
   "https://www.vox.com/policy-and-politics/2017/11/2/16588964/america-epistemic-crisis");
is($item->{title},
   "America is facing an epistemic crisis");
is($item->{description},
   "<p><a href=\"https://www.vox.com/policy-and-politics/2017/11/2/16588964/america-epistemic-crisis\">America is facing an epistemic crisis</a>: “an increasingly large chunk of Americans believes a whole bunch of crazy things, and it is warping our politics. […] what if Mueller proves the case and it’s not enough? What if there is no longer any evidentiary standard that could overcome the influence of right-wing media?”</p>\n");

# last
$item = pop(@{$rss->{"items"}});
is($item->{link},
   "https://www.scientificamerican.com/article/the-supreme-courts-contempt-for-facts-is-a-betrayal-of-justice/");
is($item->{title},
   "The Supreme Court’s Contempt for Facts Is a Betrayal of Justice");
like($item->{description},
   qr/<p>In the last four years, a reliably Republican majority on the high court.*/);

# multiple links means multiple identical descriptions, not sure if that's cool
@items = grep { $_->{description} =~ /^<p>In the last four years/ } @{$rss->{"items"}};
is(scalar(@items), 10);

done_testing();
