use Test::More;

use lib qw(../../lib ../lib t/lib lib);

use TestLib;

my $t = new TestLib;

my $schema = $t->get_schema;

my $rs = $schema->resultset("Simple");

my $g = $rs->get_graph;

my $v1 = $g->get_vertex(1);
my $v3 = $g->get_vertex(3);
my $v5 = $g->get_vertex(5);

$g->add_edge($v1, $v5);

is(scalar $g->all_successors($v1), 5);

is($rs->find(5)->vaterid, 1);

is(scalar $g->successors($v1), 4);

is(scalar $g->all_successors($v3), 1);

# tests that each vertex can have one parent only!

done_testing;