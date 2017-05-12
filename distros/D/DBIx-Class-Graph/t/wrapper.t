use Test::More;

use lib qw(t/lib);

use TestLib;

my $t = new TestLib;

my $schema = $t->get_schema;
my $rs = $schema->resultset("Complex");

my $g = $rs->graph;

my $vertex = $rs->new_result({title => 'foo'});

ok($g->add_vertex($vertex), 'add not in_storage vertex');
ok($g->add_edge($vertex, $g->get_vertex(1)) ,'add edge from new vertex to an exiting one');

ok($g = $schema->resultset("Complex")->graph, 'get graph again');

is($g->vertices, 7, 'make sure new vertex was added');

ok($g->add_edge($rs->new_result({title => 'foo'}), $rs->new_result({title => 'bar'})), 'add an edge between two new vertices');

is($g->vertices, 9, 'the graph has wo more vertices');

$g = $schema->resultset("Complex")->graph;

is($g->vertices, 9, 'even after recreation');

ok($g->delete_vertex($g->get_vertex(1)), 'delete the root vertex');

is($g->vertices, 8, 'one fewer vertices');

is($g->edges, 4, 'three fewer edges');

$g = $schema->resultset("Complex")->graph;

is($g->vertices, 8, 'even after recreation');

is($g->edges, 4, 'even after recreation');

done_testing;