#!/stardev/Perl/bin/perl -w

# strict
use strict;

use Test::More tests => 92;

# load test modules
require_ok( "Astro::FITS::Header::Item");

# read comparison header from the end of the test file
my @raw = <DATA>;
chomp @raw;

# Store the answers in an array, the index must match the index into @raw
# Might be better to store in a hash indexed by the card itself
# but would require us to not use <DATA>
my @ANSWER = (
	      {
	       Keyword => 'LOGICAL',
	       Value   => 'T',
	       Comment => 'Testing the LOGICAL type',
	       Type    => 'LOGICAL',
	      },
	      {
	       Keyword => 'INTEGER',
	       Value   => -32,
	       Comment => 'Testing the INT type',
	       Type    => 'INT',
	      },
	      {
	       Keyword => 'FLOAT',
	       Value   => 12.5,
	       Comment => 'Testing the FLOAT type',
	       Type    => 'FLOAT',
	      },
	      {
	       Keyword => 'UNDEF',
	       Value   => undef,
	       Comment => 'Testing the undef type',
	       Type    => 'UNDEF',
	      },
	      {
	       Keyword => 'STRING',
	       Value   => 'string',
	       Comment => 'Testing the STRING type',
	       Type    => 'STRING',
	      },
	      {
	       Keyword => 'LNGSTR',
	       Value   => 'a very long string that is long',
	       Comment => 'Long string',
	       Type    => 'STRING',
	      },
	      {
	       Keyword => 'QUOTE',
	       Value   => "a ' single quote",
	       Comment => 'Single quote',
	       Type    => 'STRING',
	      },
	      {
	       Keyword => 'ZERO',
	       Value   => "",
	       Comment => 'Zero length quote',
	       Type    => 'STRING',
	      },
	      {
	       Keyword => 'COMMENT',
	       Comment => 'Testing the COMMENT type',
	       Type    => 'COMMENT',
	      },
	      {
	       Keyword => 'HISTORY',
	       Comment => '  Testing the HISTORY type',
	       Type    => 'COMMENT',
	      },
	      {
	       Keyword => 'STRANGE',
	       Comment => '  Testing the non-standard COMMENT',
	       Type    => 'COMMENT',
	      },
	      {
	       Keyword => 'END'
	      },
	     );



# Loop through the array of FITS header items
# Checking that we can reconstruct a FITS header card
foreach my $n (0..$#raw) {

  my $card = $raw[$n];

  # For information
  # print "# $card\n";

  # Create a new Item object using this card
  my $item = new Astro::FITS::Header::Item( Card => $card );

  # Make sure the constructed card is used rather than the cached version
  $item->keyword( $item->keyword );

  # Compare the actual card with the reconstructed version
  # This tests the parsing of header cards
  is( "$item", $card, "Compare card $n" );

  # Test that the parsed card fields match what they're supposed to be
  # LOGICAL values are translated to booleans by the object, so must
  # convert values
  is( eval '$item->'.lc($_),
      ('Value' eq $_ && 'LOGICAL' eq $ANSWER[$n]{Type}) ?
        { T => 1, F => 0 }->{$ANSWER[$n]{$_}} : $ANSWER[$n]{$_},
    "Compare method $_") foreach keys %{$ANSWER[$n]};


  # Now create a new item from the bits
  my $item2 = new Astro::FITS::Header::Item( %{ $ANSWER[$n] });

  # Compare the brand new card with the old version
  # This tests the construction of a card from the raw "bits"
  is( "$item2", $card, "Compare reconstructed card $n");

  # Also compare using the equality method
  # first compare it with itself
  ok( $item->equals($item), "Is the object equal to itself?" );

  # and then with the comparison card
  ok( $item->equals($item2),"Is the object equal to the new object?");
}

# Test that the caching is working. We do this by using
# a card that we know is not conformant
my $c = "LNGSTR  = 'a very long string that is long' /Long string                        ";

my $i = new Astro::FITS::Header::Item( Card => $c);
is("$i", $c, "test cache");



#keyword
#value
#comment
#type
#card

exit;

# T I M E   A T   T H E   B A R ----------------------------------------------

__DATA__
LOGICAL =                    T / Testing the LOGICAL type                       
INTEGER =                  -32 / Testing the INT type                           
FLOAT   =                 12.5 / Testing the FLOAT type                         
UNDEF   =                      / Testing the undef type                         
STRING  = 'string  '           / Testing the STRING type                        
LNGSTR  = 'a very long string that is long' / Long string                       
QUOTE   = 'a '' single quote'  / Single quote                                   
ZERO    = ''                   / Zero length quote                              
COMMENT Testing the COMMENT type                                                
HISTORY   Testing the HISTORY type                                              
STRANGE   Testing the non-standard COMMENT                                      
END                                                                             
