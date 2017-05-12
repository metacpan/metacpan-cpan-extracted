#!/usr/bin/perl -w
use SOAP::Lite;
use Data::Dumper;
my $query = "Jewell, M (2002) Making Examples for Reference Parsers. Journal of Example Writing 3:100-150.";
my $baseurl = "http://paracite.eprints.org/cgi-bin/openurl.cgi?";

my $result = SOAP::Lite
        -> service("http://paracite.eprints.org/paracite.wsdl")
        -> doReferenceParse($query, $baseurl);
my $metadata = $result->{metadata};
my $openurl = $result->{openURL};
print "Metadata for $query:\n";
print Dumper($metadata);
print "OpenURL:\n";
print Dumper($openurl);
