#!perl

# Test that we can read a JCMT catalogue that is not rigid about its
# columns. Test simply creates a catalogue with random junk attached
# and then reads it in and compares target values.

use strict;
use Test::More tests => 13;

require_ok( 'Astro::Coords' );
require_ok( 'Astro::Catalog::Star' );
require_ok( 'Astro::Catalog' );


# test sources
my @input = (
	     {
	      ra => '03:25:27.1',
	      dec => '30:45:11',
	      type => 'j2000',
	      name => 'a space',
	      comment => 'with comment'
	     },
	     {
	      ra => '13:25:27.1',
	      dec => '-30:45:11',
	      type => 'b1950',
	      name => 'test',
	     },
	     {
	      long => '03:26:30.0',
	      lat => '-1:45:0',
	      type => 'galactic',
	      name => 'gal 2',
	     }

	    );

# Start by having some test coordinates
# convert test sources to Astro::Coords and randomly
my @ref = map {
  new Astro::Coords( units => 'sex', %$_ );
} @input;

# Make sure we have constructed objects
for (@ref) {
  isa_ok( $_, "Astro::Coords::Equatorial");
}


# Generate a catalogue manually
my @lines = ("* a comment\n");
for my $c (@ref) {
  my $line = $c->name;
  my $ra = $c->ra(format => 's');
  my $dec = $c->dec( format => 's');
  $ra =~ s/:/ /g;
  $dec =~ s/:/ /g;

  $line .= "$ra $dec ";

  # Always RJ
  $line .= "rj ";

  if (rand(1) < 0.5) {
    # add some extra stuff
    my $vel = (rand(1)<0.5 ? "- 35." : "N/A");
    my $flux = (rand(1)<0.5 ? "42.4" : "n/a");
    my $range = 'n/a';
    my $frame = "LSR";
    my $veldef = "RADIO";
    my $comment = ($c->comment ? $c->comment : "ooh");

    $line .= " $vel $flux $range $frame $veldef $comment";
  }
  $line .= "\n";

  push(@lines, $line);

}

# Read the data array
my $cat = new Astro::Catalog( Format => 'JCMT', Data => \@lines );

# Get the source list and remove planets
my @sources = $cat->stars;
my @filter = grep { $_->coords->isa("Astro::Coords::Equatorial") } @sources;

is($#filter, $#ref, "Compare size");

# Now compare
for my $i (0..$#ref) {
  is($filter[$i]->id, $ref[$i]->name, "Compare names");
  ok($ref[$i]->distance( $filter[$i]->coords) < 0.1, "Compare distance");
}

# Write catalog to array so we can prepend test output with a #
my @output;
$cat->write_catalog( Format => 'JCMT', File => \@output );
print "# " . join("\n# ", @output) ."\n";
