use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ArangoDB2;

my $res;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});

my $dbname = "ngukvderybvfgjutecbxzsfhyujmnvgf";
my $database = $arango->database($dbname);
my $graph = $database->graph;

# test required methods
my @methods = qw(
    new
    create
    delete
    dropCollections
    edgeDefinitions
    get
    list
    orphanCollections
);

for my $method (@methods) {
    can_ok($graph, $method);
}

# skip tests against the actual ArangoDB2 server unless
# LIVE_TEST env param is set
if (!$ENV{LIVE_TEST}) {
    diag("Skipping live API tests - set LIVE_TEST=1 to enable");
    done_testing();
    exit;
}

# delete database
$database->delete;
# create database
$database->create({
    users => [
        {
            username => $ENV{ARANGO_USER},
            passwd => $ENV{ARANGO_PASS},
        },
    ],
});

# create a new graph
$graph = $database->graph("myGraph")->create({
    edgeDefinitions => [
        {
            collection => "edges",
            from => [
                "startVertices",
            ],
            to => [
                "endVertices",
            ],
        },
    ],
});

ok($graph, "graph created");
ok($graph->name, "graph name");
ok($graph->edgeDefinitions, "graph edgeDefinitions");
ok($graph->orphanCollections, "graph orphanCollections");
ok($graph->id, "graph id");
ok($graph->rev, "graph rev");
ok($database->graphs->{$graph->name}, "instance registered");

# get graph
$graph = $database->graph->get({name => "myGraph"});
ok($graph, "get graph");
ok($graph->name, "graph name");
ok($graph->edgeDefinitions, "graph edgeDefinitions");
ok($graph->orphanCollections, "graph orphanCollections");
ok($graph->id, "graph id");
ok($graph->rev, "graph rev");
ok($database->graphs->{$graph->name}, "instance registered");

# get list
my $list = $graph->list;
ok($list, "list");
ok( (grep { $_->{_id} eq $graph->id } @$list), "graph in list");

# delete graph
ok($graph->delete, "delete");

# get list
$list = $graph->list;
ok( !(grep { $_->{_id} eq $graph->id } @$list), "graph not in list");

# delete database
$database->delete;

done_testing();
