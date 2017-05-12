#-*-cperl-*-

use Test::More;

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Utils qw(random_bitstring decode_string);

use_ok( "Algorithm::Evolutionary::Fitness::Any", "using Fitness::Any OK" );

my $string = random_bitstring(64);
sub squares {
  my $chrom = shift;
  my @values = decode_string( $chrom, 32, -1, 1 );
  return $values[0] * $values[1];
}

my $resultado = squares( $string );

my $any_eval = new Algorithm::Evolutionary::Fitness::Any \&squares;

isa_ok( $any_eval,  "Algorithm::Evolutionary::Fitness::Any" );

my $chrom = { '_str' => $string };
ok( $any_eval->apply( $chrom ) == $resultado, "Seems to work" );

done_testing();
