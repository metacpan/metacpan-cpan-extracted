# Regression test: put large complex graph. breaks Dumper 2.121
# I don't know why this particular structure is problematic. not just size...
# big arrays or hashes don't break it
# ternary trees with depth <= 3 don't break it
# in this test, binary trees with depth <= 5 don't break it

use t::lib;
use strict;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use autodbUtil;

use Graph;

my $autodb=new Class::AutoDB(database=>testdb,create=>1); # create database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# regression test starts here
# make and store a big object
# regular_tree(graph=>$graph,arity=>3,depth=>4);
for my $depth (1..10) {
  my $name="binary tree depth $depth";
  my $graph=new Graph(name=>$name);
  regular_tree(graph=>$graph,arity=>2,depth=>$depth);
  $autodb->put($graph);
  my $dbh=$autodb->dbh;

  my($oid,$name,$length)=$dbh->selectrow_array
    (qq(SELECT G.oid, G.name, LENGTH(A.object) 
      FROM Graph AS G,_AutoDB as A where G.name=\'$name\' AND G.oid=A.oid));

#   is($oid,$autodb->oid($graph),"depth $depth: oid");
#   is($name,$graph->name,"depth $depth: name");
  ok($length>1000,"depth $depth: length=".(defined $length? $length: 'undef').' looks okay');
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
