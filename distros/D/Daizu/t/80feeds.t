#!/usr/bin/perl
use warnings;
use strict;

use Test::More;
use Path::Class qw( file );
use Daizu;
use Daizu::Test qw( init_tests );
use Daizu::Feed;
use Daizu::Util qw( validate_date rfc2822_datetime );

init_tests(137);

my $cms = Daizu->new($Daizu::Test::TEST_CONFIG);
my $wc = $cms->live_wc;

my $xml = make_test_feed($cms, 'atom', 'snippet');

# atom feed root
my $feed_elem = $xml->documentElement;
is($feed_elem->localname, 'feed', 'atom: <feed> root');
is($feed_elem->namespaceURI, 'http://www.w3.org/2005/Atom',
   'atom: <feed> namespace');

# atom feed <title>
my (@elem) = $feed_elem->getChildrenByTagName('title');
is(scalar @elem, 1, 'atom: one feed <title>');
is($elem[0]->textContent, 'Foo Blog', 'atom: right title');

# atom feed <id>
(@elem) = $feed_elem->getChildrenByTagName('id');
is(scalar @elem, 1, 'atom: one feed <id>');
is($elem[0]->textContent, guid_uri_for_path($wc, 'foo.com/blog'),
   'atom: feed <id> right');

# atom feed <generator>
(@elem) = $feed_elem->getChildrenByTagName('generator');
is(scalar @elem, 1, 'atom: one feed <generator>');
is($elem[0]->getAttribute('uri'), 'http://www.daizucms.org/',
   'atom: feed <generator> uri');
is($elem[0]->getAttribute('version'), $Daizu::VERSION,
   'atom: feed <generator> version');
is($elem[0]->textContent, 'Daizu CMS', 'atom: feed <generator> content');

# atom feed <link>s
(@elem) = $feed_elem->getChildrenByTagName('link');
is(scalar @elem, 2, 'atom: two feed <link>s');
is($elem[0]->getAttribute('href'), 'http://foo.com/blog/feed.atom',
   'atom: feed <link> self href');
is($elem[0]->getAttribute('rel'), 'self',
   'atom: feed <link> self rel');
is($elem[0]->getAttribute('type'), 'application/atom+xml',
   'atom: feed <link> self type');
is($elem[1]->getAttribute('href'), 'http://foo.com/blog/',
   'atom: feed <link> blog href');
is($elem[1]->getAttribute('rel'), undef,
   'atom: feed <link> blog rel');
is($elem[1]->getAttribute('type'), 'text/html',
   'atom: feed <link> blog type');

# atom feed <updated>
(@elem) = $feed_elem->getChildrenByTagName('updated');
is(scalar @elem, 1, 'atom: one feed <updated>');
like($elem[0]->textContent, qr/\A\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/,
     'atom: feed <updated> is W3C datetime');

# atom entries
(@elem) = $feed_elem->getChildrenByTagName('entry');
is(scalar @elem, 3, 'atom: right number of feed <entry>');

my $entry_n = 1;
for my $entry_elem (@elem) {
    my @elem;

    my ($path, $exp_title, $exp_pubdate, $exp_url) =
        expected_article_values($entry_n);

    # atom entry <published>
    (@elem) = $entry_elem->getChildrenByTagName('published');
    is(scalar @elem, 1, 'atom: one entry <published>');
    is($elem[0]->textContent, $exp_pubdate,
       'atom: entry <published> is right datetime');

    # atom entry <updated>
    (@elem) = $entry_elem->getChildrenByTagName('updated');
    is(scalar @elem, 1, 'atom: one entry <updated>');
    like($elem[0]->textContent, qr/\A\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/,
         'atom: entry <updated> is W3C datetime');

    # atom entry <id>
    (@elem) = $entry_elem->getChildrenByTagName('id');
    is(scalar @elem, 1, 'atom: one entry <id>');
    is($elem[0]->textContent, guid_uri_for_path($wc, $path),
       'atom: entry <id> right');

    # atom entry <link>
    (@elem) = $entry_elem->getChildrenByTagName('link');
    is(scalar @elem, 1, 'atom: one entry <link>');
    is($elem[0]->getAttribute('href'), $exp_url, 'atom: entry <link> href');
    is($elem[0]->getAttribute('rel'), 'alternate', 'atom: entry <link> rel');
    is($elem[0]->getAttribute('type'), 'text/html', 'atom: entry <link> type');

    # atom entry <title>
    (@elem) = $entry_elem->getChildrenByTagName('title');
    is(scalar @elem, 1, 'atom: one entry <title>');
    is($elem[0]->textContent, $exp_title, 'atom: entry <title> right');

    # atom entry <content>
    (@elem) = $entry_elem->getChildrenByTagName('content');
    is(scalar @elem, 1, 'atom: one entry <content>');
    is($elem[0]->getAttributeNS('http://www.w3.org/XML/1998/namespace', 'base'),
       $exp_url, 'atom: entry <content> xml:base');
    my $content_elem = $elem[0];
    is($content_elem->getAttribute('type'), 'xhtml',
       'atom: entry <content> type');
    (@elem) = $content_elem->getChildrenByTagName('div');
    is(scalar @elem, 1, 'atom: one entry <content><div>');
    is($elem[0]->namespaceURI, 'http://www.w3.org/1999/xhtml',
       'atom: entry <content><div> in XHTML namespace');

    # Article 5 has a syntax highlighted bit in, but for the feed
    # content the <span> elements and 'class' attribute should be
    # removed, so as not to confuse aggregators.
    if ($exp_title eq 'Article 5') {
        (@elem) = $content_elem->getElementsByTagName('span');
        is(scalar @elem, 0, 'atom: entry <content> has no <span> elements');
        (@elem) = $content_elem->getElementsByTagName('pre');
        SKIP: {
            is(scalar @elem, 1, 'atom: entry <content> has a <pre> element');
            skip '<pre> element missing', 1 unless @elem;
            ok(!$elem[0]->hasAttribute('class'), 'atom: <pre> has no class');
        }
    }

    ++$entry_n;
}


