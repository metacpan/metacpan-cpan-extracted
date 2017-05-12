#!perl -T

use Test::More tests => 17;
use Test::Exception;
use Graph;
use Data::Dumper ;
use Data::Printer;

BEGIN {

    use_ok( 'Algorithm::CriticalPath' )                             || print "Bail out!\n";
    
    # Test not supplying a graph
    throws_ok ( sub { my $cp = Algorithm::CriticalPath->new() }, qr/Attribute \(graph\) is required/, 'Critical Path analysis requires a graph.');


    # Test various simple dags give the expected critical path.    
    my $g = Graph->new(directed => 1);
    
    
    my $cp = Algorithm::CriticalPath->new( { graph => $g}) ; 
    is_deeply($cp->vertices(),[]);
    ok( $cp->cost() == 0, 'Critical Path cost with 0 nodes is 0.');

    
    $g->add_weighted_vertex('Node1', 1);
    $cp = Algorithm::CriticalPath->new( { graph => $g}) ; 

#p $cp->vertices();

    is_deeply($cp->vertices(),['Node1']);
    ok( $cp->cost() == 1, 'Critical Path cost with 1 node is the node cost');

    $g->add_weighted_vertex('Node2', 2);
    $g->add_edge('Node1','Node2');
    $cp = Algorithm::CriticalPath->new( { graph => $g}) ; 
#p $cp->vertices();
    is_deeply($cp->vertices(),['Node1','Node2']);
    ok( $cp->cost() == 3, 'Critical Path cost with 2 nodes in line is the sum of the nodes cost');


    $g->add_weighted_vertex('Node3', 0.5);
    $g->add_edge('Node1','Node3');
    $cp = Algorithm::CriticalPath->new( { graph => $g}) ; 

    is_deeply($cp->vertices(),['Node1','Node2']);
    ok( $cp->cost() == 3, 'Critical Path cost with 3 nodes is the sum of the 2 most expensive in-line nodes');

    $g->add_weighted_vertex('EndNode4', 0);
    $g->add_edge('Node2','EndNode4');
    $g->add_edge('Node3','EndNode4');
    $cp = Algorithm::CriticalPath->new( { graph => $g}) ; 

    is_deeply($cp->vertices(),['Node1','Node2','EndNode4']);
    ok( $cp->cost() == 3, 'Critical Path cost with 4 nodes where the last has no cost is the sum of the 2 most expensive in-line nodes');

# Test building an invalid graph for critical path analysis - this one has a loop
    my $g2 = Graph->new(directed => 1);
    $g2->add_weighted_vertex('Node1', 1);
    $g2->add_weighted_vertex('Node2', 2);
    $g2->add_edge('Node1','Node2');
    $g2->add_edge('Node2','Node1');

    throws_ok ( sub { $cp = Algorithm::CriticalPath->new( { graph => $g2}) }, qr/Invalid graph type for critical path analysis/, 'Critical Path analysis cannot be run on cyclic graphs.');


# Test building an invalid graph for critical path analysis - this one is not directed
    my $g3 = Graph->new(undirected => 1);
    throws_ok ( sub { my $cp = Algorithm::CriticalPath->new( { graph => $g3}) }, qr/Invalid graph type for critical path analysis/, 'Critical Path analysis cannot be run on undirected graphs.');

# Test building an invalid graph for critical path analysis - this one is refvertexed
    my $g4 = Graph->new(refvertexed => 1);
    throws_ok ( sub { my $cp = Algorithm::CriticalPath->new( { graph => $g4}) }, qr/Invalid graph type for critical path analysis/, 'Critical Path analysis cannot be run on refvertexed graphs.');

# Test building an invalid graph for critical path analysis - this one is multivertexed  
    my $g5 = Graph->new(multivertexed => 1);
    throws_ok ( sub { my $cp = Algorithm::CriticalPath->new( { graph => $g5}) }, qr/Invalid graph type for critical path analysis/, 'Critical Path analysis cannot be run on multivertexed graphs.');

# Test building an invalid graph for critical path analysis - this one is multiedged 
    my $g6 = Graph->new(multiedged => 1);
    throws_ok ( sub { my $cp = Algorithm::CriticalPath->new( { graph => $g6}) }, qr/Invalid graph type for critical path analysis/, 'Critical Path analysis cannot be run on multiedged graphs.');

}

diag( "Testing Algorithm::CriticalPath $Algorithm::CriticalPath::VERSION, Perl $], $^X" );
