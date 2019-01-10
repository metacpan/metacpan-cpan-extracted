use warnings;
use strict;

use Test::More;
use Compress::Huffman;

my $n = Compress::Huffman->new ();
my $i = 1;

my @array = qw/a b c d q x f e f g h i j  k l m n o p q r s t 1 2 3 4 5 6/;
my %order = ( map { $_ => $i++ } @array );

eval {
    $n->symbols (\%order, notprob => 1);
};

my $msg = $n->encode(\@array);

my $x = Compress::Huffman->new ();

eval {
    $x->symbols (\%order, notprob => 1);
};

my $back = $x->decode($msg);
is_deeply(\@array, $back);

done_testing ();