$xml = make_test_feed($cms, 'rss2', 'content');

# rss2 feed root
$feed_elem = $xml->documentElement;
is($feed_elem->localname, 'rss', 'rss2: <rss> root');
(@elem) = $feed_elem->getChildrenByTagName('channel');
is(scalar @elem, 1, 'rss2: one feed <channel>');
my $chan_elem = $elem[0];

# rss2 feed <title>
(@elem) = $chan_elem->getChildrenByTagName('title');
is(scalar @elem, 1, 'rss2: one feed <title>');
is($elem[0]->textContent, 'Foo Blog', 'rss2: right title');

# rss2 feed <description> - must exist even if it's empty
(@elem) = $chan_elem->getChildrenByTagName('description');
is(scalar @elem, 1, 'rss2: one feed <description>');

# rss2 feed <link>
(@elem) = $chan_elem->getChildrenByTagName('link');
is(scalar @elem, 1, 'rss2: one feed <link>');
is($elem[0]->textContent, 'http://foo.com/blog/', 'rss2: feed <link> right');

# rss2 feed <generator>
(@elem) = $chan_elem->getChildrenByTagName('generator');
is(scalar @elem, 1, 'rss2: one feed <generator>');
is($elem[0]->textContent, "http://www.daizucms.org/?v=$Daizu::VERSION",
   'rss2: feed <generator> content');

# rss2 feed <atom:link> to self
(@elem) = $chan_elem->getChildrenByTagName('atom:link');
is(scalar @elem, 1, 'rss2: one feed <atom:link>');
is($elem[0]->getAttribute('href'), 'http://foo.com/blog/feed.rss',
   'rss2: feed <link> self href');
is($elem[0]->getAttribute('rel'), 'self',
   'rss2: feed <link> self rel');
is($elem[0]->getAttribute('type'), 'application/rss+xml',
   'rss2: feed <link> self type');

