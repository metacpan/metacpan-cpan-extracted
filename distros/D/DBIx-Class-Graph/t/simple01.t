use Test::More;

use lib qw(t/lib);

use TestLib;

my $t = new TestLib;

my $schema = $t->get_schema;

my $rs = $schema->resultset("Simple");

my $g = $rs->graph;

isa_ok($rs, "DBIx::Class::ResultSet::Graph");

isa_ok($g, "Graph");

my $v = $rs->get_vertex(1);

is($v->id, 1);

is(scalar $g->all_successors($v), 5);

my $nv = $rs->create({title => "new"});

$g->add_edge($v, $nv);

is(scalar $g->all_successors($v), 6);

is($rs->find(7)->vaterid, 1);

$g->delete_edge($v, $nv);

is($rs->find(7)->vaterid, undef);

is(scalar $g->all_successors($v), 5);

$g->delete_vertex($g->get_vertex(3));

is($rs->find(3), undef);

is($rs->find(5)->vaterid, undef);

is(scalar $g->all_successors($v), 2);

done_testing;