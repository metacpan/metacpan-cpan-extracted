#
# biblio @ pc-nerz
#
use strict;
use Test::More tests => 4;

BEGIN {
	use_ok( 'Biblio::Biblio' );
}

my $bib = new Biblio::Biblio(
	file => 't/sample.bib',
	verbose => 0,
	quiet => 1,
	);
isnt($bib, undef, "open biblio database");

my $refs = $bib->queryPapers();
isnt($refs, undef, "queryPapers()");

my $a = $bib->queryPaperWithId('Roomware-NextGeneration');
is_deeply($a,{
		'Editors' => 'J. A. Carroll',
		'Keywords' => 'BEACH, user-centered system design, workspaces of the future, team work, cooperative buildings, ...',
		'Title' => 'Roomware: Towards the next generation of human-computer interaction based on an integrated design of real and virtual worlds',
		'BibDate' => '2003-06-16 11:44:53',
		'Year' => '2001',
		'CrossRef' => 'Carroll-HCIMillennium', ## CrossRef is now handeled by bp ...
		'Source' => 'http://ipsi.fraunhofer.de/ambiente/publications/',
		'Publisher' => 'Addison Wesley',
		'OrigFormat' => 'bibtex (dj 18 dec 96)',
		'CiteType' => 'incollection',
		'Pages' => '553-578',
		'Authors' => 'Norbert A. Streitz, Peter Tandler, Christian Müller-Tomfelde, and Shin\'ichi Konomi',
		'exportdate' => '2003-06-16 11:44:53',
		'Identifier' => 'Streitz et al. 2001',
		'SuperTitle' => 'Human-Computer Interaction in the New Millennium',
		'Category' => 'UbiComp',
		'CiteKey' => 'Roomware-NextGeneration',
		'Recommendation' => '+++',
	}, "queryPaperWithId('Roomware-NextGeneration')");

#use Data::Dumper;
#print Dumper $a;

TODO: {
	my $x = {qw(
		CiteKey test
		CiteType article
		Authors Authors
		Category test
		Title test-title
		Journal test-journal
		Volume 1
		Number 2
		Pages 3-4
		)};
	
	$bib->storePaper($x);
}
