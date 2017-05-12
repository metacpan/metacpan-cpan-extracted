#-*-cperl-*-

#Test the MMDP fitness function

use Test::More tests => 7;
use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use_ok( "Algorithm::Evolutionary::Fitness::MMDP", "using Fitness::MMDP OK" );

my $units = "000000";
my $mmdp = new  Algorithm::Evolutionary::Fitness::MMDP;
for (my $i = 0; $i < length($units); $i++ ) {
    my $clone = $units;
    substr($clone, $i, 1 ) = "1";
    is(  $mmdp->mmdp( $clone ),
	 $Algorithm::Evolutionary::Fitness::MMDP::unitation[$i+1],
	 "Unitation $i = ". $Algorithm::Evolutionary::Fitness::MMDP::unitation[$i+1]." OK");
    $units = $clone;
}
