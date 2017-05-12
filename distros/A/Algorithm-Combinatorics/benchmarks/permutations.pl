use strict;
use warnings;

use Algorithm::Combinatorics qw(permutations);
use Math::Combinatorics;
use Benchmark qw(cmpthese);

our @data = 1..7;

sub aperm {
   my $iter = permutations(\@data);
   1 while $iter->next;
}

sub mperm {
    my $iter = Math::Combinatorics->new(data => \@data);
    1 while $iter->next_permutation;
}

cmpthese(-10, {
    aperm => \&aperm,
    mperm => \&mperm,
});

#         Rate mperm aperm
# mperm 12.2/s    --  -78%
# aperm 54.4/s  347%    --
