# vi:fdm=marker fdl=0 syntax=perl:

use strict;
use Test;
use CGI::RSS;
use Date::Manip;

plan tests => 2;

my $rss = new CGI::RSS;

my $re1 = UnixDate( ParseDate("2008-03-22"), $CGI::RSS::pubDate_format );
ok( $rss->item(
        $rss->title       ( "test title"                ),
        $rss->link        ( "http://url/url/"           ),
        $rss->guid        ( "http://url/url/?permalink" ),
        $rss->description ( "roflmao roflmao"           ),
        $rss->date        ( "2008-03-22"                ),

    ), qr(\Q$re1\E) );

my $re2 = UnixDate( ParseDate("2008-03-22"), "%a %z" );
$rss->pubDate_format("%a %z");
ok( $rss->item(
        $rss->title       ( "test title"                ),
        $rss->link        ( "http://url/url/"           ),
        $rss->guid        ( "http://url/url/?permalink" ),
        $rss->description ( "roflmao roflmao"           ),
        $rss->date        ( "2008-03-22"                ),

    ), qr(\Q$re2\E) );
