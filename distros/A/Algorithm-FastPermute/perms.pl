# Print all the permutations of the list (1..N), where N is specified on
# the command line.

use Algorithm::FastPermute;

my @array = (1..shift());
permute {
    print "@array\n";
} @array;
