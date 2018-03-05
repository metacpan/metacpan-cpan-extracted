#!perl -T
use 5.008;
use strict;
use warnings;
use Test::More;

plan tests => 28;

use AVLTree;

# test AVL tree with numbers

sub cmp_f {
  my ($i1, $i2) = @_;

  return $i1<$i2?-1:($i1>$i2)?1:0;
}

my $tree = AVLTree->new(\&cmp_f);
isa_ok($tree, "AVLTree");
is($tree->size(), 0, "Empty tree upon construction");

map { ok($tree->insert($_), "Insert item") } qw/10 20 30 40 50 25/;
is($tree->size(), 6, "Tree size after insertion");

ok(!$tree->find(), "No query");
ok(!$tree->find(undef), "Undefined query");

my $query = 30;
my $result = $tree->find($query);
ok($result, "Item found");

ok(!$tree->find(18), "Item not found");

ok(!$tree->remove(1), "Non existent item not removed");
is($tree->size(), 6, "Tree size preserved after unsuccessful removal");
ok($tree->remove(20), "Existing item removed");
ok(!$tree->find(20), "Item removed not found");
is($tree->size(), 5, "Tree size preserved after unsuccessful removal");

# test traversal
my $item = $tree->first;
is($item, 10, 'First item');
my @ids = qw/25 30 40 50/;
while ($item = $tree->next()) {
  is($item, shift @ids, 'Next item');
}

$item = $tree->last;
is($item, 50, 'Last item');
@ids = qw/40 30 25 10/;
while ($item = $tree->prev) {
  is($item, shift @ids, 'Prev item');
}

diag( "Testing AVLTree $AVLTree::VERSION, Perl $], $^X" );
