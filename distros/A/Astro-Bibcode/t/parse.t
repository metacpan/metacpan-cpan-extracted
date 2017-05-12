#!perl

# Simple test of bibcode parsing

use strict;
use Test::More tests => 33;

require_ok( 'Astro::Bibcode' );

# Basic null constructor
my $bib = new Astro::Bibcode( );
isa_ok( $bib, "Astro::Bibcode");

# Set of bibcodes to verify
my %BIB = (
	   '1996PhDT........42J' => {
				     year => 1996,
				     journalcode => 'PhDT',
				     initial => 'J',
				     class => 'thesis',
				    },
	   '2000immm.proc...77G' => {
				     year => 2000,
				     journalcode => 'immm',
				     class => 'conference proceeding',
				    },
#	   '2002yCat..33851014C' => {
#				     year => 2002,
#				     initial => 'C',
#				     class => 'catalog',
#		 },
#	   '2001AAS...19915601S' => {
#				     year => 2001,
#				     journalcode => 'AAS',
#				    },
	   '1999A&amp;A...345..949C' => {
					 year => 1999,
					 volume => 345,
					 page => 949,
					 class => 'periodical',
					 initial => 'C',
					 journalcode => 'A&A',
					 journal => 'Astronomy and Astrophysics',
					},
	   '2000adass...9..559J' => {
				     year => 2000,
				     journalcode => 'adass',
				     volume => 9,
				     class => 'recurring conference',
				     page => 559,
				     initial => 'J',
				     journal => 'ASP Conf. Ser. 216: Astronomical Data Analysis Software and Systems IX',
				    },
	   '2000irsm.conf..164P', => {
				      year => 2000,
				      journalcode => 'irsm',
				      class => 'conference proceeding',
				      page => 164,
				      initial => 'P',
				     },

	  );

# loop over bibcodes
for my $bcode (keys %BIB) {
  my $retval = $bib->bibcode( $bcode );
  ok( $retval, "store bibcode $bcode");

  SKIP: {
      skip "No object created", scalar keys %{$BIB{$bcode}}
         unless $retval;

      # only if good status
      for my $key (keys %{$BIB{$bcode}}) {
	my $data = $bib->$key();
	is($bib->$key, $BIB{$bcode}->{$key}, "Compare $key");
      }
    }

  if ($retval) {
    prt($bib->summary) ;
  } else {
    prt("No object to summarise for bibcode $bcode");
  }

}

exit;

# Prepend # and print
sub prt {
  my $string = shift;
  print map { "# $_\n" } split(/\n/, $string);
}
