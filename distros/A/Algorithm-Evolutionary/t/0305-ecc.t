#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Utils qw(random_bitstring);

use_ok( "Algorithm::Evolutionary::Fitness::ECC", "using Fitness::ECC OK" );

my $number_of_codewords = 16;
my $min_distance = 1;

my $ecc = new Algorithm::Evolutionary::Fitness::ECC( $number_of_codewords, $min_distance );
isa_ok( $ecc,  "Algorithm::Evolutionary::Fitness::ECC" );

my $string = random_bitstring(128);
ok( $ecc->ecc( $string ) > 0, "Seems to work" );

