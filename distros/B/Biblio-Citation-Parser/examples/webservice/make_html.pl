#!/usr/bin/perl -w
use SOAP::Lite;

# A more involved example - creates a chunk of HTML
# with links to the OpenURLs for each reference in
# referencelist.txt.

my $baseurl = "http://paracite.eprints.org/cgi-bin/openurl.cgi?";

my $service = SOAP::Lite
        -> service("http://paracite.eprints.org/paracite.wsdl");

open(FIN, "referencelist.txt");
print "<ul>\n";
foreach(<FIN>)
{
        chomp;
        $openurl = $service->doOpenURLConstruct($_, $baseurl);
        print '<li><a href="'.$openurl.'">'.$_.'</a></li>',"\n";
}
print "</ul>\n";
close FIN;
