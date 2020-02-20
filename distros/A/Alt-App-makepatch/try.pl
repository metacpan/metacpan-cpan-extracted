use strictures 2;

use Data::Dump;
use Parse::LocalDistribution;

my $parser = Parse::LocalDistribution->new( { VERBOSE => 1 } );

dd $parser->parse('.');
