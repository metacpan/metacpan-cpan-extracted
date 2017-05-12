#!/usr/bin/perl -w

# CGI script that simply displays the XML

use strict;
use CGI::XMLForm;

my $cgi = new CGI::XMLForm;

print $cgi->header;

# Output HTML Body
if ($cgi->param) {
	print $cgi->start_html('CGI::XMLForm'),
		$cgi->h1("Form gave us the following params:"),
		$cgi->hr;
	print $cgi->pre($cgi->escapeHTML(join "\n", split '&', $cgi->query_string));
	
	my $xml = $cgi->ToXML();

	print $cgi->hr;

	print $cgi->pre($cgi->escapeHTML($xml)), $cgi->br, $cgi->hr;

}
else {
	print $cgi->start_html('error'),
	$cgi->h1("Error: "),
	$cgi->h2("FATAL ERROR : Expecting parameters - please execute from correct source");
}
