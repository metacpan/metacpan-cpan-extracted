#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Utils qw(random_number_array);

use_ok( "Algorithm::Evolutionary::Fitness::Rastrigin", "using Fitness::Rastrigin OK" );

my $size = 10;
my $min = -5.12;
my $range = 10.24;

my $tests = 20;
my $r = new Algorithm::Evolutionary::Fitness::Rastrigin( $size );
isa_ok( $r,  "Algorithm::Evolutionary::Fitness::Rastrigin" );
for my $t ( 1..$tests ) {
  my @random_number_array = random_number_array( $size, $min, $range );
  is ( $r->Rastrigin( @random_number_array ) > 0, 1, "Applying $t test" );
}

done_testing;



