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
my $traversal = $graph->traversal;

# test required methods
my @methods = qw(
    direction
    edgeCollection
    expander
    filter
    graphName
    init
    itemOrder
    maxDepth
    maxIterations
    minDepth
    order
    sort
    startVertex
    strategy
    uniqueness
    visitor
);

for my $method (@methods) {
    can_ok($traversal, $method);
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
my $vertex2 = $graph->vertexCollection("foo")->vertex->create({test => 2});

# do traversal
$res = $graph->traversal->startVertex($vertex1)->direction("any")->execute;
ok($res, "execute");
ok($res->{visited}, "got visited");

# delete database
$database->delete;

done_testing();
