use Test::More tests => 4;

use strict;
use warnings;

use_ok( 'XML::Atom::Feed::JavaScript' );

my $feed = XML::Atom::Feed::JavaScript->new(Stream => 't/feed.xml');

my $expected = <<'JAVASCRIPT_TEXT';
document.write('<div class=\"atom_feed\">');
document.write('<div class=\"atom_feed_title\">dive into atom</div>');
document.write('<ul class=\"atom_item_list\">');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002447.html\">Test</a></span><span class=\"atom_item_desc\"><p>Python is cool stuff for ReSTy webapps.</p></span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002444.html\">Created using the Fix Auth</a></span><span class=\"atom_item_desc\">      Stuff.          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002441.html\">just a test - updated</a></span><span class=\"atom_item_desc\">      nothing to see here, move along          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002440.html\">Second attempt.</a></span><span class=\"atom_item_desc\">      <P><STRONG>Updating </STRONG>now works too.</P><P>How about a new paragraph?</P>          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002439.html\">First post.</a></span><span class=\"atom_item_desc\">      Testing a <EM>javascript</EM> client. Test. Again. and again.          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002437.html\">Can anyone post?</a></span><span class=\"atom_item_desc\">      Is it OK for other people to post to this test implementation?<br /> <strong>It works!</strong>  Yes! for now          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002431.html\">Unit Test 1</a></span><span class=\"atom_item_desc\">      When you do unit testing.          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002430.html\">Unit Test 1</a></span><span class=\"atom_item_desc\">      When you do unit testing.          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002427.html\">Unit Test 1</a></span><span class=\"atom_item_desc\">      When you do unit testing.          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002426.html\">Unit Test 1</a></span><span class=\"atom_item_desc\">      When you do unit testing.          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002425.html\">Unit Test 1</a></span><span class=\"atom_item_desc\">      When you do unit testing.          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002424.html\">Unit Test 1</a></span><span class=\"atom_item_desc\">      When you do unit testing.          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002423.html\">Unit Test 1</a></span><span class=\"atom_item_desc\">      When you do unit testing.          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002421.html\">Unit Test 1</a></span><span class=\"atom_item_desc\">      When you do unit testing.          </span></li>');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002420.html\">Unit Test 1</a></span><span class=\"atom_item_desc\">      When you do unit testing.          </span></li>');
document.write('</ul>');
document.write('</div>');
JAVASCRIPT_TEXT

my $expected_max = <<'JAVASCRIPT_TEXT';
document.write('<div class=\"atom_feed\">');
document.write('<div class=\"atom_feed_title\">dive into atom</div>');
document.write('<ul class=\"atom_item_list\">');
document.write('<li class=\"atom_item\"><span class=\"atom_item_title\"><a class=\"atom_item_link\" href=\"http://diveintomark.org/atom/archives/002447.html\">Test</a></span><span class=\"atom_item_desc\"><p>Python is cool stuff for ReSTy webapps.</p></span></li>');
document.write('</ul>');
document.write('</div>');
JAVASCRIPT_TEXT

is( $feed->asJavascript(), $expected, 'asJavascript' );
is( $feed->asJavascript( 1 ), $expected_max, 'asJavascript( max )' );
is( $feed->asJavascript( 20 ), $expected, 'asJavascript( max too big )' );