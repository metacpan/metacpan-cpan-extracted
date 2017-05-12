#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More; # No plan

use warnings;
use strict;

use lib qw( ../../algorithm-evolutionary-utils/lib ../../lib ../lib lib ); #Just in case we are testing it in-place
use Algorithm::Evolutionary::Utils qw(random_bitstring);

use_ok( "Algorithm::Evolutionary::Fitness::ONEMAX", "using A::E::Fitness::ONEMAX OK" );

my $om = new Algorithm::Evolutionary::Fitness::ONEMAX;
isa_ok( $om,  "Algorithm::Evolutionary::Fitness::ONEMAX" );

my $num_bits = 32;
my $indi = random_bitstring( $num_bits, 1) ; # Build random bitstring with length 10
ok( $om->_apply( $indi ) > 0, "Works on indis" );
ok( $om->onemax( $indi->{'_str'})  > 0, "Works on strings" );
my $string = "11111111111";
my $copy = $string;
ok( $om->onemax( $string) == 11, "OK count 1" );
ok( $string == $copy, "String not affected" );
$string = "010111101111110";
ok( $om->onemax( $string ) == 11, "OK count 2" );
$om->reset_evaluations();
ok( $om->evaluations() == 0, "Evaluations reset");
ok( scalar keys %{$om->cache()} > 0, "Cache used" );
done_testing();
