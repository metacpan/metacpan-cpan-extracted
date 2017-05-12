# This is a test for module Compress::Huffman.

use warnings;
use strict;
use Test::More;
use Compress::Huffman;
my $eps = 0.0001;
my $n = Compress::Huffman->new ();
ok ($n, "Made object");
my %s = (
    a => 1,
    b => 2,
    c => 3,
);
eval {
    $n->symbols (\%s, notprob => 1, verbose => 1);
};
ok (! $@, "Made symbol table");
my $xl = $n->xl ();
ok ($xl > 1.5 - $eps && $xl < 1.5 + $eps, "expected length about 1.5");

my %t = (
    a => 0.01,
    b => 0.02,
    c => 0.03,
    d => 0.04,
    e => 0.2,
    f => 0.3,
    g => 0.4,
);
$n->symbols (\%t, verbose => 1);
my $h = $n->{h};
for my $sym ('a'..'f') {
    my $next = chr (ord ($sym) + 1);
    ok (length ($h->{$sym} >= length ($h->{$next})), "length ordering $sym $next OK");
}
$n->symbols (\%t, size => 3, verbose => 1);
$n->symbols (\%t, size => 4, verbose => 1);
#$n->symbols (\%t, size => 99, verbose => 1);

done_testing ();

# Local variables:
# mode: perl
# End:
