########################################
# test graphs using our homegrown graph implementation with non-persistent nodes
# what we're mainly testing is our ability to freeze and thaw complex structures
########################################
use t::lib;
use strict;
use Test::More;
use Test::Deep;
use autodbTestObject;

use graphUtil; use Graph_020;

my($num_objects,$get_type)=@ARGV;
defined $num_objects or $num_objects=3;
defined $get_type or $get_type='get';

my $autodb=new Class::AutoDB(-database=>testdb); # open database

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
    my $correct_graph;
  { no strict 'refs';
    $correct_graph=&$name(graph=>new Graph_020(name=>$name),@_);
  }
  local $SIG{__WARN__}=sub {warn @_ unless $_[0]=~/^Deep recursion/;};
  local $DB::deep=0;
  # get and test actual graph
  # %test_args, exported by graphUtil, sets class2colls, coll2keys, label
  my $test=new autodbTestObject(%test_args,get_type=>$get_type);
  # can't use test_get because it assumes all objects persistent
  my($actual_graph)=$test->do_get({collection=>'Graph_020',name=>$name},$get_type,1);
  cmp_deeply($actual_graph,$correct_graph,"$get_type $name: contents");
}
