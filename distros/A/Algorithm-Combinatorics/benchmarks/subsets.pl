use strict;

use Algorithm::Combinatorics qw(subsets);
use List::PowerSet;
use Benchmark qw(cmpthese);

our @data = 1..10;

sub lps_subsets {
    my $p = List::PowerSet::powerset_lazy(@data);
    1 while $p->();
}

sub ac_subsets {
    my $p = subsets(\@data);
    1 while $p->next;
}


cmpthese(-15, {
    lps_subsets => \&lps_subsets,
    ac_subsets  => \&ac_subsets,
});

# The iterator is faster, but the subroutine that gives the entire powerset
# in List::PowerSet is faster than our code in list context. We do not provide
# that one because one of the premises of this module is to not recurse.

#             Rate lps_subsets  ac_subsets
#lps_subsets 120/s          --        -50%
#ac_subsets  241/s        101%          --
