#-*-cperl-*-

use Test::More;

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Utils qw(random_bitstring);

use_ok( "Algorithm::Evolutionary::Fitness::Trap", "using Fitness::Trap OK" );

my $number_of_bits = 5;

my $trap = new Algorithm::Evolutionary::Fitness::Trap( $number_of_bits );
isa_ok( $trap,  "Algorithm::Evolutionary::Fitness::Trap" );

my $string = random_bitstring(100);
ok( $trap->trap( $string ) > 0, "Seems to work" );
ok( $trap->trap( $string ) > 0, "From cache" );

#All fields
my $new_trap = new Algorithm::Evolutionary::Fitness::Trap( 4, 2, 3, 2 ); 
ok( $new_trap->trap( $string ) > 0, "Seems to work" );
ok( $new_trap->trap( $string ) > 0, "From cache" );

for ( my $i = 0; $i < 16; $i++ ) {
  my $binary = sprintf "%04b", $i;
  my $resultado = $new_trap->trap( $binary );
  ok( $resultado >= 0, "Result for $binary is $resultado" );
}

done_testing();
