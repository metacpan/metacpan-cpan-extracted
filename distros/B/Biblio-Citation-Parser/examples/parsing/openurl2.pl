#!/usr/bin/perl

# This (slightly more involved) example parses a reference,
# decomposes it (to get spage, epage, etc), trims it to remove
# any non-OpenURL fields, and then dumps the metadata.

use Biblio::Citation::Parser::Standard;
use Biblio::Citation::Parser::Utils;
use Data::Dumper;

$ref = "Jewell, M (2002) Making Examples for Reference Parsers. Journal of Example Writing 3:100-150.";

my $cit_parser = new Biblio::Citation::Parser::Standard;
print "- Parsing $ref\n";
$metadata = $cit_parser->parse($ref);
print "- Decomposing and trimming metadata\n";
$metadata = trim_openurl(decompose_openurl($metadata));
print "- Metadata dump follows:\n";
print Dumper($metadata);
