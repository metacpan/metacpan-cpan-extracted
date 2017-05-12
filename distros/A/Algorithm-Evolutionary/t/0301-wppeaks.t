#-*-cperl-*-

use Test::More tests => 5;

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Utils qw(hamming);

use_ok( "Algorithm::Evolutionary::Fitness::wP_Peaks", "using Fitness::wP_Peaks OK" );

my $peaks = 10;
my $bits = 32;
my @weights = (1);
for (1..$peaks ) {
  push @weights, 0.99;
}
my $p_peaks = new Algorithm::Evolutionary::Fitness::wP_Peaks( $bits, @weights );
isa_ok( $p_peaks,  "Algorithm::Evolutionary::Fitness::wP_Peaks" );

my $string = $p_peaks->random_string();
ok( $p_peaks->p_peaks( $string ) > 0, "Seems to work" );

my $descriptor = { number_of_peaks => $peaks,
		   weight => 0.99 };
$p_peaks = new Algorithm::Evolutionary::Fitness::wP_Peaks( $bits, $descriptor );
isa_ok( $p_peaks,  "Algorithm::Evolutionary::Fitness::wP_Peaks" );

$string = $p_peaks->random_string();
ok( $p_peaks->p_peaks( $string ) > 0, "Seems to work" );
