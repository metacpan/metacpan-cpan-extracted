#!/usr/bin/perl

use utf8;
use lib "../..";

use Biblio::Document::Parser::Standard;
use Biblio::Document::Parser::Utils;
use Biblio::Citation::Parser::Standard;
use Biblio::Citation::Parser::Citebase;
use Biblio::Citation::Parser::Utils;
use Term::ANSIColor;

binmode(STDERR, ":utf8");
binmode(STDOUT, ":utf8");

if (scalar @ARGV != 1)
{
	print STDERR "Usage: $0 <filename>\n";
	exit;
}

my $cit_parser = new Biblio::Citation::Parser::Standard;
my $doc_parser = new Biblio::Document::Parser::Standard;

#print "Parsed using Biblio::Citation::Parser::Standard\n\n";

#parse_document($doc_parser,$cit_parser);

print "Parsed using Biblio::Citation::Parser::Citebase\n\n";

$cit_parser = new Biblio::Citation::Parser::Citebase;
parse_document($doc_parser,$cit_parser);

sub parse_document {
	my ($doc_parser,$cit_parser) = @_;
	my $content = get_content($ARGV[0]);
	my @references = $doc_parser->parse($content);
	foreach $reference (@references)
	{
		$metadata = $cit_parser->parse($reference);
		$location = create_openurl($metadata);
		print
			color("red"), "$reference\n", color("reset"),
			color("green"), "\t$location\n", color("reset"),
			"---\n";
	}
}
