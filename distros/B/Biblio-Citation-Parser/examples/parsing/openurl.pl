#!/usr/bin/perl

# This example creates an OpenURL address from a parsed reference.

use Biblio::Citation::Parser::Standard;
use Biblio::Citation::Parser::Utils;
use URI::OpenURL;

$ref = "Jewell, M (2002) Making Examples for Reference Parsers. Journal of Example Writing 3:100-150.";

print "- Parsing $ref\n";
my $cit_parser = new Biblio::Citation::Parser::Standard;
$metadata = $cit_parser->parse($ref);
print "- Creating OpenURL (BaseURL set to http://paracite.eprints.org/cgi-bin/openurl.cgi)\n";
print URI::OpenURL->new('http://paracite.eprints.org/cgi-bin/openurl.cgi')->referent(%$metadata)->as_string();
my($openurl,@errors) = create_openurl($metadata);
print "http://paracite.eprints.org/cgi-bin/openurl.cgi?".$openurl."\n";
