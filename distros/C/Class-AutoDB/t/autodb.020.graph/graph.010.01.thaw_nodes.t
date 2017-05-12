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

my($num_objects,$get_type)=@ARGV;
defined $num_objects or $num_objects=3;
defined $get_type or $get_type='get';

my $autodb=new Class::AutoDB(-database=>testdb); # open database

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
    my $correct_graph;
  { no strict 'refs';
    $correct_graph=&$name(graph=>new Graph_010(name=>$name),@_);
  }
  # get actual graph
  # %test_args, exported by graphUtil, sets class2colls, coll2keys, label
  my $test=new autodbTestObject(%test_args,labelprefix=>"$get_type:",get_type=>$get_type);
  my($actual_graph)=$test->do_get({collection=>'Graph_010',name=>$name},$get_type,1);
  
  my @all_actual_objects=($actual_graph,$actual_graph->nodes,$actual_graph->edges);
  my @actual_nodes=$actual_graph->nodes;
  my @actual_edges=$actual_graph->edges;
  my @all_correct_objects=($correct_graph,$correct_graph->nodes,$correct_graph->edges);
  my @correct_nodes=$correct_graph->nodes;
  my @correct_edges=$correct_graph->edges;
  my $label="get_type: $name";

  # face validity. correct number of objects, nodes, edges
  is(scalar(@all_actual_objects),scalar(@all_correct_objects),
     "$label ".(scalar(@all_correct_objects)).' objects');
  is(scalar(@actual_nodes),scalar(@correct_nodes),
     "$label ".(scalar(@correct_nodes)).' nodes');
  is(scalar(@actual_edges),scalar(@correct_edges),
     "$label ".(scalar(@correct_edges)).' edges');

  # CAUTION: @correct_thawed in 'thaw' tests refers to objects in $actual_graph
  my @correct_thawed=($actual_graph);
  cmp_thawed(\@all_actual_objects,\@correct_thawed,"$label thawed Graph_010 (top level)");

  # walk nodes list
  my $ok=1;
  for my $node (@actual_nodes) {
    my $nname=$node->name;		# force thaw
    push(@correct_thawed,$node);
    $ok&&=_cmp_thawed(\@all_actual_objects,\@correct_thawed,
		     "$label thawed nodes",__FILE__,__LINE__);
  }
  report_pass($ok,"$label thawed nodes");

  # check neighbors lists - nodes should all be thawed already
  my @actual_neighbors=map {@{$_->neighbors}} @actual_nodes;
  cmp_thawed(\@actual_neighbors,\@actual_nodes,"$label thawed neighbors");

 # walk edges list
  my $ok=1;
  for my $edge (@actual_edges) {
    my $ename=$edge->name;		# force thaw
    push(@correct_thawed,$edge);
    my($m,$n)=@{$edge->nodes};
    my $mname=$m->name;		# force thaw. should be nop. don't add to correct_thawed!
    my $nname=$n->name;		# force thaw. should be nop. don't add to correct_thawed!
    $ok&&=_cmp_thawed(\@all_actual_objects,\@correct_thawed,
		      "$label thawed edges",__FILE__,__LINE__);
  }
  report_pass($ok,"$label thawed edges");

  # check edges' nodes (aka endpoints) - nodes should all be thawed already
  my @actual_ends=map {@{$_->nodes}} @actual_edges;
  cmp_thawed(\@actual_ends,\@actual_nodes,"$label thawed edge endpoints");

  local $SIG{__WARN__}=sub {warn @_ unless $_[0]=~/^Deep recursion/;};
  local $DB::deep=0;

  # test contents the usual way. 
  # first, recompute transients. NO! test_get is smart enough to remove transients...
  # $actual_graph->init_transients;
  $test->test_get(labelprefix=>"$get_type:",
		  actual_object=>$actual_graph,correct_object=>$correct_graph);
}
