#!/usr/bin/perl
# $Id: shorten.pl,v 1.1 2003/09/10 07:28:54 cvspub Exp $
use CGI qw/:standard/;
use CGI::Shorten;

$script_url = 'http://'.$ENV{HTTP_HOST}.'/redirect.pl';
$sh = new CGI::Shorten(
		       db_prefix => ".shorten_",
		       script_url => $script_url,
		       );


print header,
    start_html('CGI::Shorten'),
    h1('CGI::Shorten'),
    start_form,
    "URL to shorten: ",textfield('_url'),p,
    submit,
    end_form,
    hr;

if (param()) {
    $shurl = $sh->shorten(param("_url"));
    print
	"Your shortened link for ".b(param("_url"))." is:", br,
	a({href=> $shurl}, $shurl);
}
undef $sh;
print end_html;
