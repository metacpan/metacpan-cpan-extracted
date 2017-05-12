# vi:fdm=marker fdl=0 syntax=perl:

use strict;
use Test;
use CGI::RSS;

plan tests => 1;

my $rss = new CGI::RSS;

if( eval "use WWW::Mechanize; 1;" ) {
    my $xml = $rss->header;
       $xml =~ s/^.+$//m; # the first line is the content type (for apache)
       $xml =~ s/^[\x0d\x0a]+//; # then some blank lines

    $xml .= $rss->begin_rss(title=>"My Feed!", link=>"http://localhost/directory", desc=>"blargorious comments!");
    $xml .= $rss->item(
        $rss->title       ( "test title"                ),
        $rss->link        ( "http://url/url/"           ),
        $rss->guid        ( "http://url/url/?permalink" ),
        $rss->description ( "roflmao roflmao"           ),
        $rss->date        ( scalar localtime            ),
    );

   $xml .= $rss->finish_rss;

   open my $xmlfh, ">w3-validator-input.xml" or die $!;
   print $xmlfh $xml;
   close $xmlfh;

   if( not -f "w3.ok" ) {
        skip(1,1);

   } else {
       print STDERR "[submitting sample rss to w3]\n";

       my $mech = new WWW::Mechanize;
          $mech->get("http://validator.w3.org/feed/#validate_by_input");
          $mech->submit_form(
              form_number => 2,
              fields => { rawdata => $xml },
          );

       open my $w3, ">w3-validator-result.html" or die $!;
       print $w3 $mech->content;
       close $w3;

       ok( $mech->content =~ m/This is a valid RSS feed\./ );
   }

} else {
    skip(1,1);
}
