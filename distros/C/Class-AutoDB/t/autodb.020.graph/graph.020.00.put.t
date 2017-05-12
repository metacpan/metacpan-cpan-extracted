########################################
# test graphs using our homegrown graph implementation with non-persistent nodes
# what we're mainly testing is our ability to freeze and thaw complex structures
########################################
use t::lib;
use strict;
use Test::More;
use autodbTestObject;

use graphUtil; use Graph_020;

my($put_type)=@ARGV;
defined $put_type or $put_type='put';

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# some of these graphs are very big. make sure max_allowed_packet big enough
if (max_allowed_packet_ok()) {
  do_test('chain');
  do_test('star');
  do_test('binary_tree',-depth=>5);
  do_test('ternary_tree',-depth=>5);
  do_test('cycle');
  do_test('clique',-nodes=>20);
  do_test('cone_graph');
  do_test('grid');
  do_test('torus');
} else {
  diag "tests skipped: max_allowed_packet could not be set to big enough value";
  ok(1);			# need at least 1 test to run
}

done_testing();

sub do_test {
  my $name=shift;
  my $graph;
  { no strict 'refs';
    $graph=&$name(graph=>new Graph_020(name=>$name),@_);
  }
  # okay to use TestObject because just one persistent object per test
  # %test_args, exported by graphUtil, sets class2colls, coll2keys, label
  my $test=new autodbTestObject(%test_args,put_type=>$put_type);
  $test->test_put(labelprefix=>"$put_type $name:",object=>$graph,correct_diffs=>1);
}


