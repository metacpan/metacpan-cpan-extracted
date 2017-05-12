use strict;
use warnings;

use Test::More ;

plan tests => 12;

use Data::Random::Nucleotides qw/rand_nuc/;

## Fixed size
my $nuc = rand_nuc(size=>50);
like ( $nuc, qr/^[ACGT]{50}$/, "nucleotides");

## Variable size
foreach ( 1 .. 10 ) {
	my $nuc = rand_nuc(min=>10, max=>100);
	like ( $nuc, qr/^[ACGT]{10,100}$/, "nucleotides_10_to_100");
}

## Fixed size, with N
$nuc = rand_nuc(size=>1000);
like ( $nuc, qr/^[ACGTN]{1000}$/, "nucleotides_with_N");
