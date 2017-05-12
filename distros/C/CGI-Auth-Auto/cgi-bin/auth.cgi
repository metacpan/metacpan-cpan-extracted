#!/usr/bin/perl -w
# this file is part of CGI::Auth::Auto, look up on cpan for more info
# when you're done with getting this to work, i suggest you get rid of the begin block.
BEGIN { use CGI::Carp qw(fatalsToBrowser); eval qq|use lib '$ENV{DOCUMENT_ROOT}/../lib';|; } # or wherever your lib is 
use strict;
use CGI::Auth::Auto;
use CGI qw(:all);

my $auth = new CGI::Auth::Auto; 

# if you want to use the template included in the distro, 
# put it in cgi-bin/auth/login.html
# as long as this script resides in cgi-bin/, it will be found and used

$auth->check;


my $html = 
   header().
   start_html().
   h1("hello ".$auth->username).
   p('You are logged in now.').
   p('<a href="?logout">logout?</a>');	

print $html;
exit;

