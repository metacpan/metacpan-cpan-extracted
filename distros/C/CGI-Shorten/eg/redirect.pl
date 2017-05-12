#!/usr/bin/perl
# $Id: redirect.pl,v 1.2 2003/09/10 07:31:45 cvspub Exp $

use CGI::Shorten;
$this_script = 'http://'.$ENV{HTTP_HOST}.'/redirect.pl';
$sh = new CGI::Shorten(
		       db_prefix => ".shorten_",
		       script_url => $this_script,
		       );

use CGI qw/:standard/;

$query = $ENV{QUERY_STRING};
if($query =~ /[a-z]/o){
    $url = $this_script.'?'.$query;
    print $sh->redirect($url);
}
undef $sh;
