use Test::More;

use lib qw(t/lib);

use TestLib;

my $t = new TestLib;

my $schema = $t->get_schema;

my $rs = $schema->resultset("SimpleSucc");

my $g = $rs->get_graph;

my $v = $g->get_vertex(1);

is($v->id, 1);

is(scalar $g->all_successors($v), 2);

ok(($g->all_successors($v))[0]->id);

my $v2 = $g->get_vertex(5);

is(scalar $g->all_predecessors($v2), 4);

my $nv = $rs->create({title => "new"});

$g->add_edge($v, $nv);

is(scalar $g->all_successors($v), 1);

is($rs->find(1)->childid, 7);

$g->delete_edge($v, $nv);

is(scalar $g->all_successors($v), 0);

is(scalar $g->all_predecessors($v2), 3);

$g->delete_vertex($g->get_vertex(3));

is($rs->find(3), undef);

is($rs->find(1)->childid, undef);

is(scalar $g->all_successors($v), 0);

done_testing;