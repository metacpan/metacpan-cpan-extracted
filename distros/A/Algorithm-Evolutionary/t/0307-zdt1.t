#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Utils qw(random_bitstring);

use_ok( "Algorithm::Evolutionary::Fitness::ZDT1", "using Fitness::ZDT1 OK" );

my $number_of_bits = 10;

my $zdt1 = new Algorithm::Evolutionary::Fitness::ZDT1( $number_of_bits );
isa_ok( $zdt1,  "Algorithm::Evolutionary::Fitness::ZDT1" );

my $string = random_bitstring($number_of_bits*30);
my $array_ref = $zdt1->zdt1( $string );
ok( scalar @{$array_ref} == 2, "Returns a vector" );
ok( $array_ref->[0] >= 0, "First comp OK" );
ok( $array_ref->[1] <= 30, "2nd comp OK" );


