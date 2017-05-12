# Astro::ADS::Query test harness

use strict;
use Test::More tests => 22;
use Astro::ADS::Query;
use Astro::ADS::Result;

# T E S T   H A R N E S S --------------------------------------------------
my $timestamp = join ':', (localtime)[2,1,0];
my $wait = 5;	# seconds to wait before subsequent calls to ADS

# list of authors
my @authors = ( "Allan, Alasdair", "Naylor, Tim", "Harries, T.J.", "Bate, M.");

# Check the configuration of the Query object
my $query = new Astro::ADS::Query( Authors => \@authors );
$query->agent("Test Suite $timestamp");

# Proxy
my $proxy = $query->proxy();
if ($proxy ) {
	diag("You are using $proxy as a web proxy");
}
else {
	diag("No web proxy in use");
}
is( $query->proxy(undef), undef, 'Unset proxy');


# AUTHORS
my @ret_authors = $query->authors();
is_deeply(\@ret_authors, \@authors, "check its got all the authors");
my $first_author = $query->authors();
is( $first_author, $authors[0], "scalar call to authors returns the first author" );

# delete two authors and check again
my @new_authors = @authors[0,1];
my @next_authors = $query->authors(\@new_authors);
is_deeply( \@next_authors, \@new_authors, "delete two authors and check again that it got all its authors");
my $new_first_author = $query->authors();
is( $new_first_author, $new_authors[0], "check authors in scalar context" );

# change author logic
my $author_logic = $query->authorlogic("AND");
is( $author_logic, "AND", "Check author logic" );


# query ADS
diag("First query to ADS (authors)");
my $result = $query->querydb();

# grab the comparison from the DATA block  - NEVER USED, WHY?!?
my @data = <DATA>;
chomp @data;

# change author logic
$author_logic = $query->authorlogic("OR");
is( $author_logic, "OR", "check author login" );

# list of objects
my @objects = ( "U Gem", "SS Cyg");

# Check the configuration of the Query object
my $query2 = new Astro::ADS::Query( Objects => \@objects, proxy => $query->proxy() );
$query2->agent("Test Suite $timestamp");

my @ret_obj = $query2->objects();
is_deeply(\@ret_obj, \@objects, "Check the configuration of the Query object");

# change author logic
my $obj_logic = $query2->objectlogic("AND");
is( $obj_logic, "AND", "check the author logic" );


# query ADS (2)
diag("Second query to ADS - searching on ", join " and ", @objects);
sleep $wait;
my $other_result = $query2->querydb();

is( $other_result->sizeof(), 100, 'Should get 100 abstracts per page (this paper returns 304 results)');

# add some more objects
$objects[2] = "M31";
$objects[3] = "M32";

diag("Third query with additional objects ($objects[2] and $objects[3])");
my $query3 = new Astro::ADS::Query( Objects => \@objects, proxy => $query->proxy() );
$query3->agent("Test Suite $timestamp");
$query3->objectlogic("AND");

# Set the object query
$query3->objects( \@objects );


# query ADS (3)
sleep $wait;
my $next_result = $query3->querydb();

is( $next_result->sizeof(), 0, 'Should have no results with those 4 objects' . join ", ", @objects);

# set and check the proxy
$query2->proxy('http://wwwcache.ex.ac.uk:8080/');
is( $query2->proxy(), 'http://wwwcache.ex.ac.uk:8080/', 'Should return the proxy just set');

# set and check the timeout
$query2->timeout(60);
is( $query2->timeout(), 60, 'checking timeout on the user agent' );

# test bibcode query for Tim Jenness
diag("Fourth query for Tim Jenness' paper 1996PhDT........42J");
my $query4 = new Astro::ADS::Query( Bibcode => "1996PhDT........42J", proxy => $query->proxy() );
$query4->agent("Test Suite $timestamp");

# query ADS
sleep $wait;
my $bibcode_result = $query4->querydb();

# check we have the right object
#
# TODO: Should get the abstract and match test against that
#
my $timj_thesis = $bibcode_result->paperbyindex( 0 );
my @timj_abstract = $timj_thesis->abstract();
cmp_ok( @timj_abstract, ">=", 33, "number of lines of text for Tim Jenness' abstract" );
#open my $fh, '>', 't/timj_abstract.txt';
#print $fh @timj_abstract, "\n";
#close $fh;

# test the user agent tag
diag("User Agent: ", $query4->agent() );

