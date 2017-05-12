#!/usr/bin/perl -w
use SOAP::Lite;
my $query = "Harnad, Stevan (1995) The PostGutenberg Galaxy: How to Get There From Here. Information Society 11(4):285-292.";
my $baseurl = "http://paracite.eprints.org/cgi-bin/openurl.cgi?";

my $result = SOAP::Lite
        -> service("http://paracite.eprints.org/paracite.wsdl")
        -> doParaciteSearch($query, $baseurl);

print "Results of search on $query:\n";
use Data::Dumper; print Dumper($result);
