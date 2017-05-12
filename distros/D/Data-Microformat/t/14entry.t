#!perl -w

use strict;
use Data::Microformat::hFeed::hEntry;
use DateTime;
use Test::More tests => 11;

my $simple = << 'EOF';
	 <div class='hentry entry' id='tag__2008__2_actionstreams_819'>
		<h3 class='entry-title'><a href='http://example.com/989691066' rel='bookmark' title='A title'>A title</a></h3>
		<div class='entry-summary'><p>Brendan <a href="foo">did</a> something</p></div>
		<div class='entry-content'>
                Brendan waxed lyrical about cats &amp; puppies.
        </div>

		<ul class='post-info'>
			<li>Published: <a href='http://example.com/989691066' rel='bookmark' title='A title'><abbr class='published' title='2008-11-04T17:21:06'>November 11,08</abbr></a></li>
			<li>Modified: <a href='http://example.com/989691066' rel='bookmark' title='A title'><abbr class='modified' title='2008-11-04T17:21:07'>November 11,08</abbr></a></li>
			<li>Written by: <address class='vcard author'><abbr class='fn nickname' title='Brendan O&#39;Connor'>Brendan O&#39;Connor</abbr></address></li>
            <li>Tags: <a href='http://example.com/tags/microformats' rel='tag'>microformats</a>, <a href='http://example.com/tags/perl' rel='tag'>perl</a></li>
		</ul>
</div>
EOF

ok(my $entry = Data::Microformat::hFeed::hEntry->parse($simple));
my $issued   = DateTime->new( year => 2008, month => 11, day => 4, hour => 17, minute => 21, second => 6);
my $modified = $issued->clone->add( seconds => 1); 

is($entry->id,       "tag__2008__2_actionstreams_819",                 "Got correct id");
is($entry->title,    "A title",                                        "Got correct title");
is($entry->link,     "http://example.com/989691066",                   "Got correct link");
is($entry->summary,  '<p>Brendan <a href="foo">did</a> something</p>', "Got correct summary");
is($entry->content,  "Brendan waxed lyrical about cats & puppies.",    "Got correct content");
is("".$entry->issued,   "".$issued,                                    "Got correct issued");
is("".$entry->modified, "".$modified,                                  "Got correct modified"); 
is_deeply([$entry->tags], [qw(microformats perl)],                     "Got correct tags");

ok(my $author = $entry->author,                                        "Got author");
is($author->fn, "Brendan O'Connor",                                    "Got author fullname");      

