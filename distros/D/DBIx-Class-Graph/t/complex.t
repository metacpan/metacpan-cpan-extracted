use Test::More;

use lib qw(t/lib);

use TestLib;

my $t = new TestLib;

my $schema = $t->get_schema;

my $g = $schema->resultset("Complex")->graph;

#$g isa Graph

is( scalar $g->vertices, 6, 'got 6 vertices' );
is( scalar $g->edges,    6, 'got 6 edges' );

is( $g->all_predecessors( $g->get_vertex(3) ), 1, 'node 3 has one parent' );
is( $g->all_successors( $g->get_vertex(1) ),   5, 'node 1 has 5 successors' );
is( $g->successors( $g->get_vertex(1) ),   3, 'node 1 has 3 direct childs' );
is( $g->successors( $g->get_vertex(3) ),   2, 'node 3 has 2 direct childs' );
is( $g->successors( $g->get_vertex(2) ),   1, 'node 2 has 1 direct child' );
is( $g->predecessors( $g->get_vertex(5) ), 2, 'node 5 has 2 parents' );

ok( $g->delete_edge( $g->get_vertex(1), $g->get_vertex(2) ), 'delete edge' );

$g = $schema->resultset("Complex")->graph;

is( scalar $g->edges, 5, 'got 5 edges' );

my $node7 =
  $schema->resultset("Complex")->create( { title => 'foo', id_foo => 7 } );

$g->add_vertex($node7);

for ( 1 .. 2 ) {
    ok( $g->add_edge( $g->get_vertex(5), $g->get_vertex(7) ), 'add edge with new row' );

    is( scalar $g->edges, 6, 'got 6 edges' );
    $g = $schema->resultset("Complex")->graph;

    is( scalar $g->edges, 6, 'still got 6 edges' );
}

done_testing;
