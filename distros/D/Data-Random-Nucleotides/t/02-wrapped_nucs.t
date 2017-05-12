use strict;
use warnings;

use Test::More ;

plan tests => 3;

use Data::Random::Nucleotides qw/rand_wrapped_nuc/;

## Fixed size - shorter than 70 nt, not wrapped.
my $nuc = rand_wrapped_nuc(size=>50);
like ( $nuc, qr/^[ACGT]{50}$/, "wrapped_short");

## Fixed size, long - should be wrapped at 70 characters
$nuc = rand_wrapped_nuc(size=>1000);
like ( $nuc, qr/^[ACGT\n]+$/s, "wrapped_long_content_with_newline");
like ( $nuc, qr/^[ACGT]{0,70}$/m, "wrapped_long_70_chars");
