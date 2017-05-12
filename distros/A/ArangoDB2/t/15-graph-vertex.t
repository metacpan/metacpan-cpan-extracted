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
my $edgeDefinition = $graph->edgeDefinition;
my $edge = $edgeDefinition->edge;

# test required methods
my @methods = qw(
    create
    delete
    get
    keepNull
    new
    update
    replace
    waitForSync
);

for my $method (@methods) {
    can_ok($edge, $method);
}

# skip tests against the actual ArangoDB server unless
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
                "foo",
            ],
            to => [
                "foo",
            ],
        },
    ],
});

# create some vertices
my $vertex1 = $graph->vertexCollection("foo")->vertex->create({test => 1});
ok($vertex1, "vertex created");
my $vertex2 = $graph->vertexCollection("foo")->vertex->create({test => 2});
ok($vertex2, "vertex created");

# create edge
$edge = $graph->edgeDefinition("edges")->edge->from($vertex1)->to($vertex2)->create({hello => "world"});
ok($edge, "edge created");
ok($edge->from, "edge from");
ok($edge->to, "edge to");

# get edge
$edge = $graph->edgeDefinition("edges")->edge->get({name => $edge->name});
ok($edge, "edge created");
ok($edge->from, "edge from");
ok($edge->to, "edge to");
ok($edge->id, "get id");
ok($edge->rev, "get rev");
ok($edge->data, "get data");
is_deeply($edge->data, {hello => "world"}, "data");

# update
$edge->update({test => "more"});

# get edge
$edge = $graph->edgeDefinition("edges")->edge->get({name => $edge->name});
is($edge->data->{test}, "more", "update");

$edge->replace({goodbye => "world"});
is_deeply($edge->data, {goodbye => "world"}, "replace");

# delete edge
$res = $edge->delete;
ok($res, "delete");

# get edge
$edge = $graph->edgeDefinition("edges")->edge->get({name => $edge->name});
ok(!$edge, "edge deleted");

# delete database
$database->delete;

done_testing();
