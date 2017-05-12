#-*-cperl-*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Utils qw(hamming);

use_ok( "Algorithm::Evolutionary::Fitness::P_Peaks", "using Fitness::P_Peaks OK" );

my $peaks = 100;
my $bits = 32;
my $p_peaks = new Algorithm::Evolutionary::Fitness::P_Peaks( $peaks, $bits );
isa_ok( $p_peaks,  "Algorithm::Evolutionary::Fitness::P_Peaks" );

is( hamming( "111000111", "011100110" ), 3, "Hamming OK" );

my $string = $p_peaks->random_string();
my $result = $p_peaks->p_peaks( $string );
ok( $result > 0, "Seems to work" );
is( $p_peaks->p_peaks( $string ), $result, "Caching" );
is( $p_peaks->cached_evals(), 1, "Cached evals" );
$bits = 192;
$p_peaks = new Algorithm::Evolutionary::Fitness::P_Peaks( $peaks, $bits );
for ( my $i = 0; $i < $peaks; $i ++ ) {
  cmp_ok($p_peaks->p_peaks( $p_peaks->random_string() ), ">=", 0, "Distance OK" );
}
done_testing();
