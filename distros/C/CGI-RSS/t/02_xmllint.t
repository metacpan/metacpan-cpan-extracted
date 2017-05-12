# vi:fdm=marker fdl=0 syntax=perl:

use strict;
use Test;
use CGI::RSS;

plan tests => 1;

my $rss = new CGI::RSS;

my @path = split ":", $ENV{PATH};
my $lint;
for my $p (map {"$_/xmllint"} @path) {
    if( -x $p ) {
        $lint = $p;
        last;
    }
}

if( $lint ) {
    open my $out, ">test.xml" or die $!;

    print STDERR "[checking xml with xmllint]\n";

  # print
    $rss->header;
    print $out $rss->begin_rss(title=>"My Feed!", link=>"http://localhost/directory", desc=>"blargorious comment!");

        print $out $rss->item(
            $rss->title       ( "test title"                ),
            $rss->link        ( "http://url/url/"           ),
            $rss->guid        ( "http://url/url/?permalink" ),
            $rss->description ( "roflmao roflmao"           ),
            $rss->date        ( "2008-03-22"                ),
        );

    print $out $rss->finish_rss;

    ok(system(qw(xmllint --noout test.xml)), 0);

} else {
    skip(1,1);
}
