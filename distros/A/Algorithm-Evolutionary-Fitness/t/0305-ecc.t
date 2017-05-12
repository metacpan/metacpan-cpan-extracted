#-*-cperl-*-

use Test::More;
use Test::Exception;

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Algorithm::Evolutionary::Utils qw(random_bitstring);

use_ok( "Algorithm::Evolutionary::Fitness::ECC", "using Fitness::ECC OK" );

my $number_of_codewords = 16;
my $min_distance = 1;

my $ecc = new Algorithm::Evolutionary::Fitness::ECC( $number_of_codewords, $min_distance );
isa_ok( $ecc,  "Algorithm::Evolutionary::Fitness::ECC" );

throws_ok { new Algorithm::Evolutionary::Fitness::ECC()  } qr/codewords/, "No codewords";
throws_ok { new Algorithm::Evolutionary::Fitness::ECC(2,0)  } qr/istance/, "No distance";


my $string = random_bitstring(128);
ok( $ecc->ecc( $string ) > 0, "Seems to work" );
ok( $ecc->ecc( $string ) > 0, "Seems to work again" );
$string = random_bitstring(128);
ok( $ecc->ecc( $string ) > 0, "Keeps working" );
done_testing();
