########################################
# test graphs using our homegrown graph implementation
# what we're mainly testing are 
#   1) 'put' is really doing the Oid thing and not just dumping entire graphs
#   2) defered thawing. the various test scripts follow different paths through
#      object network
########################################
use t::lib;
use strict;
use Test::More;
use autodbTestObject;

use graphUtil; use Graph_010;

my($put_type)=@ARGV;
defined $put_type or $put_type='put';

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

do_test('chain');
do_test('star');
do_test('binary_tree',-depth=>5);
do_test('ternary_tree',-depth=>5);
do_test('cycle');
do_test('clique',-nodes=>20);
do_test('cone_graph');
do_test('grid');
do_test('torus');

done_testing();

sub do_test {
  my $name=shift;
  my $graph;
  { no strict 'refs';
    $graph=&$name(graph=>new Graph_010(name=>$name),@_);
  }
  my $nodes=$graph->nodes;
  my $edges=$graph->edges;
  # don't use TestObject because too much output
  $graph->put;
  ok_collections([$graph],"$put_type $name: graph",{Graph_010=>$coll2keys->{Graph_010}})  ;
  map {$_->put} @$nodes;
  # ok_collections($nodes,"$put_type $name: ".(scalar @$nodes)." nodes",{Node=>$coll2keys->{Node}}); 
  map {$_->put} $graph->edges;
  # ok_collections($edges,"$put_type $name: ".(scalar @$edges)." edges",{Edge=>$coll2keys->{Edge}}); 
    
  remember_oids($graph,@$nodes,@$edges);
}


