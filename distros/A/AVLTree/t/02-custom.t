#!perl -T
use 5.008;

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Carp;

plan tests => 19;

use AVLTree;

# test AVL tree with custom data

# suppose data comes as a hash ref where the comparison is based on
# on the values associated to a given key, e.g. id
sub cmp_f {
  my ($i1, $i2) = @_;
  my ($id1, $id2) = ($i1->{id}, $i2->{id});
  croak "Cannot compare items based on id"
    unless defined $id1 and defined $id2;
  
  return $id1<$id2?-1:($id1>$id2)?1:0;
}

my $tree = AVLTree->new(\&cmp_f);
isa_ok($tree, "AVLTreePtr");
is($tree->size(), 0, "Empty tree upon construction");

my $items =
  [
   { id => 10, data => ['ten'] },
   { id => 20, data => ['twenty'] },
   { id => 30, data => ['thirty'] },
   { id => 40, data => ['forty'] },
   { id => 50, data => ['fifty'] },
   { id => 25, data => ['twentyfive'] },
  ];
map { ok($tree->insert($_), "Insert item") } @{$items};
is($tree->size(), 6, "Tree size after insertion");

ok(!$tree->find(), "No query");
ok(!$tree->find(undef), "Undefined query");

my $query = { id => 30, data => 'something' };
my $result = $tree->find($query);
ok($result, "Item found");
cmp_deeply($result, { id => 30, data => ['thirty'] }, "Item returned");

ok(!$tree->find({ id => 18 }), "Item not found");

ok(!$tree->remove({ id => 1 }), "Non existent item not removed");
is($tree->size(), 6, "Tree size preserved after unsuccessful removal");
ok($tree->remove({ id => 20 }), "Existing item removed");
ok(!$tree->find({ id => 20 }), "Item removed not found");
is($tree->size(), 5, "Tree size preserved after unsuccessful removal");

diag( "Testing AVLTree $AVLTree::VERSION, Perl $], $^X" );
