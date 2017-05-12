#-*-cperl-*-

use Test::More;
use warnings;
use strict;

use lib qw( lib ../lib ../../lib  ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Individual::BitString;
use Algorithm::Evolutionary::Utils 
  qw(entropy consensus average decode_string 
     vector_compare random_bitstring random_number_array);

my @pop;
my $number_of_bits = 20;
my $population_size = 20;
my $last_bitstring = "0"x$number_of_bits;
for ( 0..$population_size ) {
  my $random_bitstring = random_bitstring( $number_of_bits );
  isnt( $random_bitstring, $last_bitstring, "New random bitstring" );
  $last_bitstring = $random_bitstring;
  #Creates random individual
  my $indi = Algorithm::Evolutionary::Individual::BitString->from_string( $random_bitstring ) ; 
  $indi->Fitness( rand );
  push( @pop, $indi );
}

my $size = 3;
my $min = -10;
my $range = 20;
my @last_number_array = qw( 0 0 0 );
for ( 0..$population_size ) {
  my @random_number_array = random_number_array( $size, $min, $range );
  isnt( $random_number_array[0], $last_number_array[0], "New random number array" );
  @last_number_array = @random_number_array;
}

#test utils

ok( entropy( \@pop ) > 0, "Entropy" );
ok( length(consensus( \@pop )) > 1, "Consensus" );
ok( average( \@pop ) > 0, "Average");
is( scalar( decode_string( $pop[0]->Chrom(), 10, -1, 1 ) ), 2, "Decoding" );
my @vector_1 = qw( 1 1 1);
my @vector_2 = qw( 0 0 0);
is( vector_compare( \@vector_1, \@vector_2 ), 1, "Comparison 0" );
@vector_2 = qw( 0 0 1);
is( vector_compare( \@vector_1, \@vector_2 ), 1, "Comparison 1" );
@vector_2 = qw( 1 1 1);
is( vector_compare( \@vector_1, \@vector_2 ), 0 , "Comparing equal" );
@vector_2 = qw( 2 2 1);
is( vector_compare( \@vector_1, \@vector_2 ), -1, "Compare less" );

done_testing;

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2010/09/24 08:39:07 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/t/0002-utils.t,v 3.1 2010/09/24 08:39:07 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $
  $Name $

=cut
