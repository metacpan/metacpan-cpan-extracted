# This is a test of save and load for module Compress::Huffman.

use warnings;
use strict;
use Test::More;
use Compress::Huffman;

my $n = Compress::Huffman->new ();
my %s = (
    a => 1,
    b => 2,
    c => 3,
);
$n->symbols (\%s, notprob => 1, verbose => 1);
my $saved = $n->save ();
note "$saved\n";
my $m = Compress::Huffman->new ();
$m->load ($saved);
is_deeply ($n, $m);
done_testing ();
