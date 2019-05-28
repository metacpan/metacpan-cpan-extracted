#!perl
# t\030-ordered_pred.t: tests of Data::Hopen::OrderedPredecessorGraph
use rlib 'lib';
use HopenTest;

use Data::Hopen::OrderedPredecessorGraph;

my $g2 = Data::Hopen::OrderedPredecessorGraph->new;
isa_ok($g2, 'Data::Hopen::OrderedPredecessorGraph');

$g2->add_edge('a','a');
$g2->add_edge('a','b');
$g2->add_edge('b','c');
$g2->add_edge('a','c');
$g2->add_edge(1,'c');
$g2->add_edge('e','c');

# Test that the order doesn't change over 20 runs.
my @preds = $g2->ordered_predecessors('c');
cmp_ok(@preds, '==', 4, 'Right number of predecessors of c');
is_deeply([$g2->ordered_predecessors('c')], \@preds, "c $_") foreach 1..19;

# Initial part of the order shouldn't change even after you add an edge.
$g2->add_edge('f', 'c');
is_deeply([@{ [$g2->ordered_predecessors('c')] }[0..3]], \@preds,
    "Adding edge doesn't change the first part of the order");

# And a few more checks with the new edge.
@preds = $g2->ordered_predecessors('c');
cmp_ok(@preds, '==', 5, 'Right number of predecessors of c after adding edge');
is_deeply([$g2->ordered_predecessors('c')], \@preds, "c2 $_") foreach 1..5;

# Another edge
$g2->add_edge('c','b');
@preds = $g2->ordered_predecessors('b');
cmp_ok(@preds, '==', 2, 'Right number of predecessors of b');
is_deeply([$g2->ordered_predecessors('b')], \@preds, "b $_") foreach 1..5;

done_testing();
