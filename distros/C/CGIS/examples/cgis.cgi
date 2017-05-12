#!/usr/bin/perl

use strict;
require CGIS;

my $cgi = new CGIS();
my $cmd = $cgi->param("_cmd") || 'default';

if ( $cmd eq 'end-session' ) {
  $cgi->session()->delete();
  print $cgi->redirect(-uri=>$ENV{HTTP_REFERER});
}

print $cgi->header(),
  $cgi->start_html("CGIS Test"),
  $cgi->h1("CGIS Test"), 
  $cgi->a({-href=>$cgi->urlf(_cmd=>'end-session')}, "end session"), 
  "&#xA0;|&#xA0;",
  $cgi->urlf(_cmd=>'end-session'), "<br /><br />";

printf("Your session id is %s<br />", $cgi->session_id);
printf("Current page's url is <b>%s</b><br />", $cgi->self_url);
print $cgi->end_html();


