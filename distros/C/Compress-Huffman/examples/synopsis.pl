#!/home/ben/software/install/bin/perl
use warnings;
use strict;

# Turn an alphabet in the form of a hash from symbols to
# probabilities into a binary Huffman table.

use Compress::Huffman;
my $cf = Compress::Huffman->new ();
my %symbols = (
    a => 0.5,
    b => 0.25,
    c => 0.125,
    d => 0.125,
);
$cf->symbols (\%symbols);
my $table = $cf->table ();
for my $k (sort keys %symbols) {
    print "$k: <$table->{$k}> ";
}
print "\n";

# Turn an alphabet in the form of a hash from symbols to weights
# into a tertiary Huffman table.

$cf->symbols (\%symbols, size => 3, notprob => 1);

my $table3 = $cf->table ();
for my $k (sort keys %symbols) {
    print "$k: <$table3->{$k}> ";
}
print "\n";
