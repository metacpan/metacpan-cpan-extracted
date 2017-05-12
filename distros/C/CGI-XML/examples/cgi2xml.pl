#!/usr/bin/perl -w
use strict;
use CGI::XML;
my $q = new CGI::XML;

# save CGI variables to XML file
my $xml = $q->toXML("cgi");
print $xml;
