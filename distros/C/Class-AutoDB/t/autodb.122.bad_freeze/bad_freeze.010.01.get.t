# Regression test: put large complex graph. breaks Dumper 2.121
# I don't know why this particular structure is problematic. not just size...
#   big arrays or hashes don't break it
#   ternary trees with depth <= 3 don't break it
#   in this test, binary trees with depth <= 5 don't break it
#
# this script gets the graphs put by the companion 00.put test.
#   just for sanity
#   I've never actually seen 'get' fail on structures that were 'put' correctly

use t::lib;
use strict;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbUtil;

use Graph;

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# regression test starts here
# get graphs previously store
# regular_tree(graph=>$graph,arity=>3,depth=>4);
for my $depth (1..10) {
  my $name="binary tree depth $depth";
  my $correct_graph=new Graph(name=>$name);
  regular_tree(graph=>$correct_graph,arity=>2,depth=>$depth);
  my $actual_graph;
  eval {($actual_graph)=$autodb->get(Collection=>'Graph',name=>$name)};
  if ($@) {
    fail("$name: get. error is: ".substr($@,0,21).' ...');
    next;
  }
  if (!$actual_graph) {
    fail("$name: get. error is: got undef");
    next;
  }
  cmp_deeply($actual_graph,$correct_graph,"$name: contents");
}
done_testing();

# sub ternary_tree {regular_tree(@_,-arity=>3)}
sub regular_tree {
  my $args=new Hash::AutoHash::Args(@_);
  my($tree,$depth,$arity,$root)=@$args{qw(graph depth arity root)};
  defined $root or $root=0;
  $tree->add_node($root);
  if ($depth>0) {
    for (my $i=0; $i<$arity; $i++) {
      my $child="$root/$i";
      $tree->add_edge($root,$child);
      regular_tree(graph=>$tree,depth=>$depth-1,arity=>$arity,root=>$child);
    }
  }
  $tree;
}
