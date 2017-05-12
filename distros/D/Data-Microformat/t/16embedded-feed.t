#!perl -w

use strict;
use Data::Microformat::hFeed;
use DateTime;
use Test::More tests => 18;

my $simple = << 'EOF';
<html>
<head>
	<title>A bogus title</title>
</head>
<body>
<div class='hfeed'>
	 <div class='feed-title'>A feed title</div>
     <div class='feed-tagline'>A test feed</div>
	 <div class='feed-description'>A description of a test feed</div>
	 <div class='hentry entry' id='tag__2008__2_actionstreams_819'>
		<h3 class='entry-title'><a href='http://example.com/989691066' rel='bookmark' title='A title'>A title</a></h3>
		<div class='entry-summary'>Brendan did something</div>
		<div class='entry-content'>
                Brendan waxed lyrical about cats &amp; puppies.
        </div>

		<ul class='post-info'>
			<li>Published: <a href='http://example.com/989691066' rel='bookmark' title='A title'><abbr class='published' title='2008-11-04T17:21:06'>November 11,08</abbr></a></li>
			<li>Modified: <a href='http://example.com/989691066' rel='bookmark' title='A title'><abbr class='modified' title='2008-11-04T17:21:07'>November 11,08</abbr></a></li>
            <li>Tags: <a href='http://example.com/tags/microformats' rel='tag'>microformats</a>, <a href='http://example.com/tags/perl' rel='tag'>perl</a></li>
		</ul>
	</div>
    <p>Updated: <abbr class='updated' title='2008-11-04T17:21:06'>November 11,08</abbr></p>
    <p>Categories: <a rel="tag directory">feed tag</a>, <a rel="tag directory">some category</a></p>
	<p>Written by: <address class='vcard author'><abbr class='fn nickname' title='Brendan O&#39;Connor'>Brendan O&#39;Connor</abbr></address></p>
    <p><a href="http://creativecommons.org/licenses/by/2.0/" rel="license">cc by 2.0</a></p>
</div>
</body>
</html>
EOF

ok(my $feed = Data::Microformat::hFeed->parse($simple),              "Parsed feed");
my $issued   = DateTime->new( year => 2008, month => 11, day => 4, hour => 17, minute => 21, second => 6);
my $modified = $issued->clone->add(seconds => 1);

is($feed->title,       "A feed title",                               "Got correct title");
is($feed->tagline,     "A test feed",                                "Got correct tag line");
is($feed->description, "A description of a test feed",               "Got correct tag line");
is("".$feed->modified, "".$issued,                                   "Got correct feed modification time");
is_deeply([$feed->categories], ['feed tag', 'some category'],        "Got feed categories");     
ok(my $c = $feed->copyright,                                         "Got feed copyright");
is($c->{text},        "cc by 2.0",                                   "Got correct copyright text");
is($c->{href},        "http://creativecommons.org/licenses/by/2.0/", "Got correct copyright href");
ok(my $author = $feed->author,                                       "Got author");
is($author->fn, "Brendan O'Connor",                                  "Got author fullname");


ok(my ($entry) = $feed->entries,                                     "Got entries");
is($entry->link,     "http://example.com/989691066",                 "Got correct link");
is($entry->summary,  "Brendan did something",                        "Got correct summary");
is($entry->content,  "Brendan waxed lyrical about cats & puppies.",  "Got correct content");
is("".$entry->issued,   "".$issued,                                  "Got correct issued");
is("".$entry->modified, "".$modified,                                "Got correct modified"); 
is_deeply([$entry->tags], [qw(microformats perl)],                   "Got correct tags");


