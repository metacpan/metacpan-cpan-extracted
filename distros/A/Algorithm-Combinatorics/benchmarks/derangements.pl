use strict;
use warnings;

use Algorithm::Combinatorics qw(derangements);
use Math::Combinatorics;
use Benchmark qw(cmpthese);

our @data = 1..7;

sub ader {
   my $iter = derangements(\@data);
   1 while $iter->next;
}

sub mder {
    my $iter = Math::Combinatorics->new(data => \@data);
    1 while $iter->next_derangement;
}

cmpthese(-10, {
    ader => \&ader,
    mder => \&mder,
});

#        Rate  mder  ader
# mder 11.9/s    --  -91%
# ader  138/s 1063%    --
