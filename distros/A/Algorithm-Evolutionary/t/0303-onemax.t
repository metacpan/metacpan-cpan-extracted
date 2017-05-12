#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More tests => 6;

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place
use Algorithm::Evolutionary::Individual::BitString;

use_ok( "Algorithm::Evolutionary::Fitness::ONEMAX", "using A::E::Fitness::ONEMAX OK" );

my $om = new Algorithm::Evolutionary::Fitness::ONEMAX;
isa_ok( $om,  "Algorithm::Evolutionary::Fitness::ONEMAX" );

my $num_bits = 32;
my $indi = new Algorithm::Evolutionary::Individual::BitString $num_bits ; # Build random bitstring with length 10
ok( $om->_apply( $indi ) > 0, "Works on indis" );
ok( $om->onemax( $indi->{'_str'})  > 0, "Works on strings" );
my $string = "11111111111";
ok( $om->onemax( $string) == 11, "OK count 1" );
$string = "010111101111110";
ok( $om->onemax( $string ) == 11, "OK count 2" );