# Test the start/end year and month options
$query4->startmonth( "01" );
is( $query4->startmonth(), "01", 'Start month option' );

$query4->endmonth( "12" );
is( $query4->endmonth(), "12", 'End month option' );

$query4->startyear( "2001" );
is( $query4->startyear(), "2001", 'Start year option' );

$query4->endyear( "2002" );
is( $query4->endyear(), "2002", 'End year option' );

# test the ampersand bibcode bug rt #35645( affects Astronomy & Astrophysics )
my $bibcode5 = '1977A&A....60...43D';
diag("Fifth query for $bibcode5");
my $query5 = new Astro::ADS::Query( Bibcode => $bibcode5, proxy => $query->proxy() );
$query5->agent("Test Suite $timestamp");

sleep $wait;
my $AnA_bibcode_result = $query5->querydb();

# check we have the right object
my $AnA_paper = $AnA_bibcode_result->paperbyindex( 0 );
my $AnA_title = $AnA_paper->title();
my $AnA_bibcode = $AnA_paper->bibcode();

# title from Web search
is( $AnA_title, 'NGC 1510 - A young elliptical galaxy', 'Title from Web search' );
is( $AnA_bibcode, $bibcode5, "bibcodes should match $bibcode5" );

diag("Call reference method on $AnA_bibcode");
my $AnA_references = $AnA_paper->references();
is( $AnA_references->sizeof(), 39, 'check the references with ampersand in bibcode' );
is( $AnA_references->paperbyindex(2)->bibcode(), '1973A&A....29...43B', 'Third reference should be the 1973 Astronomy & Astrophysics paper');

done_testing;
exit;

# D A T A   B L O C K  ----------------------------------------------------

__DATA__
Query Results from the Astronomy Database


Retrieved 1 abstracts, starting with number 1.  Total number selected: 1.

%R 1999MNRAS.310..407W
%T A spatially resolved `inside-out' outburst of IP Pegasi
%A Webb, N. A.; Naylor, T.; Ioannou, Z.; Worraker, W. J.; Stull, J.; Allan, A.;
Fried, R.; James, N. D.; Strange, D.
%F AA(Department of Physics, Keele University, Keele, Staffordshire ST5 5BG), 
AB(Department of Physics, Keele University, Keele, Staffordshire ST5 5BG), 
AC(Department of Physics, Keele University, Keele, Staffordshire ST5 5BG), 
AD(65 Wantage Road, Didcot, Oxfordshire OX11 0AE), AE(Stull Observatory, 
Alfred University, Alfred, NY 14802, USA), AF(Department of Physics, Keele 
University, Keele, Staffordshire ST5 5BG), AG(Braeside Observatory, PO Box 
906 Flagstaff, AZ 86002, USA), AH(11 Tavistock Road, Chelmsford, Essex CM1 
6JL), AI(Worth Hill Observatory, Worth Matravers, Dorset)
%J Monthly Notices, Volume 310, Issue 2, pp. 407-413.
%D 12/1999
%L 413
%K ACCRETION, ACCRETION DISCS, BINARIES: ECLIPSING, STARS: INDIVIDUAL: IP PEG, 
NOVAE, CATACLYSMIC VARIABLES, WHITE DWARFS, INFRARED: STARS
%G MNRAS
%C (c) 1999 The Royal Astronomical Society
%I ABSTRACT: Abstract;
   EJOURNAL: Electronic On-line Article;
   ARTICLE: Full Printable Article;
   REFERENCES: References in the Article;
   CITATIONS: Citations to the Article;
   SIMBAD: SIMBAD Objects;
%U http://cdsads.u-strasbg.fr/cgi-bin/nph-bib_query?bibcode=1999MNRAS.310..407W&db_key=AST 
%S  1.000
%B We present a comprehensive photometric data set taken over the entire 
outburst of the eclipsing dwarf nova IP Peg in 1997 September/October. 
Analysis of the light curves taken over the long rise to the 
peak-of-outburst shows conclusively that the outburst started near the 
centre of the disc and moved outwards. This is the first data set that 
spatially resolves such an outburst. The data set is consistent with the 
idea that long rise times are indicative of such `inside-out' outbursts. 
We show how the thickness and the radius of the disc, along with the 
mass transfer rate, change over the whole outburst. In addition, we show 
evidence of the secondary and the irradiation thereof. We discuss the 
possibility of spiral shocks in the disc; however, we find no conclusive 
evidence of their existence in this data set. 
