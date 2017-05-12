# Astro::ADS::Result test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 4 };

# load modules
use Astro::ADS::Result;
use Astro::ADS::Result::Paper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# create a test paper object
my ( $bibcode, $title, @authors, @affil, $journal, $published, @keywords,
     $origin, @links, $URL, @abstract1, @abstract2, $object );

# separate the two abstracts from the __DATA_ block
my @data = <DATA>;
chomp @data;
for my $i ( 0 ... 10 ) {
   push ( @abstract1, $data[$i] );
}
for my $i ( 12 ... 19 ) {
   push ( @abstract2, $data[$i] );
}

# Set the test paper meta-data
$bibcode = "1998MNRAS.295..167A";
$title = "ASCA X-ray observations of EX Hya - Spin-resolved spectroscopy";

$authors[0] = "Allan, Alasdair";
$authors[1] = "Hellier, Coel";
$authors[2] = "Beardmore, Andrew";
$affil[0] = "Keele Univ. 0";
$affil[1] = "Keele Univ. 1";
$affil[2] = "Keele Univ. 2";

$journal = "Royal Astronomical Society, Monthly Notices, vol. 295, p. 167";
$published = "3/1998";

$keywords[0] = "WHITE DWARF STARS";
$keywords[1] = "X RAY ASTRONOMY";
$keywords[2] = "SPECTRAL RESOLUTION";
$keywords[3] = "ASTRONOMICAL"; 
$keywords[4] = "SPECTROSCOPY";
$keywords[5] = "ACCRETION DISKS";
$keywords[6] = "ASTRONOMICAL MODELS";
$keywords[7] = "TEMPERATURE"; 
$keywords[8] = "DISTRIBUTION";
$keywords[9] = "SHOCK WAVES";

$origin = "STI";

$links[0] = "ABSTRACT";
$links[1] = "EJOURNAL";
$links[2] = "ARTICLE";
$links[3] = "GIF";
$links[4] = "REFERENCES";
$links[5] = "CITATIONS";
$links[6] = "SIMBAD";

$URL =
 "http://ukads.nottingham.ac.uk/cgi-bin/nph-bib_query?bibcode=1998MNRAS.295..167A";
 #"http://cdsads.u-strasbg.fr/cgi-bin/nph-bib_query?bibcode=1998MNRAS.295..167A";

$object = "EX Hya";

# create an Astro::ADS::Result::Paper object from the meta-data
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
                                           Abstract  => \@abstract1,
                                           Object    => $object );

# some new meta-data
$bibcode = "2001adass..10..459A";
$title = "IFU Data Products and Reduction Software";

$authors[0] = "Allan, A.";
$authors[1] = "Allington-Smith, J.";
$authors[2] = "Turner, J.";
$authors[3] = "Johnson, R.";
$authors[4] = "Miller, B.";
$authors[5] = "Valdes, F. G";
$affil[0] = undef;
$affil[1] = undef;
$affil[2] = undef;
$affil[3] = undef;
$affil[4] = undef;
$affil[5] = undef;

$journal = "Astronomical Data Analysis Software and Systems X, ASP Conference 
Proceedings, Vol. 238. Edited by F. R. Harnden, Jr., Francis A. Primini, and 
Harry E. Payne. San Francisco: Astronomical Society of the Pacific, ISSN: 
1080-7926, 2001., p.459";
$published = "1/2001";

$keywords[0] = undef;

$origin = "AUTHOR";

$links[0] = "ABSTRACT";

$URL =
 "http://ukads.nottingham.ac.uk/cgi-bin/nph-bib_query?bibcode=2001adass..10..459A";
 #"http://cdsads.u-strasbg.fr/cgi-bin/nph-bib_query?bibcode=2001adass..10..459A";

# create another Astro::ADS::Result::Paper object from the meta-data
my $other = new Astro::ADS::Result::Paper( Bibcode   => $bibcode,
                                           Title     => $title,
                                           Authors   => \@authors,
                                           Affil     => \@affil,
                                           Journal   => $journal,
                                           Published => $published,
                                           Keywords  => \@keywords,
                                           Origin    => $origin,
                                           Links     => \@links,
                                           URL       => $URL,
                                           Abstract  => \@abstract2 );

my @paper_stack;
push( @paper_stack, $paper, $other);

# create an Astro::ADS::Result object
my $result = new Astro::ADS::Result( Papers => \@paper_stack );

# create another
my $next = new Astro::ADS::Result( );

# push papers onto $next
$next->pushpaper( $paper );
$next->pushpaper( $other );

# should be the same
ok( $result->sizeof(), $next->sizeof() );

# pop one paper off $next
my $ret_paper = $next->poppaper();

# compare with $other
ok( $other->bibcode(), $ret_paper->bibcode() );

# paperbyindex
my $index_paper = $result->paperbyindex(1);

# compare with $ret_paper
ok( $index_paper->bibcode(), $ret_paper->bibcode() );


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
We present a summary of the current status of Starlink and UK data 
reduction and science product manipulation software for the next 
generation of IFUs, and discuss the implications of the currently 
available analysis software with respect to the scientific output of 
these new instruments. The possibilities of utilising existing software 
for science product analysis is examined. We also examine the competing 
science product data formats, and discuss the conventions for 
representing the data in a multi-extension FITS format.
