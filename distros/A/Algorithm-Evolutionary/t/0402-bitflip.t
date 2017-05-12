#-*-cperl-*-

use warnings;
use strict;

use lib qw( ../../lib ../lib lib ); #Just in case we are testing it in-place

use Test::More tests => 5;

BEGIN { 
  use_ok( 'Algorithm::Evolutionary::Op::Bitflip' );
};

use Algorithm::Evolutionary::Individual::BitString;
use Algorithm::Evolutionary::Utils qw(hamming);

my $bits = 36;
my $size = 6;
my $indi = new Algorithm::Evolutionary::Individual::BitString $bits;


my $bf = new Algorithm::Evolutionary::Op::Bitflip 1;
isa_ok( $bf, 'Algorithm::Evolutionary::Op::Bitflip' );

my $indi2 = $bf->apply($indi);
isnt( $indi2->Chrom(), $indi->Chrom(), "Testing bitflip" );
isnt( $bf->apply($indi2)->Chrom(), $indi2->Chrom(), "Testing bitflip again" );

$bf = new Algorithm::Evolutionary::Op::Bitflip 5;
is( hamming($bf->apply($indi)->Chrom(), $indi->Chrom), 5, "5 bitflips" );

