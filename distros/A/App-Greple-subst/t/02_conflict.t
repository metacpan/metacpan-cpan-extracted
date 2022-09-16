use v5.14;
use warnings;
use Encode;
use utf8;

use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

line(subst(qw(--check=all --dict t/JA-include.dict t/JA.txt))
     ->run->{stdout}, 1, "include");

line(subst(qw(--check=all --dict t/JA-include.dict t/JA.txt --warn-include))
     ->run->{stdout}, 2, "include --warn-include");

line(subst(qw(--check=all --dict t/JA-overlap.dict t/JA.txt))
     ->run->{stdout}, 2, "overlap");

line(subst(qw(--check=all --dict t/JA-overlap.dict t/JA.txt --no-warn-overlap))
     ->run->{stdout}, 1, "overlap --no-warn-overlap");

done_testing;
