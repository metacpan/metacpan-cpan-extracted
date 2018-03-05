#!/usr/bin/env perl

use strict;
use warnings;

use FindBin '$Bin';
use List::Util qw(shuffle);

use lib 'lib';
use lib "$Bin/../lib", "$Bin/../blib/lib", "$Bin/../blib/arch";

use AVLTree;
# use Tree::AVL;

use Benchmark;

$| = 1;

print '-' x 21, "\n 100K random inserts\n", '-' x 21, "\n\n";
my @items = shuffle 1 .. 100000;

# my $start = new Benchmark;
# print "[Tree::AVL]\t\t";
# my $treeavl = Tree::AVL->new();
# map { $treeavl->insert($_) } @items;
# my $end = new Benchmark;
# my $diff = timediff($end, $start);
# printf "time taken was %s seconds\n", timestr($diff, 'all');

my $start = new Benchmark;
print "[AVLTree]\t\t";
my $avltree = AVLTree->new(\&cmp_f);
map { $avltree->insert($_) } @items;
my $end = new Benchmark;
my $diff = timediff($end, $start);
printf "time taken was %s seconds\n\n\n", timestr($diff, 'all');

print '-' x 23, "\n 10K random deletions\n", '-' x 23, "\n\n";
@items = shuffle 1 .. 10000;

# $start = new Benchmark;
# print "[Tree::AVL]\t\t";
# map { $treeavl->remove($_) } @items;
# $end = new Benchmark;
# $diff = timediff($end, $start);
# printf "time taken was %s seconds\n", timestr($diff, 'all');

$start = new Benchmark;
print "[AVLTree]\t\t";
map { $avltree->remove($_) } @items;
$end = new Benchmark;
$diff = timediff($end, $start);
printf "time taken was %s seconds\n", timestr($diff, 'all');

sub cmp_f {
  my ($i1, $i2) = @_;

  return $i1<$i2?-1:($i1>$i2)?1:0;
}