# rss2 feed <lastBuildDate>
(@elem) = $chan_elem->getChildrenByTagName('lastBuildDate');
is(scalar @elem, 1, 'rss2: one feed <lastBuildDate>');
my $VALID_RFC_822_DATE = qr{
    \A
    (?:Sun|Mon|Tue|Wed|Thu|Fri|Sat), \x20
    \d\d \x20
    (?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \x20
    \d\d\d\d \x20
    \d\d:\d\d:\d\d \x20
    \+0000
    \z
}x;
like($elem[0]->textContent, qr/$VALID_RFC_822_DATE/,
     'rss2: feed <lastBuildDate> is RFC 822 datetime');

# rss2 entries
(@elem) = $chan_elem->getChildrenByTagName('item');
is(scalar @elem, 3, 'rss2: right number of feed <item>');

$entry_n = 1;
for my $entry_elem (@elem) {
    my @elem;

    my ($path, $exp_title, $exp_pubdate, $exp_url) =
        expected_article_values($entry_n);

    # rss2 entry <pubDate>
    (@elem) = $entry_elem->getChildrenByTagName('pubDate');
    is(scalar @elem, 1, 'rss2: one entry <pubDate>');
    like($elem[0]->textContent, qr/$VALID_RFC_822_DATE/,
         'rss2: entry <pubDate> is valid RFC 822 datetime');
    is($elem[0]->textContent, rfc2822_datetime(validate_date($exp_pubdate)),
       'rss2: entry <pubDate> is right datetime');

    # rss2 entry <guid>
    (@elem) = $entry_elem->getChildrenByTagName('guid');
    is(scalar @elem, 1, 'rss2: one entry <guid>');
    is($elem[0]->getAttribute('isPermaLink'), 'false',
       'rss2: entry <guid> not permalink');
    is($elem[0]->textContent, guid_uri_for_path($wc, $path),
       'rss2: entry <guid> right');

    # rss2 entry <link>
    (@elem) = $entry_elem->getChildrenByTagName('link');
    is(scalar @elem, 1, 'rss2: one entry <link>');
    is($elem[0]->textContent, $exp_url, 'rss2: entry <link> URL');

    # rss2 entry <title>
    (@elem) = $entry_elem->getChildrenByTagName('title');
    is(scalar @elem, 1, 'rss2: one entry <title>');
    is($elem[0]->textContent, $exp_title, 'rss2: entry <title> right');

    # rss2 entry <description>
    (@elem) = $entry_elem->getChildrenByTagName('description');
    is(scalar @elem, 1, 'rss2: one entry <description>');
    unlike($elem[0]->textContent, qr/<p/,
           'rss2: entry <description> contains no markup');

    # rss2 entry <content:encoded>
    (@elem) = $entry_elem->getChildrenByTagName('content:encoded');
    is(scalar @elem, 1, 'rss2: one entry <content:encoded>');
    like($elem[0]->textContent, qr/<p/,
         'rss2: entry <content:encoded> contains markup');
    my $content_elem = $elem[0];

    # Article 5 has a syntax highlighted bit in, but for the feed
    # content the <span> elements and 'class' attribute should be
    # removed, so as not to confuse aggregators.
    if ($exp_title eq 'Article 5') {
        like($content_elem->textContent, qr/<pre>#!/,
             'rss2: entry content has no spans or classes');
    }

    ++$entry_n;
}


sub guid_uri_for_path
{
    my ($wc, $path) = @_;
    my ($guid_uri) = $wc->{cms}->db->selectrow_array(q{
        select g.uri
        from file_guid g
        inner join wc_file f on f.guid_id = g.id
        where f.wc_id = ?
          and f.path = ?
    }, undef, $wc->id, $path);
    die "can't find GUID URI for path '$path'" unless defined $guid_uri;
    return $guid_uri;
}

sub make_test_feed
{
    my ($cms, $format, $type) = @_;
    my $wc = $cms->live_wc;
    my $extention = $format;
    $extention =~ s/rss2$/rss/;
    my $feed = Daizu::Feed->new($cms, $wc->file_at_path('foo.com/blog'),
                                "http://foo.com/blog/feed.$extention",
                                $format, $type);
    $feed->add_entry($wc->file_at_path($_))
        for 'foo.com/blog/2006/fish-fingers/article-1.html',
            'foo.com/blog/2006/fish-fingers/article-2.html',
            'foo.com/blog/2006/strawberries/article-5/_index.html';
            #'foo.com/blog/2005/photos/wasp-on-holly-leaf.jpg';
    isa_ok($feed, 'Daizu::Feed', "new feed: format=$format, type=$type");
    my $xml = $feed->xml;
    isa_ok($xml, 'XML::LibXML::Document', '$feed->xml');
    return $xml;
}

sub expected_article_values
{
    my ($entry_n) = @_;

    if ($entry_n == 1) {
        return ('foo.com/blog/2006/fish-fingers/article-1.html',
                'Article 1',
                '2006-03-12T08:32:45Z',
                'http://foo.com/blog/2006/03/article-1/');
    }
    elsif ($entry_n == 2) {
        return ('foo.com/blog/2006/fish-fingers/article-2.html',
                'Article 2',
                '2006-03-15T18:55:01Z',
                'http://foo.com/blog/2006/03/article-2/');
    }
    elsif ($entry_n == 3) {
        return ('foo.com/blog/2006/strawberries/article-5/_index.html',
                'Article 5',
                '2006-06-01T23:00:43Z',
                'http://foo.com/blog/2006/06/article-5/');
    }
    else {
        die;
    }
}

# vi:ts=4 sw=4 expandtab filetype=perl
