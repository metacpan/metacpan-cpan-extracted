#!/usr/bin/perl -w

use Test::More;

use BibTeX::Parser;
use IO::File;

my $fh = new IO::File "t/bibs/braces.bib", "r" ;
my $parser = new BibTeX::Parser $fh;
while (my $entry=$parser->next) {
    is($entry->parse_ok,1);
    if ($entry->key eq 'scholkopf98kpca') {
	@authors=$entry->author;
	is(scalar @authors,3);
	is("$authors[0]", '{Sch\"olkopf}, Bernhard');
	is("$authors[1]", 'Smola, Alex');
	is("$authors[2]", 'Muller, K.R.');
    }
    if ($entry->key eq 'brownetal93') {
	@authors=$entry->author;
	is(scalar @authors,4);
	is("$authors[0]", 'Brown, Peter F.');
	is("$authors[1]", '{Della Pietra}, Stephen A.');
	is("$authors[2]", '{Della Pietra}, Vincent J.');
	is("$authors[3]", 'Mercer, Robert~L.');
    }
}

done_testing();
