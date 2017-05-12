#!/usr/bin/perl 
use Biblio::Citation::Parser::Standard;

# Get a little extra info out of the metadata.

$ref = "Jewell, M (2002) Making Examples for Reference Parsers. Journal of Example Writing 3:100-150.";

print "- Parsing '$ref'\n"; 
my $cit_parser = new Biblio::Citation::Parser::Standard;
$metadata = $cit_parser->parse($ref);
print "- Metadata follows:\n";
print "First name: ".$metadata->{aufirst}."\n";
print "Last name: ".$metadata->{aulast}."\n";
print "Title: ".$metadata->{atitle}."\n";
print "Publication: ".$metadata->{title}."\n";
print "Year: ".$metadata->{year}."\n";
print "Issue: ".$metadata->{issue}."\n";
print "Page range: ".$metadata->{pages}."\n";
print "Matched template: ".$metadata->{match}."\n";
print "Marked result: ".$metadata->{marked}."\n";
