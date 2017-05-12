# Astro::ADS::Result::Paper test harness

use Test::More tests => 21;
use Astro::ADS::Query;
use Astro::ADS::Result::Paper;

# T E S T   H A R N E S S --------------------------------------------------
my $wait = 5;   # seconds to wait before subsequent calls to ADS

# Set the test paper meta-data
my $bibcode = "1998MNRAS.295..167A";
my $title = "ASCA X-ray observations of EX Hya - Spin-resolved spectroscopy";

my @authors = ("Allan, Alasdair", "Hellier, Coel", "Beardmore, Andrew");
my @affil = ( "Keele Univ. 0", "Keele Univ. 1", "Keele Univ. 2");

my $journal = "Royal Astronomical Society, Monthly Notices, vol. 295, p. 167";
my $published = "3/1998";

my @keywords = ( "WHITE DWARF STARS", "X RAY ASTRONOMY", "SPECTRAL RESOLUTION", 
	"ASTRONOMICAL", "SPECTROSCOPY", "ACCRETION DISKS", "ASTRONOMICAL MODELS", 
	"TEMPERATURE", "DISTRIBUTION", "SHOCK WAVES");

my $origin = "STI";

my @links = ( "ABSTRACT", "EJOURNAL", "ARTICLE", "GIF", "REFERENCES", "CITATIONS", "SIMBAD");

my $URL = 'http://ukads.nottingham.ac.uk/cgi-bin/nph-bib_query?bibcode=1998MNRAS.295..167A';
#"http://cdsads.u-strasbg.fr/cgi-bin/nph-bib_query?bibcode=1998MNRAS.295..167A";

my @abstract = <DATA>;
chomp @abstract;

my $object = "EX Hya";

my $score = 1.0;

# create an Astro::ADS::Result::Paper object from the meta-data
diag("Create new Result::Paper object with full metadata for $bibcode");
my $paper = new Astro::ADS::Result::Paper( Bibcode   => $bibcode,
                                           Title     => $title,
                                           Authors   => \@authors,
                                           Affil     => \@affil,
                                           Journal   => $journal,
                                           Published => $published,
                                           Keywords  => \@keywords,
                                           Origin    => $origin,
                                           Links     => \@links,
                                           URL       => $URL,
                                           Abstract  => \@abstract,
                                           Object    => $object,
                                           Score     => $score );

is( $paper->bibcode(), $bibcode, "Should fetch paper bibcode $bibcode" );
is( $paper->title(), $title, "Should fetch paper title $title" );

# Authors
my @ret_authors = $paper->authors();
is_deeply( \@ret_authors, \@authors, "Should get 3 authors" );
my $first_author = $paper->authors();
is( $first_author, $authors[0], "Calling authors in scalar context gets the first author" );


# Author Afilliations
my @ret_affil = $paper->affil();
is_deeply( \@ret_affil, \@affil, "Afilliations" );
my $first_author_affil = $paper->affil();
is( $first_author_affil, $affil[0], "check affiliation in scalar context" );


# Check the metadata is the same
is( $paper->journal(), $journal, "check the journal $journal" );
is( $paper->published(), $published, "check the publication date $published" );
is( $paper->object(), $object, "the astronomical object should be $object" );
is( $paper->score(), $score, "the score should be $score" );
is( $paper->origin(), $origin, "is the origin $origin" );

# Keywords
my @ret_keys = $paper->keywords();
is_deeply(\@ret_keys, \@keywords, 'Should fetch all the keywords');
my $num_keys = $paper->keywords();
is( $num_keys, $#keywords, "keywords called in scalar context should get the number -1" );


# Links (outbound)
my @ret_urls = $paper->links();
is_deeply(\@ret_urls, \@links, 'Should fetch all the outbound links');
my $num_urls = $paper->links();
is( $num_urls, $#links, "Scalar call to links should give $#links" );

# Abstract
my @ret_abs = $paper->abstract();
is_deeply(\@ret_abs, \@abstract, 'Should get its abstract');
my $lines = $paper->abstract();
is( $lines, $#abstract, "scalar call to abstract" );


####
# FOLLOWUP QUERIES
# ----------------


diag("do a followup query by calling the references method");
sleep $wait;
my $refs = $paper->references();

#### Source of Possible Confusion #### 
# As of Feb 2010, there are 27 citations and 30 references reported by ADS
# There were 27 references on ADS for this paper in July 2003,
# but there were 30 references on ADS for this paper in May 2009
# There are 32 references in the original paper
####
my $references_found = $refs->sizeof();
ok( $references_found >= 30 && $references_found <= 32, "number of references bounded between 30 and 32" );

#
# Citations
#
diag("do a followup query by calling the citations method");
sleep $wait;
my $cites = $paper->citations();

# 27 citations as of Feb 2010
# 28 citations as of Feb 2011
# 30 citations as of Jul 2011
# 34 citations as of Jul 2013
# The number of citations is always increasing, so as long as
# this value is greater than 28, you should be fine.  If in doubt,
# check http://adsabs.harvard.edu/abs/1998MNRAS.295..167A

my %ADS_citations = ( number_reported => 34,
						year_reported => 2013,
						cites_per_year => 2 );

my $current_number_of_citations = $cites->sizeof();
my $current_year = 1900 + (localtime)[5];

cmp_ok( $current_number_of_citations, '>=', $ADS_citations{'number_reported'}, 
			"The current number of citations must at least $ADS_citations{'number_reported'}");
cmp_ok( $current_number_of_citations, 
		'<=',
        ($ADS_citations{'number_reported'} 
			+ $ADS_citations{'cites_per_year'} * ($current_year - $ADS_citations{'year_reported'})
			+ 1
		),
		"The current number of citations shouldn't be too many more than $ADS_citations{'number_reported'}
Ignore this test failure if the number of ciations is close enough to the expected value" );

#
# Table of Contents
#
# shouldn't be a TOC with this paper
my $toc = $paper->tableofcontents();
is( $toc, undef, "There should be No table of contents" );

done_testing();
exit;

# D A T A   B L O C K  ----------------------------------------------------

__DATA__
We analyze the spectral changes over the spin modulation in the 
intermediate polar EX Hya using archival ASCA data. We find that the 
modulation can be modelled as either (1) the effect of occultation of 
the accretion poles by the limb of the white dwarf, or (2) the effect of 
phase-dependent photoelectric absorption. We argue, on the basis of the 
partial X-ray eclipse, that the accretion columns in the system are 
tall, with shock height Rwd, and hence that the spin modulation is 
caused mainly by occultation. We find that the temperature distribution 
along the accretion shocks is incompatible with the calculations of 
Aizu, except for a restricted parameter regime with a high Mwd. Hence 
the material in the shock must cool faster than predicted by theory. 
