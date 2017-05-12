use strict;
use warnings;

use Test::More ;

plan tests => 3;

## test the ":all" export
use Data::Random::Nucleotides qw/:all/;

ok ( rand_fasta(size=>50), "all_rand_fasta");
ok ( rand_nuc(size=>50),   "all_rand_nuc");
ok ( rand_wrapped_nuc(size=>50),"all_rand_wrapped_nuc");
