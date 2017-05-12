#-*-cperl-*-

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Test::More tests => 402;

BEGIN { 
  use_ok( 'Algorithm::Evolutionary::Op::Quad_Crossover_Diff' );
};

use Algorithm::Evolutionary::Individual::String;

my $number_of_chars = 32;

my $q = new Algorithm::Evolutionary::Op::Quad_Crossover_Diff $number_of_chars/2;
isa_ok( $q, 'Algorithm::Evolutionary::Op::Quad_Crossover_Diff' );

my $result;
my $str = "A"x$number_of_chars;
my $str_2 = "b"x$number_of_chars;
my $indi = Algorithm::Evolutionary::Individual::String->fromString( $str );
my $indi_2 = Algorithm::Evolutionary::Individual::String->fromString( $str_2 );
for ( 1..100 ) { 
  $str = $indi->{'_str'};
  $str_2 = $indi_2->{'_str'};
  $q->apply( $indi, $indi_2 );
  isnt( $indi->{'_str'}, $str, $indi->{'_str'}." differs from ". $str);
  isnt( $indi_2->{'_str'}, $str_2, $indi_2->{'_str'}." differs from ". $str_2);
}

$q = new Algorithm::Evolutionary::Op::Quad_Crossover_Diff  $number_of_chars/4;
$indi = Algorithm::Evolutionary::Individual::String->fromString( $str );
$indi_2 = Algorithm::Evolutionary::Individual::String->fromString( $str_2 );
for ( 1..100 ) { 
  $str = $indi->{'_str'};
  $str_2 = $indi_2->{'_str'};
  $q->apply( $indi, $indi_2 );
  isnt( $indi->{'_str'}, $str, $indi->{'_str'}." differs from ". $str);
  isnt( $indi_2->{'_str'}, $str_2, $indi_2->{'_str'}." differs from ". $str_2);

}
