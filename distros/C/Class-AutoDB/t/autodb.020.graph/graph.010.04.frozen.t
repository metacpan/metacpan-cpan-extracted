########################################
# test graphs using our homegrown graph implementation
# what we're mainly testing are 
#   1) 'put' is really doing the Oid thing and not just dumping entire graphs
#   2) defered thawing. the various test scripts follow different paths through
#      object network
# this one checks the frozen representation in the database
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
  my @correct_nodes=$correct_graph->nodes;
  my @correct_edges=$correct_graph->edges;
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

  my $dbh=$autodb->dbh;
  # test frozen representation of top level Graph_010
  my $oid=$actual_graph->oid;
  my($frozen)=$dbh->selectrow_array(qq(SELECT object FROM _AutoDB WHERE oid=$oid));
  my @names=$frozen=~/name\W*=>/g;
  is(scalar @names,1,"$label names in frozen Graph_010 (top level)");
  my @nodes=$frozen=~/_CLASS\W*=>\W*Node/g;
  is(scalar @nodes,scalar @correct_nodes,"$label nodes in frozen Graph_010 (top level)");
  my @edges=$frozen=~/_CLASS\W*=>\W*Edge/g;
  is(scalar @edges,scalar @correct_edges,"$label edges in frozen Graph_010 (top level)");

  # test frozen representation of Nodes. walk nodes list
  my $ok=1;
  for my $node (@actual_nodes) {
    my $oid=$node->oid;
    my($frozen)=$dbh->selectrow_array(qq(SELECT object FROM _AutoDB WHERE oid=$oid));
    my @names=$frozen=~/name\W*=>/g;
    $ok&&=scalar(@names)==1;
    my @nodes=$frozen=~/_CLASS\W*=>\W*Node/g;
    $ok&&=scalar(@nodes)==scalar(@{$node->neighbors})+1; # extra 1 for node itself
    my @edges=$frozen=~/_CLASS\W*=>\W*Edge/g;
    $ok&&=scalar(@edges)==0;	# nodes don't contain edges
  }
  report_pass($ok,"$label frozen nodes");

 # test frozen representation of Edges. walk edges list
  my $ok=1;
  for my $edge (@actual_edges) {
    my $oid=$edge->oid;
    my($frozen)=$dbh->selectrow_array(qq(SELECT object FROM _AutoDB WHERE oid=$oid));
    my @names=$frozen=~/name\W*=>/g;
    $ok&&=scalar(@names)==1;
    my @nodes=$frozen=~/_CLASS\W*=>\W*Node/g;
    $ok&&=scalar(@nodes)==2;	# edge contains 2 nodes
    my @edges=$frozen=~/_CLASS\W*=>\W*Edge/g;
    $ok&&=scalar(@edges)==1;	# for edge itself
  }
  report_pass($ok,"$label frozen edges");

  local $SIG{__WARN__}=sub {warn @_ unless $_[0]=~/^Deep recursion/;};
  local $DB::deep=0;

  # test contents the usual way. 
  # first, recompute transients. NO! test_get is smart enough to remove transients...
  # $actual_graph->init_transients;
  $test->test_get(labelprefix=>"$get_type:",
		  actual_object=>$actual_graph,correct_object=>$correct_graph);
}
