#!/usr/bin/perl -w

use SOAP::Lite;
my $query="Jewell, M (2002) Making Examples for Reference Parsers. Journal of Example Writing 3:100-150.";

my $result = SOAP::Lite 
	-> service("http://paracite.eprints.org/paracite.wsdl")
	-> doOpenURLConstruct($query, "http://paracite.eprints.org/cgi-bin/openurl.cgi?");
print "OpenURL for $query: $result\n";
